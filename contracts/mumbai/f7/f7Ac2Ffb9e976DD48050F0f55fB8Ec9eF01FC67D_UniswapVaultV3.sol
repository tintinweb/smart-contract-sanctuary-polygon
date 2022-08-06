// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import { Vault } from "../Vault.sol";
import "./UniswapVaultV3Storage.sol";
import "./INonfungiblePositionManager.sol";
/// @notice Contains the primary logic for Uniswap V3 Vaults
contract UniswapVaultV3 is Vault, UniswapVaultV3Storage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum,
        address _uniswapFactory,
        address _uniswapRouter,
        address _uniswapPositionManager,
        address _uniswapQuoter,
        uint24 _fee
    ) public virtual initializer {
        __UniswapVaultV3_init(
            coreAddress,
            _epochDuration,
            _token0,
            _token1,
            _token0FloorNum,
            _token1FloorNum,
            _uniswapFactory,
            _uniswapRouter,
            _uniswapPositionManager,
            _uniswapQuoter,
            _fee
        );
    }

    function __UniswapVaultV3_init(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum,
        address _uniswapFactory,
        address _uniswapRouter,
        address _uniswapPositionManager,
        address _uniswapQuoter,
        uint24 _fee
    ) internal onlyInitializing {
        __Vault_init(
            coreAddress,
            _epochDuration,
            _token0,
            _token1,
            _token0FloorNum,
            _token1FloorNum
        );
        __UniswapVaultV3_init_unchained(
            _uniswapFactory,
            _uniswapRouter,
            _uniswapPositionManager,
            _uniswapQuoter,
            _fee
        );
    }

    function __UniswapVaultV3_init_unchained(
        address _uniswapFactory,
        address _uniswapRouter,
        address _uniswapPositionManager,
        address _uniswapQuoter,
        uint24 _fee
    ) internal onlyInitializing {
        pool = IUniswapV3Factory(_uniswapFactory).getPool(
            address(token0),
            address(token1),
            _fee
        );
        // require that the pool has been created
        require(pool != address(0), "ZERO_ADDRESS");

        router = _uniswapRouter;
        factory = _uniswapFactory;
        positionManager = _uniswapPositionManager;
        quoter = _uniswapQuoter;
        fee = _fee;

        //Full range by default
        tickLower = -887220;
        tickUpper = 887220;
    }

    // @dev queries the pool reserves and ensure the token ordering is correct
    function getPoolBalances() internal view virtual override returns (
        uint256 reservesA,
        uint256 reservesB
    ) {
        reservesA = token0.balanceOf(pool);
        reservesB = token1.balanceOf(pool);
    }

    // simulate token swap with uniswap quoter to get amountOut
    function calcAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal virtual override returns (uint256) {

        (uint256 reserve0, uint256 reserve1) = getPoolBalances();
        address tInput; 
        address tOutput;
        if (reserveIn == reserve0 && reserveOut == reserve1) {
            tInput = address(token0);
            tOutput = address(token1);
        } else {
            tInput = address(token1);
            tOutput = address(token0);
        }
        uint256 amountIn = IQuoter(quoter).quoteExactOutputSingle(
            tInput,
            tOutput,
            fee,
            amountOut,
            uint160(0)
        );
        return amountIn;
    }

    // Withdraws all liquidity
    // @dev We can ignore the need for frontrunning checks because the `_nextEpoch` function checks
    // that the pool reserves are as expected beforehand
    function _withdrawLiquidity() internal virtual override {
        //No position to interact with
        if (tokenId == 0) return;

        // use position manager to retrieve our liquidity
        // safe to ignore return values because we check balances before and after this call
        // decrease liquidity
        INonfungiblePositionManager.DecreaseLiquidityParams memory decLiqParams =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        INonfungiblePositionManager(positionManager).decreaseLiquidity(decLiqParams);
        // collect tokens and fee rewards
        INonfungiblePositionManager.CollectParams memory collectParams =
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        INonfungiblePositionManager(positionManager).collect(collectParams);
    }

    // Deposits available liquidity
    // @dev We can ignore the need for frontrunning checks because the `_nextEpoch` function checks
    // that the pool reserves are as expected beforehand
    // `availableToken0` and `availableToken1` are also known to be greater than 0 since they are checked
    // by `depositLiquidity` in `Vault.sol`
    function _depositLiquidity(uint256 availableToken0, uint256 availableToken1)
        internal
        virtual
        override
        returns (uint256 token0Deposited, uint256 token1Deposited)
    {
        // use the position manager to mint position for `token0` and `token1`
        // or increase liquidity if we already have one 
        token0.safeIncreaseAllowance(positionManager, availableToken0);
        token1.safeIncreaseAllowance(positionManager, availableToken1);
        // can safely ignore `liquidity` return value because when withdrawing we check our full balance
        // mint new position if it's our first interaction with the pool 
        if (tokenId == 0) {
            INonfungiblePositionManager.MintParams memory params =
                INonfungiblePositionManager.MintParams({
                    token0: address(token0),
                    token1: address(token1),
                    fee: fee,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: availableToken0,
                    amount1Desired: availableToken1,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: block.timestamp
                });

            (tokenId, liquidity, token0Deposited, token1Deposited ) = 
                INonfungiblePositionManager(positionManager).mint(params);
        } else {
            INonfungiblePositionManager.IncreaseLiquidityParams memory params =
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: availableToken0,
                    amount1Desired: availableToken1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
            (liquidity, token0Deposited, token1Deposited) = 
                INonfungiblePositionManager(positionManager)
                    .increaseLiquidity(params);
        }
        // if we didn't deposit the full `availableToken{x}`, reduce allowance for safety
        if (availableToken0 > token0Deposited) {
            token0.safeApprove(router, 0);
        }
        if (availableToken1 > token1Deposited) {
            token1.safeApprove(router, 0);
        }
    }

    // For the default Uniswap vault this does nothing
    function _unstakeLiquidity() internal virtual override {}

    // For the default Uniswap vault this does nothing
    function _stakeLiquidity() internal virtual override {}

    // Swaps tokens
    // @dev We can ignore the need for frontrunning checks because the `_nextEpoch` function checks
    // that the pool reserves are as expected beforehand
    function swap(
        IERC20Upgradeable tokenIn,
        IERC20Upgradeable tokenOut,
        uint256 amountIn
    ) internal virtual override returns (uint256 amountOut, uint256 amountConsumed) {
        if (amountIn == 0) return (0, 0);
        tokenIn.safeIncreaseAllowance(router, amountIn);
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
            tokenIn: address(tokenIn),
            tokenOut: address(tokenOut),
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = ISwapRouter(router).exactInputSingle(params);
        amountConsumed = amountIn;
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

// Have to use SafeERC20Upgradeable instead of SafeERC20 because SafeERC20 inherits Address.sol,
// which uses delegeatecall functions, which are not allowed by OZ's upgrade process
// See more:
// https://forum.openzeppelin.com/t/error-contract-is-not-upgrade-safe-use-of-delegatecall-is-not-allowed/16859
import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { IWrappy } from "../external/IWrappy.sol";
import { CoreReference } from "../refs/CoreReference.sol";
import { VaultStorage } from "./VaultStorage.sol";
import { IVault } from "./IVault.sol";

/// @notice Contains the primary logic for vaults
/// @author Recursive Research Inc
abstract contract Vault is IVault, CoreReference, ReentrancyGuardUpgradeable, VaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant TOKEN0 = keccak256("TOKEN0");
    bytes32 public constant TOKEN1 = keccak256("TOKEN1");

    uint256 public constant RAY = 1e27;
    uint256 public constant POOL_ERR = 50; // 0.5% error margin allowed
    uint256 public constant DENOM = 10_000;
    uint256 public constant MIN_LP = 1000; // minimum amount of tokens to be deposited as LP

    // ----------- Upgradeable Constructor Pattern -----------

    /// Initializes the vault to point to the Core contract and configures it to have
    /// a given epoch duration, pair of tokens, and floor returns on each Token
    /// @param coreAddress address of the Core contract
    /// @param _epochDuration duration of the epoch in seconds
    /// @param _token0 address of TOKEN0
    /// @param _token1 address of TOKEN1
    /// @param _token0FloorNum the floor returns of the TOKEN0 side (out of `DENOM`). In practice,
    ///     10000 to guarantee lossless returns for the TOKEN0 side.
    /// @param _token1FloorNum the floor returns of the TOKEN1 side (out of `DENOM`). In practice,
    ///     500 to prevent accounting errors.
    function __Vault_init(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum
    ) internal onlyInitializing {
        __CoreReference_init(coreAddress);
        __ReentrancyGuard_init();
        __Vault_init_unchained(_epochDuration, _token0, _token1, _token0FloorNum, _token1FloorNum);
    }

    function __Vault_init_unchained(
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum
    ) internal onlyInitializing {
        require(_token0FloorNum > 0, "INVALID_TOKEN0_FLOOR");
        require(_token1FloorNum > 0, "INVALID_TOKEN1_FLOOR");

        isNativeVault = _token0 == core.wrappedNative();

        token0 = IERC20Upgradeable(_token0);
        token1 = IERC20Upgradeable(_token1);

        token0Data.epochToRate[0] = RAY;
        token1Data.epochToRate[0] = RAY;
        epoch = 1;
        epochDuration = _epochDuration;
        token0FloorNum = _token0FloorNum;
        token1FloorNum = _token1FloorNum;
    }

    // ----------- Deposit Requests -----------

    /// @notice schedules a deposit of TOKEN0 into the floor tranche
    /// @dev currently does not support fee on transfer / deflationary tokens.
    /// @param _amount the amount of the TOKEN0 to schedule-deposit if a non native vault,
    ///     and unused if it's a native vault. msg.value must be zero if not a native vault
    ///     typechain does not allow payable function overloading so we can either have 2 different
    ///     names or consolidate them into the same function as we do here
    function depositToken0(uint256 _amount) external payable override whenNotPaused nonReentrant {
        if (isNativeVault) {
            IWrappy(address(token0)).deposit{ value: msg.value }();
            _depositAccounting(token0Data, msg.value, TOKEN0);
        } else {
            require(msg.value == 0, "NOT_NATIVE_VAULT");
            token0.safeTransferFrom(msg.sender, address(this), _amount);
            _depositAccounting(token0Data, _amount, TOKEN0);
        }
    }

    /// @notice schedules a deposit of the TOKEN1 into the ceiling tranche
    /// @dev currently does not support fee on transfer / deflationary tokens.
    /// @param _amount the amount of the TOKEN1 to schedule-deposit
    function depositToken1(uint256 _amount) external override whenNotPaused nonReentrant {
        token1.safeTransferFrom(msg.sender, address(this), _amount);
        _depositAccounting(token1Data, _amount, TOKEN1);
    }

    /// @dev handles the accounting for scheduling deposits in a way that abstracts the logic
    /// @param assetData storage reference to the data for the desired asset
    /// @param _depositAmount the amount of the asset to deposit
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    function _depositAccounting(
        AssetData storage assetData,
        uint256 _depositAmount,
        bytes32 assetCode
    ) private {
        require(_depositAmount > 0, "ZERO_AMOUNT");
        uint256 currEpoch = epoch;

        // Check their prior deposit requests and flush to balanceDay0 if needed
        assetData.balanceDay0[msg.sender] = __updateDepositRequests(assetData, currEpoch, _depositAmount);

        // track total deposit requests
        assetData.depositRequestsTotal += _depositAmount;

        emit DepositScheduled(assetCode, msg.sender, _depositAmount, currEpoch);
    }

    /// @dev for updating the deposit requests with any new deposit amount
    /// or flushing the deposits to balanceDay0 if the epoch of the request has passed
    /// @param assetData storage reference to the data for the desired asset
    /// @param currEpoch current epoch (passed to save a storage read)
    /// @param _depositAmount amount of deposits
    /// @return newBalanceDay0 new balance day 0 of the user (returned to save a storage read)
    function __updateDepositRequests(
        AssetData storage assetData,
        uint256 currEpoch,
        uint256 _depositAmount
    ) private returns (uint256 newBalanceDay0) {
        Request storage req = assetData.depositRequests[msg.sender];

        uint256 balance = assetData.balanceDay0[msg.sender];
        uint256 reqAmount = req.amount;

        // If they have a prior request
        if (reqAmount > 0 && req.epoch < currEpoch) {
            // and if it was from a prior epoch
            // we now know the exchange rate at that epoch,
            // so we can add to their balance
            uint256 conversionRate = assetData.epochToRate[req.epoch];
            // will not overflow even if value = total mc of crypto
            balance += (reqAmount * RAY) / conversionRate;

            reqAmount = 0;
        }

        if (_depositAmount > 0) {
            // if they don't have a prior request, store this one (if this is a non-zero deposit)
            reqAmount += _depositAmount;
            req.epoch = currEpoch;
        }
        req.amount = reqAmount;

        return balance;
    }

    // ----------- Withdraw Requests -----------

    /// @notice schedules a withdrawal of TOKEN0 from the floor tranche
    /// @param _amount amount of Day 0 TOKEN0 to withdraw
    function withdrawToken0(uint256 _amount) external override whenNotPaused nonReentrant {
        _withdrawAccounting(token0Data, _amount, TOKEN0);
    }

    /// @notice schedules a withdrawal of the TOKEN1 from the ceiling tranche
    /// @param _amount amount of Day 0 TOKEN1 to withdraw
    function withdrawToken1(uint256 _amount) external override whenNotPaused nonReentrant {
        _withdrawAccounting(token1Data, _amount, TOKEN1);
    }

    /// @dev handles the accounting for schedules withdrawals in a way that abstracts the logic
    /// @param assetData storage reference to the data for the desired asset
    /// @param _withdrawAmountDay0 the amount of the asset to withdraw
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    function _withdrawAccounting(
        AssetData storage assetData,
        uint256 _withdrawAmountDay0,
        bytes32 assetCode
    ) private {
        require(_withdrawAmountDay0 > 0, "ZERO_AMOUNT");
        uint256 currEpoch = epoch;

        // Check if they have any deposit request that
        // might not have been flushed to the deposit mapping yet
        uint256 userBalanceDay0 = __updateDepositRequests(assetData, currEpoch, 0);

        // See if there were any existing withdraw requests
        Request storage req = assetData.withdrawRequests[msg.sender];
        if (req.amount > 0 && req.epoch < currEpoch) {
            // If there was a request from a previous epoch, we now know the corresponding amount
            // that was withdrawn and we can add it to the accumulated amount of claimable assets
            // tokenAmount * epochToRate will not overflow even if value = total mc of crypto & rate = 3.8e10 * RAY
            assetData.claimable[msg.sender] += (req.amount * assetData.epochToRate[req.epoch]) / RAY;
            req.amount = 0;
        }

        // Subtract the amount they way to withdraw from their deposit amount
        // Want to explicitly send out own reversion message
        require(userBalanceDay0 >= _withdrawAmountDay0, "INSUFFICIENT_BALANCE");
        unchecked {
            assetData.balanceDay0[msg.sender] = userBalanceDay0 - _withdrawAmountDay0;
        }

        // Add it to their withdraw request and log the epoch
        req.amount = _withdrawAmountDay0 + req.amount;
        if (req.epoch < currEpoch) {
            req.epoch = currEpoch;
        }

        // track total withdraw requests
        assetData.withdrawRequestsTotal += _withdrawAmountDay0;

        emit WithdrawScheduled(assetCode, msg.sender, _withdrawAmountDay0, currEpoch);
    }

    // ----------- Claim Functions -----------

    /// @notice allows the user (`msg.sender`) to claim the TOKEN0 they have a right to once
    /// withdrawal requests are processed
    function claimToken0() external override whenNotPaused nonReentrant {
        uint256 claim = _claimAccounting(token0Data, TOKEN0);

        if (isNativeVault) {
            IWrappy(address(token0)).withdraw(claim);
            (bool success, ) = msg.sender.call{ value: claim }("");
            require(success, "TRANSFER_FAILED");
        } else {
            token0.safeTransfer(msg.sender, claim);
        }
    }

    /// @notice allows the user (`msg.sender`) to claim the TOKEN1 they have a right to once
    /// withdrawal requests are processed
    function claimToken1() external override whenNotPaused nonReentrant {
        uint256 claim = _claimAccounting(token1Data, TOKEN1);
        token1.safeTransfer(msg.sender, claim);
    }

    /// @notice calculates the current amount of an asset the user (`msg.sender`) has claim to
    /// after withdrawal requests are processed and abstracts away the accounting logic
    /// @param assetData storage reference to the data for the desired asset
    /// @return _claim amount of the asset the user has a claim to
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    function _claimAccounting(AssetData storage assetData, bytes32 assetCode) private returns (uint256 _claim) {
        Request storage withdrawReq = assetData.withdrawRequests[msg.sender];
        uint256 currEpoch = epoch;
        uint256 withdrawEpoch = withdrawReq.epoch;

        uint256 claimable = assetData.claimable[msg.sender];
        if (withdrawEpoch < currEpoch) {
            // If epoch ended, calculate the amount they can withdraw
            uint256 withdrawAmountDay0 = withdrawReq.amount;
            if (withdrawAmountDay0 > 0) {
                delete assetData.withdrawRequests[msg.sender];
                // tokenAmount * epochToRate will not overflow even if value = total mc of crypto & rate = 3.8e10 * RAY
                claimable += (withdrawAmountDay0 * assetData.epochToRate[withdrawEpoch]) / RAY;
            }
        }

        require(claimable > 0, "NO_CLAIM");
        assetData.claimable[msg.sender] = 0;
        assetData.claimableTotal -= claimable;
        emit AssetsClaimed(assetCode, msg.sender, claimable);
        return claimable;
    }

    // ----------- Balance Functions -----------

    /// @notice gets a user's current TOKEN0 balance
    /// @param user address of the user in which whose balance we are interested
    /// @return deposited amount of deposited TOKEN0 in the protocol
    /// @return pendingDeposit amount of TOKEN0 pending deposit
    /// @return claimable amount of TOKEN0 ready to be withdrawn
    function token0Balance(address user)
        external
        view
        override
        returns (
            uint256 deposited,
            uint256 pendingDeposit,
            uint256 claimable
        )
    {
        return _balance(token0Data, user);
    }

    /// @notice gets a user's current TOKEN1 balance
    /// @param user address of the user in which whose balance we are interested
    /// @return deposited amount of deposited TOKEN1 in the protocol
    /// @return pendingDeposit amount of TOKEN1 pending deposit
    /// @return claimable amount of TOKEN1 ready to be withdrawn
    function token1Balance(address user)
        external
        view
        override
        returns (
            uint256 deposited,
            uint256 pendingDeposit,
            uint256 claimable
        )
    {
        return _balance(token1Data, user);
    }

    /// @dev handles the balance calculations in a way that abstracts the logic
    /// @param assetData storage reference to the data for the desired asset
    /// @param user address of the user in which whose balance we are interested
    /// @return _deposited amount of their asset that is deposited in the protocol
    /// @return _pendingDeposit amount of their asset pending deposit
    /// @return _claimable amount of their asset ready to be withdrawn
    function _balance(AssetData storage assetData, address user)
        private
        view
        returns (
            uint256 _deposited,
            uint256 _pendingDeposit,
            uint256 _claimable
        )
    {
        uint256 currEpoch = epoch;

        uint256 balanceDay0 = assetData.balanceDay0[user];

        // then check if they have any open deposit requests
        Request memory depositReq = assetData.depositRequests[user];
        uint256 depositAmt = depositReq.amount;
        uint256 depositEpoch = depositReq.epoch;

        if (depositAmt > 0) {
            // if they have one from a previous epoch, add the Day 0 amount that
            // deposit is worth
            if (depositEpoch < currEpoch) {
                balanceDay0 += (depositAmt * RAY) / assetData.epochToRate[depositEpoch];
            } else {
                // if they have one from this epoch, set the flat amount
                _pendingDeposit = depositAmt;
            }
        }

        // Check their withdraw requests, because if they made one
        // their deposit balances would have been flushed to here
        Request memory withdrawReq = assetData.withdrawRequests[user];
        _claimable = assetData.claimable[user];
        if (withdrawReq.amount > 0) {
            // if they have one from a previous epoch, calculate that
            // requests day 0 Value
            if (withdrawReq.epoch < currEpoch) {
                _claimable += (withdrawReq.amount * assetData.epochToRate[withdrawReq.epoch]) / RAY;
            } else {
                // if they have one from this epoch, that means the tokens are still active
                balanceDay0 += withdrawReq.amount;
            }
        }

        /* TODO: this would be better calculated if we simulated ending the epoch here
        because this doesn't consider the IL / profits from this current epoch
        but this is fine for now */
        // Note that currEpoch >= 1 since it is initialized to 1 in the constructor
        uint256 currentConversionRate = assetData.epochToRate[currEpoch - 1];

        // tokenAmount * epochToRate will not overflow even if value = total mc of crypto & rate = 3.8e10 * RAY
        return ((balanceDay0 * currentConversionRate) / RAY, _pendingDeposit, _claimable);
    }

    // ----------- Next Epoch Functions -----------

    /// @notice Struct just for wrapper around local variables to avoid the stack limit in `nextEpoch()`
    struct NextEpochVariables {
        uint256 poolBalance;
        uint256 withdrawn;
        uint256 available;
        uint256 original;
        uint256 newRate;
        uint256 newClaimable;
    }

    /// @notice Initiates the next epoch
    /// @param expectedPoolToken0 the approximate amount of TOKEN0 expected to be in the pool (preventing frontrunning)
    /// @param expectedPoolToken1 the approximate amount of TOKEN1 expected to be in the pool (preventing frontrunning)
    function nextEpoch(uint256 expectedPoolToken0, uint256 expectedPoolToken1)
        external
        override
        onlyStrategist
        whenNotPaused
    {
        require(block.timestamp - lastEpochStart >= epochDuration, "EPOCH_DURATION_UNMET");

        AssetDataStatics memory _token0Data = _assetDataStatics(token0Data);
        AssetDataStatics memory _token1Data = _assetDataStatics(token1Data);
        // These are used to avoid hitting the local variable stack limit
        NextEpochVariables memory _token0;
        NextEpochVariables memory _token1;

        uint256 currEpoch = epoch;

        // Total tokens in the liquidity pool and our ownership of those tokens
        (_token0.poolBalance, _token1.poolBalance) = getPoolBalances();
        // will not overflow with reasonable expectedPoolToken amount (DENOM = 10,000)
        require(_token0.poolBalance >= (expectedPoolToken0 * (DENOM - POOL_ERR)) / DENOM, "UNEXPECTED_POOL_BALANCES");
        require(_token0.poolBalance <= (expectedPoolToken0 * (DENOM + POOL_ERR)) / DENOM, "UNEXPECTED_POOL_BALANCES");
        require(_token1.poolBalance >= (expectedPoolToken1 * (DENOM - POOL_ERR)) / DENOM, "UNEXPECTED_POOL_BALANCES");
        require(_token1.poolBalance <= (expectedPoolToken1 * (DENOM + POOL_ERR)) / DENOM, "UNEXPECTED_POOL_BALANCES");
        // !!NOTE: After this point we don't need to worry about front-running anymore because the pool's state has been
        // verified (as long as there is no calls to untrusted external parties)

        // (1) Withdraw liquidity
        (_token0.withdrawn, _token1.withdrawn) = withdrawLiquidity();
        (_token0.poolBalance, _token1.poolBalance) = getPoolBalances();
        _token0.available = _token0.withdrawn + _token0Data.reserves;
        _token1.available = _token1.withdrawn + _token1Data.reserves;

        // (2) Perform the swap

        // Calculate the floor and ceiling returns for each side
        // will not overflow with reasonable amounts (token0/1FloorNum ~ 10,000)
        uint256 token0Floor = _token0Data.reserves + (_token0Data.active * token0FloorNum) / DENOM;
        uint256 token1Floor = _token1Data.reserves + (_token1Data.active * token1FloorNum) / DENOM;
        uint256 token1Ceiling = _token1Data.reserves + _token1Data.active;
        // Add interest to the token1 ceiling (but we don't for this version)
        // token1Ceiling += (_token1Data.active * timePassed * tokenInterest) / (RAY * 365 days);

        if (token0Floor > _token0.available) {
            // The min amount needed to reach the TOKEN0 floor
            uint256 token1NeededToSwap;
            uint256 token0Deficit = token0Floor - _token0.available;
            if (token0Deficit > _token0.poolBalance) {
                token1NeededToSwap = _token1.available;
            } else {
                token1NeededToSwap = calcAmountIn(token0Deficit, _token1.poolBalance, _token0.poolBalance);
            }

            // swap as much token1 as is necessary to get back to the token0 floor, without going
            // under the token1 floor
            uint256 swapAmount = (token1Ceiling + token1NeededToSwap < _token1.available)
                ? _token1.available - token1Ceiling
                : token1NeededToSwap + token1Floor > _token1.available
                ? _token1.available - token1Floor
                : token1NeededToSwap;

            (uint256 amountOut, uint256 amountConsumed) = swap(token1, token0, swapAmount);
            _token0.available += amountOut;
            _token1.available -= amountConsumed;
        } else if (_token1.available >= token1Ceiling) {
            // If we have more token0 than the floor and more token1 than the ceiling so we swap the excess amount
            // all to TOKEN0

            (uint256 amountOut, uint256 amountConsumed) = swap(token1, token0, _token1.available - token1Ceiling);
            _token0.available += amountOut;
            _token1.available -= amountConsumed;
        } else {
            // We have more token0 than the floor but are below the token1 ceiling
            // Min amount of TOKEN0 needed to swap to hit the token1 ceiling
            uint256 token0NeededToSwap;
            uint256 token1Deficit = token1Ceiling - _token1.available;
            if (token1Deficit > _token1.poolBalance) {
                token0NeededToSwap = _token0.poolBalance;
            } else {
                token0NeededToSwap = calcAmountIn(token1Deficit, _token0.poolBalance, _token1.poolBalance);
            }

            if (token0Floor + token0NeededToSwap < _token0.available) {
                // If we can reach the token1 ceiling without going through the TOKEN0 floor
                (uint256 amountOut, uint256 amountConsumed) = swap(token0, token1, token0NeededToSwap);
                _token0.available -= amountConsumed;
                _token1.available += amountOut;
            } else {
                // We swap as much TOKEN0 as we can without going through the TOKEN0 floor
                (uint256 amountOut, uint256 amountConsumed) = swap(token0, token1, _token0.available - token0Floor);
                _token0.available -= amountConsumed;
                _token1.available += amountOut;
            }
        }

        // (3) Add in new deposits and subtract withdrawals
        _token0.original = _token0Data.reserves + _token0Data.active;
        _token1.original = _token1Data.reserves + _token1Data.active;

        // collect protocol fee if profitable
        if (_token0.available > _token0.original) {
            // will not overflow core.protocolFee() < 10,000
            _token0.available -= ((_token0.available - _token0.original) * core.protocolFee()) / core.MAX_FEE();
        }
        if (_token1.available > _token1.original) {
            // will not overflow core.protocolFee() < 10,000
            _token1.available -= ((_token1.available - _token1.original) * core.protocolFee()) / core.MAX_FEE();
        }

        // calculate new rate (before withdraws and deposits) as available tokens divided by
        // tokens that were available at the beginning of the epoch
        // and tally claimable amount (withdraws that are now accounted for) for this token
        // tokenAmount * epochToRate will not overflow even if value = total mc of crypto & rate = 3.8e10 * RAY
        _token0.newRate = _token0.original > 0
            ? (token0Data.epochToRate[currEpoch - 1] * _token0.available) / _token0.original // no overflow
            : token0Data.epochToRate[currEpoch - 1];
        token0Data.epochToRate[currEpoch] = _token0.newRate;
        _token0.newClaimable = (_token0Data.withdrawRequestsTotal * _token0.newRate) / RAY; // no overflow
        token0Data.claimableTotal += _token0.newClaimable;
        _token1.newRate = _token1.original > 0
            ? (token1Data.epochToRate[currEpoch - 1] * _token1.available) / _token1.original // no overflow
            : token1Data.epochToRate[currEpoch - 1];
        token1Data.epochToRate[currEpoch] = _token1.newRate;
        _token1.newClaimable = (_token1Data.withdrawRequestsTotal * _token1.newRate) / RAY; // no overflow
        token1Data.claimableTotal += _token1.newClaimable;

        // calculate available token after deposits and withdraws
        _token0.available = _token0.available + _token0Data.depositRequestsTotal - _token0.newClaimable;
        _token1.available = _token1.available + _token1Data.depositRequestsTotal - _token1.newClaimable;

        token0Data.depositRequestsTotal = 0;
        token0Data.withdrawRequestsTotal = 0;
        token1Data.depositRequestsTotal = 0;
        token1Data.withdrawRequestsTotal = 0;

        // (4) Deposit liquidity back in
        (token0Data.active, token1Data.active) = depositLiquidity(_token0.available, _token1.available);
        token0Data.reserves = _token0.available - token0Data.active;
        token1Data.reserves = _token1.available - token1Data.active;

        epoch += 1;
        lastEpochStart = block.timestamp;

        emit NextEpochStarted(epoch, msg.sender, block.timestamp);
    }

    function _assetDataStatics(AssetData storage assetData) internal view returns (AssetDataStatics memory) {
        return
            AssetDataStatics({
                reserves: assetData.reserves,
                active: assetData.active,
                depositRequestsTotal: assetData.depositRequestsTotal,
                withdrawRequestsTotal: assetData.withdrawRequestsTotal
            });
    }

    // ----------- Abstract Functions Implemented For Each DEX -----------

    function getPoolBalances() internal view virtual returns (uint256 poolToken0, uint256 poolToken1);

    /// @dev This is provided automatically by the Uniswap router
    function calcAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal virtual returns (uint256 amountIn);

    /// @dev Withdraws all liquidity
    function withdrawLiquidity() internal returns (uint256 token0Withdrawn, uint256 token1Withdrawn) {
        // the combination of `unstakeLiquidity` and `_withdrawLiquidity` should never result in a decreased
        // balance of either token. If they do, this transaction will revert.
        uint256 token0BalanceBefore = token0.balanceOf(address(this));
        uint256 token1BalanceBefore = token1.balanceOf(address(this));
        _unstakeLiquidity();
        _withdrawLiquidity();
        token0Withdrawn = token0.balanceOf(address(this)) - token0BalanceBefore;
        token1Withdrawn = token1.balanceOf(address(this)) - token1BalanceBefore;
    }

    function _withdrawLiquidity() internal virtual;

    /// @dev Deposits liquidity into the pool
    function depositLiquidity(uint256 availableToken0, uint256 availableToken1)
        internal
        returns (uint256 token0Deposited, uint256 token1Deposited)
    {
        // ensure sufficient liquidity is minted, if < MIN_LP don't activate those funds
        if ((availableToken0 < MIN_LP) || (availableToken1 < MIN_LP)) return (0, 0);
        (token0Deposited, token1Deposited) = _depositLiquidity(availableToken0, availableToken1);
        _stakeLiquidity();
    }

    function _depositLiquidity(uint256 availableToken0, uint256 availableToken1)
        internal
        virtual
        returns (uint256 token0Deposited, uint256 token1Deposited);

    /// @dev Swaps tokens and handles the case where amountIn == 0
    function swap(
        IERC20Upgradeable tokenIn,
        IERC20Upgradeable tokenOut,
        uint256 amountIn
    ) internal virtual returns (uint256 amountOut, uint256 amountConsumed);

    // ----------- Rescue Funds -----------

    /// @notice rescues funds from this contract in dire situations, only when contract is paused
    /// @param tokens array of tokens to rescue
    /// @param amounts list of amounts for each token to rescue. If 0, the full balance
    function rescueTokens(address[] calldata tokens, uint256[] calldata amounts)
        external
        override
        nonReentrant
        onlyGuardian
        whenPaused
    {
        require(tokens.length == amounts.length, "INVALID_INPUTS");

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = amounts[i];
            if (tokens[i] == address(0)) {
                amount = (amount == 0) ? address(this).balance : amount;
                (bool success, ) = msg.sender.call{ value: amount }("");
                require(success, "TRANSFER_FAILED");
            } else {
                amount = (amount == 0) ? IERC20Upgradeable(tokens[i]).balanceOf(address(this)) : amount;
                IERC20Upgradeable(tokens[i]).safeTransfer(msg.sender, amount);
            }
        }
        emit FundsRescued(msg.sender);
    }

    /// @notice A function that should be called by the guardian to unstake any liquidity before rescuing LP tokens
    function unstakeLiquidity() external override nonReentrant onlyGuardian whenPaused {
        _unstakeLiquidity();
    }

    /// @notice stakes all LP tokens
    function _unstakeLiquidity() internal virtual;

    /// @notice unstakes all LP tokens
    function _stakeLiquidity() internal virtual;

    // ----------- Getter Functions -----------

    function token0ValueLocked() external view override returns (uint256) {
        return token0.balanceOf(address(this)) + token0Data.active;
    }

    function token1ValueLocked() external view override returns (uint256) {
        return token1.balanceOf(address(this)) + token1Data.active;
    }

    function token0BalanceDay0(address user) external view override returns (uint256) {
        return __user_balanceDay0(token0Data, user);
    }

    function epochToToken0Rate(uint256 _epoch) external view override returns (uint256) {
        return token0Data.epochToRate[_epoch];
    }

    function token0WithdrawRequests(address user) external view override returns (uint256) {
        return __user_requestView(token0Data.withdrawRequests[user]);
    }

    function token1BalanceDay0(address user) external view override returns (uint256) {
        return __user_balanceDay0(token1Data, user);
    }

    function epochToToken1Rate(uint256 _epoch) external view override returns (uint256) {
        return token1Data.epochToRate[_epoch];
    }

    function token1WithdrawRequests(address user) external view override returns (uint256) {
        return __user_requestView(token1Data.withdrawRequests[user]);
    }

    /// @dev This function is used to convert the way balances are internally stored to
    /// what makes sense for the user
    function __user_balanceDay0(AssetData storage assetData, address user) internal view returns (uint256) {
        uint256 res = assetData.balanceDay0[user];
        Request memory depositReq = assetData.depositRequests[user];
        if (depositReq.epoch < epoch) {
            // will not overflow even if value = total mc of crypto
            res += (depositReq.amount * RAY) / assetData.epochToRate[depositReq.epoch];
        }
        Request memory withdrawReq = assetData.withdrawRequests[user];
        if (withdrawReq.epoch == epoch) {
            // This amount has not been withdrawn yet so this is still part of
            // their Day 0 Balance
            res += withdrawReq.amount;
        }
        return res;
    }

    /// @dev This function is used to convert the way requests are internally stored to
    /// what makes sense for the user
    function __user_requestView(Request memory req) internal view returns (uint256) {
        if (req.epoch < epoch) {
            return 0;
        }
        return req.amount;
    }

    /// @notice calculates current amount of fees accrued, as the current balance of each token
    /// less the amounts each tokens that are active user funds. token0Data.active is not
    /// included because they are currently in the DEX pool
    function feesAccrued() public view override returns (uint256 token0Fees, uint256 token1Fees) {
        token0Fees =
            token0.balanceOf(address(this)) -
            token0Data.claimableTotal -
            token0Data.reserves -
            token0Data.depositRequestsTotal;
        token1Fees =
            token1.balanceOf(address(this)) -
            token1Data.claimableTotal -
            token1Data.reserves -
            token1Data.depositRequestsTotal;
    }

    /// ------------------- Setters -------------------

    /// @notice sets a new value for the token0 floor
    /// @param _token0FloorNum the new floor token0 returns (out of `DENOM`)
    function setToken0Floor(uint256 _token0FloorNum) external override onlyStrategist {
        require(_token0FloorNum > 0, "INVALID_TOKEN0_FLOOR");
        token0FloorNum = _token0FloorNum;
        emit Token0FloorUpdated(_token0FloorNum);
    }

    /// @notice sets a new value for the token1 floor
    /// @param _token1FloorNum the new floor token1 returns (out of `DENOM`)
    function setToken1Floor(uint256 _token1FloorNum) external override onlyStrategist {
        require(_token1FloorNum > 0, "INVALID_TOKEN1_FLOOR");
        token1FloorNum = _token1FloorNum;
        emit Token1FloorUpdated(_token1FloorNum);
    }

    function setEpochDuration(uint256 _epochDuration) external override onlyStrategist whenPaused {
        epochDuration = _epochDuration;
        emit EpochDurationUpdated(_epochDuration);
    }

    function setDexName(string memory _name) external override onlyStrategist {
        DEX = _name;
    }

    /// @notice sends accrued fees to the core.feeTo() address, the treasury
    function collectFees() external override {
        (uint256 token0Fees, uint256 token1Fees) = feesAccrued();
        if (token0Fees > 0) {
            token0.safeTransfer(core.feeTo(), token0Fees);
        }
        if (token1Fees > 0) {
            token1.safeTransfer(core.feeTo(), token1Fees);
        }
    }

    // To receive any native token sent here (ex. from wrapped native withdraw)
    receive() external payable {
        // no logic upon reciept of native token required
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

/// @notice Storage for uniswap V3 vaults
abstract contract UniswapVaultStorageUnpadded {
    /// @notice UniswapV3Factory address
    address public factory;
    /// @notice UniswapV3Router address
    address public router;
    // @notice UniswapV3Pool address for token0 and token1
    address public pool;
    // @notice UniswapV3NonfungiblePositionManager address
    address public positionManager;
    // @notice UniswapV3Quoter address
    address public quoter;
    // @notice vault position fee
    uint24 public fee;
    // @notice vault position liquidity
    uint128 public liquidity;
    // @notice vault position NFT token
    uint256 public tokenId;
    // @notice vault position ticks (full range by default)
    int24 public tickLower;
    int24 public tickUpper;
}

abstract contract UniswapVaultV3Storage is UniswapVaultStorageUnpadded {
    // @dev Padding 100 words of storage for upgradeability. Follows OZ's guidance.
    uint256[100] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import '@uniswap/v3-periphery/contracts/interfaces/IPoolInitializer.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IERC721Permit.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';

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
            )
        ));
    }
}
/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

interface IWrappy {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { ICore } from "../core/ICore.sol";

/// @notice Stores a reference to the core contract
/// @author Recursive Research Inc
abstract contract CoreReference is Initializable {
    ICore public core;
    bool private _paused;

    /// initialize logic contract
    /// This tag here tells OZ to not throw an error on this constructor
    /// Recommended here:
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Emitted when the pause is triggered
    event Paused();

    /// @dev Emitted when the pause is lifted
    event Unpaused();

    function __CoreReference_init(address coreAddress) internal onlyInitializing {
        __CoreReference_init_unchained(coreAddress);
    }

    function __CoreReference_init_unchained(address coreAddress) internal onlyInitializing {
        core = ICore(coreAddress);
    }

    modifier whenNotPaused() {
        require(!paused(), "PAUSED");
        _;
    }

    modifier whenPaused() {
        require(paused(), "NOT_PAUSED");
        _;
    }

    modifier onlyPauser() {
        require(core.hasRole(core.PAUSE_ROLE(), msg.sender), "NOT_PAUSER");
        _;
    }

    modifier onlyGovernor() {
        require(core.hasRole(core.GOVERN_ROLE(), msg.sender), "NOT_GOVERNOR");
        _;
    }

    modifier onlyGuardian() {
        require(core.hasRole(core.GUARDIAN_ROLE(), msg.sender), "NOT_GUARDIAN");
        _;
    }

    modifier onlyStrategist() {
        require(core.hasRole(core.STRATEGIST_ROLE(), msg.sender), "NOT_STRATEGIST");
        _;
    }

    /// @notice view function to see whether or not the contract is paused
    /// @return true if the contract is paused either by the core or independently
    function paused() public view returns (bool) {
        return (core.paused() || _paused);
    }

    function pause() external onlyPauser whenNotPaused {
        _paused = true;
        emit Paused();
    }

    function unpause() external onlyPauser whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

// Need to use IERC20Upgradeable because that is what SafeERC20Upgradeable requires
// but the interface is exactly the same as ERC20s so this still works with ERC20s
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @notice Storage for Vault
/// @author Recursive Research Inc
abstract contract VaultStorageUnpadded {
    /// @notice struct for withdraw and deposit requests
    /// @param epoch the epoch when the request was submitted
    /// @param amount size of request, if deposit it's an absolute amount of the underlying.
    ///     If withdraw, specified in "Day 0" amount
    struct Request {
        uint256 epoch;
        uint256 amount;
    }

    /// @notice struct to keep a copy of AssetData in memory during `nextEpoch` call
    struct AssetDataStatics {
        uint256 reserves;
        uint256 active;
        uint256 depositRequestsTotal;
        uint256 withdrawRequestsTotal;
    }

    /// @notice global struct to keep track of all info for an asset
    /// @param reserves total amount not active
    /// @param active total amount paired up in the Dex pool
    /// @param depositRequestsTotal total amount of queued up deposit requests
    /// @param withdrawRequestsTotal total amount of queued up withdraw requests
    /// @param balanceDay0 each user's deposited balance denominated in "day 0 tokens"
    /// @param claimable each user's amount that has been withdrawn from the LP pool and they can claim
    /// @param epochToRate exchange rate of token to day0 tokens by epoch
    /// @param depositRequests each users deposit requests
    /// @param withdrawRequests each users withdraw requests
    struct AssetData {
        uint256 reserves;
        uint256 active;
        uint256 depositRequestsTotal;
        uint256 withdrawRequestsTotal;
        uint256 claimableTotal;
        mapping(address => uint256) balanceDay0;
        mapping(address => uint256) claimable;
        mapping(uint256 => uint256) epochToRate;
        mapping(address => Request) depositRequests;
        mapping(address => Request) withdrawRequests;
    }

    /// @notice true if token0 is wrapped native
    bool public isNativeVault;

    /// @notice token that receives a "floor" return
    IERC20Upgradeable public token0;
    /// @notice token that receives a "ceiling" return
    IERC20Upgradeable public token1;

    /// @notice current epoch, set to 1 on initialization
    uint256 public epoch;
    /// @notice duration of each epoch
    uint256 public epochDuration;
    /// @notice start of last epoch, 0 on initialization
    uint256 public lastEpochStart;

    /// @notice keeps track of relevant data for TOKEN0
    AssetData public token0Data;
    /// @notice keeps track of relevant data for TOKEN1
    AssetData public token1Data;

    /// @notice minimum return for TOKEN0 (out of `vault.DENOM`) as long as TOKEN1 is above its minimum return
    uint256 public token0FloorNum;
    /// @notice minimum return for TOKEN1 (out of `vault.DENOM`)
    uint256 public token1FloorNum;
    /// @notice DEX name
    string public DEX;
}

abstract contract VaultStorage is VaultStorageUnpadded {
    // @dev Padding 100 words of storage for upgradeability. Follows OZ's guidance.
    uint256[100] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

interface IVault {
    /// @dev Emitted when a new epoch is started
    /// @param newEpoch number of the new epoch
    /// @param initiator address of the user who initiated the new epoch
    /// @param startTime timestamp of the start of this new epoch
    event NextEpochStarted(uint256 indexed newEpoch, address indexed initiator, uint256 startTime);

    /// @dev Emitted upon a new deposit request
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    /// @param user address of the user who made the deposit request
    /// @param amount amount of the asset in deposit request
    /// @param epoch epoch of the deposit request
    event DepositScheduled(bytes32 indexed assetCode, address indexed user, uint256 amount, uint256 indexed epoch);

    /// @dev Emitted upon a new withdraw request
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    /// @param user address of the user who made the withdraw request
    /// @param amountDay0 amount of the asset (day 0) in withdraw request
    /// @param epoch epoch of the withdraw request
    event WithdrawScheduled(bytes32 indexed assetCode, address indexed user, uint256 amountDay0, uint256 indexed epoch);

    /// @dev Emitted upon a user claiming their tokens after a withdraw request is processed
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    /// @param user address of the user who is claiming their assets
    /// @param amount amount of the assets (day 0) claimed
    event AssetsClaimed(bytes32 indexed assetCode, address indexed user, uint256 amount);

    /// @dev Emitted upon a guardian rescuing funds
    /// @param guardian address of the guardian who rescued the funds
    event FundsRescued(address indexed guardian);

    /// @dev Emitted upon a strategist updating the token0 floor
    /// @param newFloor the new floor returns on TOKEN0 (out of `RAY`)
    event Token0FloorUpdated(uint256 newFloor);

    /// @dev Emitted upon a strategist updating the token1 floor
    /// @param newFloor the new floor returns on TOKEN1 (out of `RAY`)
    event Token1FloorUpdated(uint256 newFloor);

    event EpochDurationUpdated(uint256 newEpochDuration);

    /// ------------------- Vault Interface -------------------

    function depositToken0(uint256 _amount) external payable;

    function depositToken1(uint256 _amount) external;

    function withdrawToken0(uint256 _amount) external;

    function withdrawToken1(uint256 _amount) external;

    function claimToken0() external;

    function claimToken1() external;

    function token0Balance(address user)
        external
        view
        returns (
            uint256 deposited,
            uint256 pendingDeposit,
            uint256 claimable
        );

    function token1Balance(address user)
        external
        view
        returns (
            uint256 deposited,
            uint256 pendingDeposit,
            uint256 claimable
        );

    function nextEpoch(uint256 expectedPoolToken0, uint256 expectedPoolToken1) external;

    function rescueTokens(address[] calldata tokens, uint256[] calldata amounts) external;

    function collectFees() external;

    function unstakeLiquidity() external;

    /// ------------------- Getters -------------------

    function token0ValueLocked() external view returns (uint256);

    function token1ValueLocked() external view returns (uint256);

    function token0BalanceDay0(address user) external view returns (uint256);

    function epochToToken0Rate(uint256 _epoch) external view returns (uint256);

    function token0WithdrawRequests(address user) external view returns (uint256);

    function token1BalanceDay0(address user) external view returns (uint256);

    function epochToToken1Rate(uint256 _epoch) external view returns (uint256);

    function token1WithdrawRequests(address user) external view returns (uint256);

    function feesAccrued() external view returns (uint256, uint256);

    /// ------------------- Setters -------------------

    function setToken0Floor(uint256 _token0FloorNum) external;

    function setToken1Floor(uint256 _token1FloorNum) external;

    function setEpochDuration(uint256 _epochDuration) external;

    function setDexName (string memory _name) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import { ICorePermissions } from "./ICorePermissions.sol";

/// @notice Interface for Core
/// @author Recursive Research Inc
interface ICore is ICorePermissions {
    // ----------- Events ---------------------

    /// @dev Emitted when the protocol fee (`protocolFee`) is changed
    ///   out of core.MAX_FEE()
    event ProtocolFeeUpdated(uint256 protocolFee);

    /// @dev Emitted when the protocol fee destination (`feeTo`) is changed
    event FeeToUpdated(address indexed feeTo);

    /// @dev Emitted when the pause is triggered
    event Paused();

    /// @dev Emitted when the pause is lifted
    event Unpaused();

    // @dev Emitted when a vault with address `vault`
    event VaultRegistered(address indexed vault);

    // @dev Emitted when a vault with address `vault`
    event VaultRemoved(address indexed vault);

    // ----------- Default Getters --------------

    /// @dev constant set to 10_000
    function MAX_FEE() external view returns (uint256);

    function feeTo() external view returns (address);

    /// @dev protocol fee out of core.MAX_FEE()
    function protocolFee() external view returns (uint256);

    function wrappedNative() external view returns (address);

    // ----------- Main Core Utility --------------

    function registerVaults(address[] memory vaults) external;

    function removeVaults(address[] memory vaults) external;

    /// @dev set core.protocolFee, out of core.MAX_FEE()
    function setProtocolFee(uint256 _protocolFee) external;

    function setFeeTo(address _feeTo) external;

    // ----------- Protocol Pausing -----------

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

/// @title Interface for CorePermissions
/// @author Recursive Research Inc
interface ICorePermissions is IAccessControlUpgradeable {
    // ----------- Events ---------------------

    /// @dev Emitted when the whitelist is disabled by `admin`.
    event WhitelistDisabled();

    /// @dev Emitted when the whitelist is disabled by `admin`.
    event WhitelistEnabled();

    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function whitelistAll(address[] memory addresses) external;

    // ----------- GRANTING ROLES -----------

    function disableWhitelist() external;

    function enableWhitelist() external;

    // ----------- Getters -----------

    function GUARDIAN_ROLE() external view returns (bytes32);

    function GOVERN_ROLE() external view returns (bytes32);

    function PAUSE_ROLE() external view returns (bytes32);

    function STRATEGIST_ROLE() external view returns (bytes32);

    function WHITELISTED_ROLE() external view returns (bytes32);

    function whitelistDisabled() external view returns (bool);

    // ----------- Read Interface -----------

    function isWhitelisted(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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