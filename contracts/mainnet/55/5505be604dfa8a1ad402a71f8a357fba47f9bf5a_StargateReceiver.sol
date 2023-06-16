// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./interfaces/IERC20.sol";
import {IUniswapRouterV2} from "./interfaces/IUniswapRouterV2.sol";

contract StargateReceiver {
    address public stargate;
    IUniswapRouterV2 public router;

    event Swap(address token, address to, uint256 bridgeAmount, uint256 amount); 

    constructor(address _stargate, address _router) {
        stargate = _stargate;
        router = IUniswapRouterV2(_router);
    }

    function sgReceive(
        uint16,
        bytes memory,
        uint256,
        address bridgeToken,
        uint256 bridgeAmount,
        bytes memory payload
    ) external {
        require(msg.sender == address(stargate), "!stargate");
        (address token, address to, uint256 amountOutMin) =
            abi.decode(payload, (address, address, uint256));

        IERC20(bridgeToken).approve(address(router), bridgeAmount);
        if (token == address(0)) {
            uint256 before = to.balance;
            address[] memory path = new address[](2);
            path[0] = bridgeToken;
            path[1] = router.WETH();
            try router.swapExactTokensForETH(
                bridgeAmount,
                amountOutMin,
                path,
                to,
                type(uint256).max
            ) {
                emit Swap(token, to, bridgeAmount, to.balance - before);
            } catch {
                IERC20(bridgeToken).transfer(to, bridgeAmount);
                emit Swap(bridgeToken, to, bridgeAmount, bridgeAmount);
            }
        } else {
            uint256 before = IERC20(token).balanceOf(to);
            address[] memory path = new address[](3);
            path[0] = bridgeToken;
            path[1] = router.WETH();
            path[2] = token;
            try router.swapExactTokensForTokens(
                bridgeAmount,
                amountOutMin,
                path,
                to,
                type(uint256).max
            ) {
                emit Swap(token, to, bridgeAmount, IERC20(token).balanceOf(to) - before);
            } catch {
                IERC20(bridgeToken).transfer(to, bridgeAmount);
                emit Swap(bridgeToken, to, bridgeAmount, bridgeAmount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IUniswapRouterV2 {
    function WETH() external view returns (address);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to, uint deadline
    ) external payable;
}