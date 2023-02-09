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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    // If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (!_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value))
            {
                revert ForceApproveFailed();
            }
        }
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        // bool success;
        // if (permit.length == 32 * 7) {
        //     success = _makeCalldataCall(token, IERC20Permit.permit.selector, permit);
        // } else if (permit.length == 32 * 8) {
        //     success = _makeCalldataCall(token, IDaiLikePermit.permit.selector, permit);
        // } else {
        //     revert SafePermitBadLength();
        // }
        // if (!success) RevertReasonForwarder.reRevert();
    }

    function _makeCall(IERC20 token, bytes4 selector, address to, uint256 amount) private returns(bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
    }

    function _makeCalldataCall(IERC20 token, bytes4 selector, bytes calldata args) private returns(bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Library with gas-efficient string operations
library StringUtil {
    function toHex(uint256 value) internal pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    function toHex(address value) internal pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    function toHex(bytes memory data) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            function _toHex16(input) -> output {
                output := or(
                    and(input, 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000),
                    shr(64, and(input, 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000))
                )
                output := or(
                    and(output, 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000),
                    shr(32, and(output, 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000))
                )
                output := or(
                    and(output, 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000),
                    shr(16, and(output, 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000))
                )
                output := or(
                    and(output, 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000),
                    shr(8, and(output, 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000))
                )
                output := or(
                    shr(4, and(output, 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000)),
                    shr(8, and(output, 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00))
                )
                output := add(
                    add(0x3030303030303030303030303030303030303030303030303030303030303030, output),
                    mul(
                        and(
                            shr(4, add(output, 0x0606060606060606060606060606060606060606060606060606060606060606)),
                            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
                        ),
                        7   // Change 7 to 39 for lower case output
                    )
                )
            }

            result := mload(0x40)
            let length := mload(data)
            let resultLength := shl(1, length)
            let toPtr := add(result, 0x22)          // 32 bytes for length + 2 bytes for '0x'
            mstore(0x40, add(toPtr, resultLength))  // move free memory pointer
            mstore(add(result, 2), 0x3078)          // 0x3078 is right aligned so we write to `result + 2`
                                                    // to store the last 2 bytes in the beginning of the string
            mstore(result, add(resultLength, 2))    // extra 2 bytes for '0x'

            for {
                let fromPtr := add(data, 0x20)
                let endPtr := add(fromPtr, length)
            } lt(fromPtr, endPtr) {
                fromPtr := add(fromPtr, 0x20)
            } {
                let rawData := mload(fromPtr)
                let hexData := _toHex16(rawData)
                mstore(toPtr, hexData)
                toPtr := add(toPtr, 0x20)
                hexData := _toHex16(shl(128, rawData))
                mstore(toPtr, hexData)
                toPtr := add(toPtr, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract SwapV3 {
    using UniERC20 for IERC20;
    // For the scope of these swap examples,
    // we will detail the design considerations when using
    // `exactInput`, `exactInputSingle`, `exactOutput`, and  `exactOutputSingle`.

    // It should be noted that for the sake of these examples, we purposefully pass in the swap router instead of inherit the swap router for simplicity.
    // More advanced example contracts will detail how to inherit the swap router safely.

    IUniswapRouter public constant swapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // This example swaps DAI/WETH9 for single path swaps and DAI/USDC/WETH9 for multi path swaps.

    //address public constant WETH9 = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;//polygon
    address public constant WETH9 = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889; //mumbai

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor() {
        
    }

    function _transferIn(address inputToken, uint256 amountIn) internal {
        if (inputToken != address(0) && inputToken != WETH9) {
            IERC20(inputToken).uniTransferFrom(payable(msg.sender), address(this), amountIn);
            IERC20(inputToken).uniApprove(address(swapRouter), amountIn);
        }
    }

    function singleSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 amountOut,
        address recipient,
        uint256 slippageAmount
    ) public payable returns(uint256 swapAmountIn, uint256 swapAmountOut){
        if (recipient == address(0)) {
            recipient = msg.sender;
        }
        if (inputToken == address(0)) {
            inputToken = WETH9;
            require(amountIn == msg.value, "amountIn error");
        }
        if (outputToken == address(0)) {
            outputToken = WETH9;
        }

        if (amountOut == 0) {
            swapAmountIn = amountIn;
            swapAmountOut = swapExactInputSingle(trader, inputToken, outputToken, amountIn, slippageAmount, recipient);
        } else {
            swapAmountOut = amountOut;
            swapAmountIn = swapExactOutputSingle(trader, inputToken, outputToken, amountOut, slippageAmount, recipient);
        }
    }


    function swapExactInputSingle(
        address trader,
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) public payable returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountIn);
        // TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);
        _transferIn(tokenIn, amountIn);
        // Naively set amountOutMinimum to 0. 
        // In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle{value: tokenIn == WETH9 ? amountIn : 0}(params);
    }


    function swapExactOutputSingle(
        address trader,
        address tokenIn, 
        address tokenOut, 
        uint256 amountOut, 
        uint256 amountInMaximum,
        address recipient
    ) public returns (uint256 amountIn) {
        _transferIn(tokenIn, amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle{value: tokenIn == WETH9 ? amountIn : 0}(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            if (tokenIn == WETH9) {
                swapRouter.refundETH();
                IERC20(address(0)).uniTransfer(payable(trader), amountInMaximum - amountIn);  
            } else {
                IERC20(tokenIn).uniTransfer(payable(trader), amountInMaximum - amountIn);   
                if (tokenIn != address(0)) {
                    IERC20(tokenIn).uniApprove(address(swapRouter), 0);
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SafeERC20.sol";
import "./StringUtil.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC20MetadataUppercase {
    function NAME() external view returns (string memory);  // solhint-disable-line func-name-mixedcase
    function SYMBOL() external view returns (string memory);  // solhint-disable-line func-name-mixedcase
}

library UniERC20 {
    using SafeERC20 for IERC20;

    error InsufficientBalance();
    error ApproveCalledOnETH();
    error NotEnoughValue();
    error FromIsNotSender();
    error ToIsNotThis();
    error ETHTransferFailed();

    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;
    IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

    function isETH(IERC20 token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    /// @dev note that this function does nothing in case of zero amount
    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                if (address(this).balance < amount) revert InsufficientBalance();
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = to.call{value: amount, gas: _RAW_CALL_GAS_LIMIT}("");
                if (!success) revert ETHTransferFailed();
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    /// @dev note that this function does nothing in case of zero amount
    function uniTransferFrom(IERC20 token, address payable from, address to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                if (msg.value < amount) revert NotEnoughValue();
                if (from != msg.sender) revert FromIsNotSender();
                if (to != address(this)) revert ToIsNotThis();
                if (msg.value > amount) {
                    // Return remainder if exist
                    unchecked {
                        // solhint-disable-next-line avoid-low-level-calls
                        (bool success, ) = from.call{value: msg.value - amount, gas: _RAW_CALL_GAS_LIMIT}("");
                        if (!success) revert ETHTransferFailed();
                    }
                }
            } else {
                token.safeTransferFrom(from, to, amount);
            }
        }
    }

    function uniSymbol(IERC20 token) internal view returns(string memory) {
        return _uniDecode(token, IERC20Metadata.symbol.selector, IERC20MetadataUppercase.SYMBOL.selector);
    }

    function uniName(IERC20 token) internal view returns(string memory) {
        return _uniDecode(token, IERC20Metadata.name.selector, IERC20MetadataUppercase.NAME.selector);
    }

    function uniApprove(IERC20 token, address to, uint256 amount) internal {
        if (isETH(token)) revert ApproveCalledOnETH();

        token.forceApprove(to, amount);
    }

    /// 20K gas is provided to account for possible implementations of name/symbol
    /// (token implementation might be behind proxy or store the value in storage)
    function _uniDecode(IERC20 token, bytes4 lowerCaseSelector, bytes4 upperCaseSelector) private view returns(string memory result) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSelector(lowerCaseSelector)
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSelector(upperCaseSelector)
            );
        }

        if (success && data.length >= 0x40) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            if (offset == 0x20 && len > 0 && data.length == 0x40 + len) {
                /// @solidity memory-safe-assembly
                assembly { // solhint-disable-line no-inline-assembly
                    result := add(data, 0x20)
                }
                return result;
            }
        }

        if (success && data.length == 32) {
            uint256 len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                unchecked {
                    len++;
                }
            }

            if (len > 0) {
                /// @solidity memory-safe-assembly
                assembly { // solhint-disable-line no-inline-assembly
                    mstore(data, len)
                }
                return string(data);
            }
        }

        return StringUtil.toHex(address(token));
    }
}