// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../ISwapPlace.sol";
import "../connector/balancer/BalancerStuff.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BalancerSwapPlace is ISwapPlace {

    IVault public balancerVault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    function swapPlaceType() external override pure returns (string memory) {
        return "BalancerSwapPlace";
    }

    function swap(SwapRoute calldata route) external override returns (uint256){

        bytes32 poolId = IBalancerPool(route.pool).getPoolId();

        IERC20(route.tokenIn).approve(address(balancerVault), IERC20(route.tokenIn).balanceOf(address(this)));

        IVault.SingleSwap memory singleSwap = IVault.SingleSwap(
            poolId,
            IVault.SwapKind.GIVEN_IN,
            IAsset(route.tokenIn),
            IAsset(route.tokenOut),
            route.amountIn,
            new bytes(0)
        );

        IVault.FundManagement memory fundManagement = IVault.FundManagement(
            address(this),
            false,
            payable(msg.sender),
            false
        );

        return balancerVault.swap(singleSwap, fundManagement, 0, block.timestamp + 600);
    }


    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address pool
    ) external override view returns (uint256){

        bytes32 poolId = IBalancerPool(pool).getPoolId();

        (, IVault.PoolSpecialization poolSpecialization) = balancerVault.getPool(poolId);
        (IERC20[] memory tokens, uint256[] memory balances,) = balancerVault.getPoolTokens(poolId);
        (uint256 indexIn, uint256 indexOut) = getIndexes(IERC20(tokenIn), IERC20(tokenOut), tokens);


        IPoolSwapStructs.SwapRequest memory swapRequest;
        swapRequest.kind = IVault.SwapKind.GIVEN_IN;
        swapRequest.tokenIn = IERC20(tokenIn);
        swapRequest.tokenOut = IERC20(tokenOut);
        swapRequest.amount = amountIn;

        if (poolSpecialization == IVault.PoolSpecialization.GENERAL) {
            return IBalancerPool(pool).onSwap(
                swapRequest,
                balances,
                indexIn,
                indexOut
            );
        }

        if (
            poolSpecialization == IVault.PoolSpecialization.MINIMAL_SWAP_INFO ||
            poolSpecialization == IVault.PoolSpecialization.TWO_TOKEN
        ) {
            return IBalancerPool(pool).onSwap(
                swapRequest,
                balances[indexIn],
                balances[indexOut]
            );
        }

        revert("Unknown balancer poolSpecialization");
    }


    function getIndexes(
        IERC20 tokenIn,
        IERC20 tokenOut,
        IERC20[] memory tokens
    ) internal pure returns (uint256, uint256){
        uint256 indexIn = type(uint256).max;
        uint256 indexOut = type(uint256).max;
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == tokenIn) {
                indexIn = i;
            } else if (tokens[i] == tokenOut) {
                indexOut = i;
            }
        }
        require(
            indexIn != type(uint256).max && indexOut != type(uint256).max,
            "Can't find index for tokens in pool"
        );
        return (indexIn, indexOut);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./Structures.sol";


interface ISwapPlace is Structures {

    function swapPlaceType() external view returns (string memory);

    function swap(
        SwapRoute calldata route
    ) external returns (uint256);

    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address pool
    ) external view returns (uint256);

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

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}


interface IVault {

    enum PoolSpecialization {GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN}


    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);


    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
    external
    view
    returns (
        uint256 cash,
        uint256 managed,
        uint256 lastChangeBlock,
        address assetManager
    );


    function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
        IERC20[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );


    enum SwapKind {GIVEN_IN, GIVEN_OUT}

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

}

interface IPoolSwapStructs {
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

interface IBalancerPool is IPoolSwapStructs {

    function getPoolId() external view returns (bytes32);

    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external view returns (uint256 amount);

    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external view returns (uint256 amount);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


interface Structures {

    struct SwapRoute {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        address swapPlace;
        address pool;
        //        string swapPlaceType;
    }

}