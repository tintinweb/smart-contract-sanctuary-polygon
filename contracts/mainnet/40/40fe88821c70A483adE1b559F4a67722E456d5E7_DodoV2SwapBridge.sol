// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "./interfaces/DodoV2Router.sol";
import "./interfaces/DodoV2Approve.sol";
import "../interfaces/IDodoV2Swap.sol";
/**
 * @title DodoV2SwapBridge
 * @author DeFi Basket
 *
 * @notice Swaps using the DodoV2 contract in Polygon.
 *
 * @dev This contract swaps ERC20 tokens to ERC20 tokens. Please notice that there are no payable functions.
 *
 */
/// @custom:security-contact [email protected]
contract DodoV2SwapBridge is IDodoV2Swap {
    address constant routerAddress = 0xa222e6a71D1A1Dd5F279805fbe38d5329C1d0e70;
    DodoV2Router constant router = DodoV2Router(routerAddress);
    /**
      * @notice Swaps from ERC20 token to ERC20 token.
      *
      * @dev Wraps the swap and generate the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param amountInPercentage Percentage of the balance of the input ERC20 token that will be swapped
      * @param amountOutMin Minimum amount of the output token required to execute swap
      */
    function swapTokenToToken(
        address fromToken,
        address toToken,
        uint256 amountInPercentage,
        uint256 amountOutMin,
        address[] calldata dodoPairs,
        uint256 directions
    ) external override {     
        uint256 amountIn = IERC20(fromToken).balanceOf(address(this)) * amountInPercentage / 100000;
        address approveAddress = DodoV2Approve(router._DODO_APPROVE_PROXY_())._DODO_APPROVE_();

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        IERC20(fromToken).approve(approveAddress, 0);
        IERC20(fromToken).approve(approveAddress, amountIn);

        uint256 amountOut = router.dodoSwapV2TokenToToken(
            fromToken,
            toToken,
            amountIn,
            amountOutMin,
            dodoPairs,
            directions,
            false,
            block.timestamp + 100000            
        );

        emit DEFIBASKET_DODOV2_SWAP(amountIn, amountOut);
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;


interface DodoV2Router {
    function dodoSwapV2TokenToToken(address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function _DODO_APPROVE_PROXY_() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;


interface DodoV2Approve {
    function _DODO_APPROVE_() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IDodoV2Swap {
    event DEFIBASKET_DODOV2_SWAP(
        uint256 amountIn,
        uint256 amountOut
    );

    function swapTokenToToken(
        address fromToken,
        address toToken,
        uint256 amountInPercentage,
        uint256 amountOutMin,
        address[] calldata dodoPairs,
        uint256 directions
    ) external;
}