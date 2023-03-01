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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "./IAsset.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

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
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
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
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "./Balancer/IVault.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Trader {
    address payable owner;

    // Aave ERC20 Token addresses on Goerli network
    address private immutable daiAddress =
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address private immutable usdcAddress =
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private immutable wethAddress =
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private immutable wmaticAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private immutable balAddress =
        0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;
    address private immutable wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address private immutable balancerVaultAddr =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    bytes32 private immutable bal_ETH_MATIC_BAL_USDC_pool =
        0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant usdcPoolFee = 500;

    ISwapRouter public immutable swapRouter;
    IVault public immutable balancerVault;

    constructor(ISwapRouter _swapRouter) {
        owner = payable(msg.sender);
        swapRouter = _swapRouter;
        balancerVault = IVault(balancerVaultAddr);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    function approveBalancer() external onlyOwner {
        IERC20(usdcAddress).approve(
            balancerVaultAddr,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
        IERC20(wethAddress).approve(
            balancerVaultAddr,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
        IERC20(wmaticAddress).approve(
            balancerVaultAddr,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
    }

    function approve(
        address addr,
        address _token,
        uint256 amountIn
    ) external onlyOwner {
        IERC20(_token).approve(addr, amountIn);
    }

    function withdraw(address _token, uint256 amountOut) public onlyOwner {
        if (amountOut == 0) {
            amountOut = IERC20(_token).balanceOf(address(this));
        }
        IERC20(_token).transfer(msg.sender, amountOut);
    }

    // function testSwap(uint256 amountIn, uint256 ethOutMin)
    //     external
    //     returns (uint256 amountOut)
    // {
    //     ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
    //         .ExactInputSingleParams({
    //             tokenIn: usdcAddress,
    //             tokenOut: wethAddress,
    //             fee: poolFee,
    //             recipient: address(this),
    //             deadline: block.timestamp,
    //             amountIn: amountIn,
    //             amountOutMinimum: ethOutMin,
    //             sqrtPriceLimitX96: 0
    //         });

    //     // The call to `exactInputSingle` executes the swap.
    //     amountOut = swapRouter.exactInputSingle(params);
    // }

    function testBalSwap(uint256 amountIn, uint256 limit) external {
        IVault.SingleSwap memory sd;
        sd.poolId = bal_ETH_MATIC_BAL_USDC_pool;
        sd.kind = IVault.SwapKind.GIVEN_IN;
        sd.assetIn = IAsset(usdcAddress);
        sd.assetOut = IAsset(wethAddress);
        sd.amount = amountIn;
        sd.userData = "0x";

        IVault.FundManagement memory fm;
        fm.sender = address(this);
        fm.fromInternalBalance = false;
        fm.recipient = payable(address(this));
        fm.toInternalBalance = false;

        balancerVault.swap(sd, fm, limit, block.timestamp);
    }

    function swapStrategyOne(
        uint256 amountIn,
        uint256 ethOutMin,
        uint256 usdcOutMin
    ) external returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdcAddress,
                tokenOut: wethAddress,
                fee: usdcPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: ethOutMin,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 ethOut = swapRouter.exactInputSingle(params);

        IVault.SingleSwap memory sd;
        sd.poolId = bal_ETH_MATIC_BAL_USDC_pool;
        sd.kind = IVault.SwapKind.GIVEN_IN;
        sd.assetIn = IAsset(wethAddress);
        sd.assetOut = IAsset(wmaticAddress);
        sd.amount = ethOut;
        IVault.FundManagement memory fm;
        fm.sender = address(this);
        fm.fromInternalBalance = false;
        fm.recipient = payable(address(this));
        fm.toInternalBalance = false;

        uint256 maticOut = balancerVault.swap(sd, fm, 0, block.timestamp);

        ISwapRouter.ExactInputSingleParams memory outParam = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: wmaticAddress,
                tokenOut: usdcAddress,
                fee: usdcPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: maticOut,
                amountOutMinimum: usdcOutMin,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(outParam);
    }

    function swapStrategyTwo(
        uint256 amountIn,
        uint256 maticOutMin,
        uint256 usdcOutMin
    ) external returns (uint256 amountOut) {
        IVault.SingleSwap memory sd;
        sd.poolId = bal_ETH_MATIC_BAL_USDC_pool;
        sd.kind = IVault.SwapKind.GIVEN_IN;
        sd.assetIn = IAsset(usdcAddress);
        sd.assetOut = IAsset(wethAddress);
        sd.amount = amountIn;
        IVault.FundManagement memory fm;
        fm.sender = address(this);
        fm.fromInternalBalance = false;
        fm.recipient = payable(this);
        fm.toInternalBalance = false;

        uint256 ethOut = balancerVault.swap(sd, fm, 0, block.timestamp);

        ISwapRouter.ExactInputSingleParams memory outParam = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: wethAddress,
                tokenOut: wmaticAddress,
                fee: usdcPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethOut,
                amountOutMinimum: maticOutMin,
                sqrtPriceLimitX96: 0
            });
        uint256 maticOut = swapRouter.exactInputSingle(outParam);

        sd.poolId = bal_ETH_MATIC_BAL_USDC_pool;
        sd.kind = IVault.SwapKind.GIVEN_IN;
        sd.assetIn = IAsset(wmaticAddress);
        sd.assetOut = IAsset(wethAddress);
        sd.amount = maticOut;
        fm.sender = address(this);
        fm.fromInternalBalance = false;
        fm.recipient = payable(this);
        fm.toInternalBalance = false;

        uint256 ethOut2 = balancerVault.swap(sd, fm, 0, block.timestamp);

        ISwapRouter.ExactInputSingleParams memory outParam2 = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: wethAddress,
                tokenOut: usdcAddress,
                fee: usdcPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethOut2,
                amountOutMinimum: usdcOutMin,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(outParam2);
    }

    function swapStrategyThree(uint256 amountIn, uint256 usdcOutMin)
        external
        returns (uint256 amountOut)
    {
        IVault.SingleSwap memory sd;
        sd.poolId = bal_ETH_MATIC_BAL_USDC_pool;
        sd.kind = IVault.SwapKind.GIVEN_IN;
        sd.assetIn = IAsset(usdcAddress);
        sd.assetOut = IAsset(wethAddress);
        sd.amount = amountIn;
        IVault.FundManagement memory fm;
        fm.sender = address(this);
        fm.fromInternalBalance = false;
        fm.recipient = payable(this);
        fm.toInternalBalance = false;

        uint256 ethOut = balancerVault.swap(sd, fm, 0, block.timestamp);

        ISwapRouter.ExactInputSingleParams memory outParam = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: wethAddress,
                tokenOut: usdcAddress,
                fee: usdcPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethOut,
                amountOutMinimum: usdcOutMin,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(outParam);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() public {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    receive() external payable {}
}