// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

// import { BytesLib } from "../../../external/BytesLib.sol";

// import { ISwapRouter } from "../../../interfaces/external/uniswap-v3/ISwapRouter.sol";

/**
 * @title UniswapV3ExchangeAdapterV2
 * @author Matrix
 *
 * Exchange adapter for Uniswap V3 SwapRouter02 that encodes trade data
 */
contract UniswapV3ExchangeAdapterV2 {
    // ==================== Constants ====================

    string internal constant EXACT_INPUT = "swapExactTokensForTokens(uint256,uint256,address[],address)";

    // ==================== Variables ====================

    // Address of Uniswap V3 SwapRouter02 contract
    address public immutable _swapRouter02;

    // ==================== Constructor function ====================

    /**
     * @param swapRouter02    Address of Uniswap V3 SwapRouter
     */
    constructor(address swapRouter02) {
        _swapRouter02 = swapRouter02;
    }

    // ==================== External functions ====================

    /**
     * @dev Return calldata for Uniswap V3 SwapRouter
     *
     * @param srcToken           Address of source token to be sold
     * @param destToken          Address of destination token to buy
     * @param to                 Address that assets should be transferred to
     * @param srcQuantity        Amount of source token to sell
     * @param minDestQuantity    Min amount of destination token to buy
     * @param data               Uniswap V3 path.
     *
     * @return target            Target contract address
     * @return value             Call value
     * @return callData          Trade calldata
     */
    function getTradeCalldata(
        address srcToken,
        address destToken,
        address to,
        uint256 srcQuantity,
        uint256 minDestQuantity,
        bytes calldata data
    )
        external
        view
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        require(srcToken != address(0), "UcEAb0a");
        require(destToken != address(0), "UcEAb0b");
        require(srcToken != destToken, "UcEAb0c");
        require(to != address(0), "UcEAb0d");

        address[] memory path;

        if (data.length == 0) {
            path = new address[](2);
            path[0] = srcToken;
            path[1] = destToken;
        } else {
            path = abi.decode(data, (address[]));
            require(path.length >= 2, "UcEA0e");
        }

        value = 0;
        target = _swapRouter02;

        // swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
        callData = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address)",
            srcQuantity, // amountIn
            minDestQuantity, // amountOutMin
            path, // path
            to // to
        );
    }

    /**
     * @dev Returns the address to approve source tokens for trading. This is the Uniswap SwapRouter address
     *
     * @return address    Address of the contract to approve tokens to
     */
    function getSpender() external view returns (address) {
        return _swapRouter02;
    }
}