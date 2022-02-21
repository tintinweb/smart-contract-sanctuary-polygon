// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { KyberV1ExchangeAdapterBase } from "./lib/KyberV1ExchangeAdapterBase.sol";

/**
 * @title KyberV1ExchangeAdapterV2
 * @author Matrix
 *
 * @dev KyberSwap V1 exchange adapter that returns calldata for trading includes option for 2 different trade types.
 */
contract KyberV1ExchangeAdapterV2 is KyberV1ExchangeAdapterBase {
    // ==================== Constants ====================

    // DMMRouter02 function string for swapping exact tokens for a minimum of receive tokens
    // uint256 amountIn, uint256 amountOutMin, address[] memory poolsPath, IERC20[] memory path, address to, uint256 deadline
    string public constant SWAP_EXACT_TOKENS_FOR_TOKENS = "swapExactTokensForTokens(uint256,uint256,address[],address[],address,uint256)";

    // DMMRouter02 function string for swapping tokens for an exact amount of receive tokens
    // uint256 amountOut, uint256 amountInMax, address[] memory poolsPath, IERC20[] memory path, address to, uint256 deadline
    string public constant SWAP_TOKENS_FOR_EXACT_TOKENS = "swapTokensForExactTokens(uint256,uint256,address[],address[],address,uint256)";

    // ==================== Constructor function ====================

    constructor(address factory, address router) KyberV1ExchangeAdapterBase(factory, router) {}

    // ==================== External functions ====================

    /**
     * @dev Return calldata for KyberSwap V1 DMMRouter02. Trade paths and bool to select trade function are encoded in the arbitrary data parameter.
     *
     * @notice When selecting the swap for exact tokens function:
     * srcQuantity is defined as the max token quantity you are willing to trade,
     * minDestinationQuantity is the exact quantity of token you are receiving.
     *
     * @param to              Address that assets should be transferred to
     * @param srcQuantity     Fixed/Max amount of source token to sell
     * @param destQuantity    Min/Fixed amount of destination token to buy
     * @param data            Bytes containing trade path and bool to determine function string
     *
     * @return target         Target contract address
     * @return value          Call value
     * @return callData       Trade calldata
     */
    function getTradeCalldata(
        address srcToken,
        address destToken,
        address to,
        uint256 srcQuantity,
        uint256 destQuantity,
        bytes memory data
    )
        external
        view
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        require(srcToken != address(0), "KEAb0a");
        require(destToken != address(0), "KEAb0b");
        require(to != address(0), "KEAb0c");

        (address[] memory path, bool shouldSwapExactTokensForTokens) = abi.decode(data, (address[], bool));
        require(path.length >= 2, "KEAbd");

        address[] memory poolsPath = new address[](path.length - 1);
        for (uint256 i = 0; i < poolsPath.length; i++) {
            poolsPath[i] = _getBestPool(path[i], path[i + 1]);
        }

        value = 0;
        target = _router;
        callData = shouldSwapExactTokensForTokens
            ? abi.encodeWithSignature(SWAP_EXACT_TOKENS_FOR_TOKENS, srcQuantity, destQuantity, poolsPath, path, to, block.timestamp)
            : abi.encodeWithSignature(SWAP_TOKENS_FOR_EXACT_TOKENS, destQuantity, srcQuantity, poolsPath, path, to, block.timestamp);
    }

    /**
     * @dev Generate data parameter to be passed to `getTradeCalldata`. Returns encoded trade paths and bool to select trade function.
     *
     * @param srcToken     Address of the source token to be sold
     * @param destToken    Address of the destination token to buy
     * @param fixIn        Boolean representing if input tokens amount is fixed
     *
     * @return bytes       Data parameter to be passed to `getTradeCalldata`
     */
    function createDataParam(
        address srcToken,
        address destToken,
        bool fixIn
    ) external pure returns (bytes memory) {
        address[] memory path = new address[](2);
        path[0] = srcToken;
        path[1] = destToken;

        return abi.encode(path, fixIn);
    }

    function createDataParam2(
        address srcToken,
        address midToken,
        address destToken,
        bool fixIn
    ) external pure returns (bytes memory) {
        address[] memory path = new address[](3);
        path[0] = srcToken;
        path[1] = midToken;
        path[2] = destToken;

        return abi.encode(path, fixIn);
    }

    /**
     * @dev Helper that returns the encoded data of trade path and boolean indicating the KyberV1 function to use
     *
     * @return bytes    Encoded data used for trading on KyberV1
     */
    function getExchangeData(address[] memory path, bool shouldSwapExactTokensForTokens) external pure returns (bytes memory) {
        return abi.encode(path, shouldSwapExactTokensForTokens);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ==================== Internal Imports ====================

import { IDMMPool } from "../../../../interfaces/external/kyber/IDMMPool.sol";
import { IDMMFactory } from "../../../../interfaces/external/kyber/IDMMFactory.sol";

import { IExchangeAdapter } from "../../../../interfaces/IExchangeAdapter.sol";

/**
 * @title KyberV1ExchangeAdapterBase
 * @author Matrix
 */
abstract contract KyberV1ExchangeAdapterBase is IExchangeAdapter {
    // ==================== Variables ====================

    IDMMFactory internal immutable _factory; // KyberSwap v1 factory
    address internal immutable _router; // Address of KyberSwap V1 DMMRouter02

    // ==================== Constructor function ====================

    constructor(address factory, address router) {
        _factory = IDMMFactory(factory);
        _router = router;
    }

    // ==================== External functions ====================

    /**
     * @dev Returns the KyberSwap factory address.
     */
    function getFactory() external view returns (address) {
        return address(_factory);
    }

    /**
     * @dev Returns the KyberSwap router address to approve source tokens for trading.
     */
    function getSpender() external view returns (address) {
        return _router;
    }

    // ==================== Internal functions ====================

    function _getBestPool(address token1, address token2) internal view returns (address bestPool) {
        address[] memory poolAddresses = _factory.getPools(IERC20(token1), IERC20(token2));
        require(poolAddresses.length > 0, "BKEA0");
        bestPool = poolAddresses[0];

        uint256 highestKLast = 0;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            uint256 currentKLast = IDMMPool(poolAddresses[i]).kLast();
            if (currentKLast > highestKLast) {
                highestKLast = currentKLast;
                bestPool = poolAddresses[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: BUSL-1.1

// Copy from https://github.com/KyberNetwork/dmm-smart-contracts/blob/master/contracts/interfaces/IDMMPool.sol under terms of BUSL-1.1 with slight modifications

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ==================== Internal Imports ====================

import "./IDMMFactory.sol";

interface IDMMPool {
    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getTradeInfo()
        external
        view
        returns (
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint112 reserve0,
            uint112 reserve1,
            uint256 feeInPrecision
        );

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function ampBps() external view returns (uint32);

    function factory() external view returns (IDMMFactory);

    function kLast() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

// Copy from https://github.com/KyberNetwork/dmm-smart-contracts/blob/master/contracts/interfaces/IDMMFactory.sol under terms of BUSL-1.1 with slight modifications

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDMMFactory {
    function createPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps
    ) external returns (address pool);

    function setFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

    function setFeeToSetter(address) external;

    function getFeeConfiguration() external view returns (address feeTo, uint16 governmentFeeBps);

    function feeToSetter() external view returns (address);

    function allPools(uint256) external view returns (address pool);

    function allPoolsLength() external view returns (uint256);

    function getUnamplifiedPool(IERC20 token0, IERC20 token1) external view returns (address);

    function getPools(IERC20 token0, IERC20 token1)
        external
        view
        returns (address[] memory _tokenPools);

    function isPool(
        IERC20 token0,
        IERC20 token1,
        address pool
    ) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IExchangeAdapter
 * @author Matrix
 */
interface IExchangeAdapter {
    // ==================== External functions ====================

    function getSpender() external view returns (address);

    /**
     * @param srcToken           Address of source token to be sold
     * @param destToken          Address of destination token to buy
     * @param destAddress        Address that assets should be transferred to
     * @param srcQuantity        Amount of source token to sell
     * @param minDestQuantity    Min amount of destination token to buy
     * @param data               Arbitrary bytes containing trade call data
     *
     * @return target            Target contract address
     * @return value             Call value
     * @return callData          Trade calldata
     */
    function getTradeCalldata(
        address srcToken,
        address destToken,
        address destAddress,
        uint256 srcQuantity,
        uint256 minDestQuantity,
        bytes memory data
    )
        external
        view
        returns (
            address target,
            uint256 value,
            bytes memory callData
        );
}