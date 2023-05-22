/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface UniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface StargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract StableSwapAgregator {
    address private OWNER;
    address private immutable uniswapV2Router;
    address public immutable stargateRouterAddress;

    constructor(
        address _uniswapV2Router, 
        address _stargateRouterAddress
    ) {
        OWNER = msg.sender;
        uniswapV2Router = _uniswapV2Router;
        stargateRouterAddress = _stargateRouterAddress;
    }

    modifier ownerRestrict {
        require(OWNER == msg.sender, "Error: caller is not an OWNER");
        _;
    }

    function stableSwapMulticall(
        address to,
        uint256 slippage,
        address tokenOut,
        bytes[] calldata datas, 
        bytes calldata stargateSwapData
    ) external payable {
        uint256 amount = 0;
        for(uint8 i = 0; i < datas.length; ) {
            (
                address tokenIn,
                uint256 amountOutMinimum
            ) = abi.decode(datas[i], (address, uint256));
            IERC20 token = IERC20(tokenIn);
            uint256 balance = token.balanceOf(msg.sender);
            token.transfer(address(this), balance);
            token.approve(uniswapV2Router, balance);
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            uint256[] memory amounts = UniswapV2Router(uniswapV2Router).swapExactTokensForTokens(
                balance, amountOutMinimum, path, address(this), block.timestamp
            );
            amount += amounts[1];
            unchecked { i++; }
        }
        if (bytes32(stargateSwapData) != bytes32("0x")) {
            IERC20(tokenOut).approve(stargateRouterAddress, amount);
            stargateStableSwap(slippage, amount, stargateSwapData);
        }
        else IERC20(tokenOut).transfer(to, amount);
    }

    function stargateStableSwap(
        uint256 slippage,
        uint256 amountIn,
        bytes calldata stargateSwapData
    ) internal {
        (
            uint16 chainId,
            uint256 srcPoolId,
            uint256 destPoolId,
            address payable refundAddress, 
            StargateRouter.lzTxObj memory lzTxParams, 
            bytes memory to,
            bytes memory payload
        ) = abi.decode(stargateSwapData, (uint16, uint256, uint256, address, StargateRouter.lzTxObj, bytes, bytes));
        uint256 amountOutMin = amountIn - (amountIn * slippage) / 1000;
        {
            uint256 _amountIn = amountIn;
            StargateRouter(stargateRouterAddress).swap{value: msg.value}(
                chainId, 
                srcPoolId, 
                destPoolId, 
                refundAddress,
                _amountIn, 
                amountOutMin, 
                lzTxParams, 
                to, 
                payload
            );
        }
    }

    function changeOwner(address owner) external ownerRestrict {
        OWNER = owner;
    }

    receive() external payable {}
}