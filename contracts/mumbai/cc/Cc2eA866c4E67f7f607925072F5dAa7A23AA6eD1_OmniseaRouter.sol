// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../interfaces/IStargateRouter.sol";
import "../interfaces/IStargateReceiver.sol";
import "../interfaces/IOmniseaReceiver.sol";

contract OmniseaRouter is IStargateReceiver {
    address public stargateRouter;      // an IStargateRouter instance
    address public ammRouter;           // an IUniswapV2Router02 instance
    address public bridgeToken;         // USDT for Stargate Pools

    // special token value that indicates the sgReceive() should swap OUT native asset
    address public OUT_TO_NATIVE = 0x0000000000000000000000000000000000000000;
    event ReceivedOnDestination(address token, uint qty, uint8 state);
    event SuccessOnCall(address indexed omReceiver, bytes srcAddress, uint16 srcChainId);
    event ErrorOnCall(address indexed omReceiver, bytes srcAddress, uint16 srcChainId);

    constructor(address _stargateRouter, address _ammRouter, address _bridgeToken) {
        stargateRouter = _stargateRouter;
        ammRouter = _ammRouter;
        bridgeToken = _bridgeToken;
    }

    //-----------------------------------------------------------------------------------------------------------------------
    // 1. swap native on source chain to native on destination chain (!)
    function swapNativeForNative(
        uint16 dstChainId,                      // Stargate/LayerZero chainId
        uint16 srcPoolId,                       // stargate poolId - *must* be the poolId for the bridgeToken asset
        uint16 dstPoolId,                       // stargate destination poolId
        uint nativeAmountIn,                    // exact amount of native token coming in on source
        address to,                             // the address to send the destination tokens to
        uint amountOutMin,                      // minimum amount of stargatePoolId token to get out of amm router
        uint amountOutMinSg,                    // minimum amount of stargatePoolId token to get out on destination chain
        uint amountOutMinDest,                  // minimum amount of native token to receive on destination
        address dstOmniseaRouter,               // destination contract. it must implement sgReceive()
        address omReceiver,                     // destination contract. it must implement sgReceive()
        bytes memory payloadForCall             // payload for the omReceive() call on destination
    ) external payable {

        require(nativeAmountIn > 0, "nativeAmountIn must be greater than 0");
        require(msg.value - nativeAmountIn > 0, "stargate requires fee to pay crosschain message");

        uint bridgeAmount;
        // using the amm router, swap native into the Stargate pool token, sending the output token to this contract
        {
            // create path[] for amm swap
            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(ammRouter).WETH();    // native IN requires that we specify the WETH in path[0]
            path[1] = bridgeToken;                             // the bridge token,

            uint[] memory amounts = IUniswapV2Router02(ammRouter).swapExactETHForTokens{value:nativeAmountIn}(
                amountOutMin,
                path,
                address(this),
                (block.timestamp + 1 hours)
            );

            bridgeAmount = amounts[1];
            require(bridgeAmount > 0, 'error: ammRouter gave us 0 tokens to swap() with stargate');

            // this contract needs to approve the stargateRouter to spend its path[1] token!
            IERC20(bridgeToken).approve(address(stargateRouter), bridgeAmount);
        }

        bytes memory data;
        {
            data = abi.encode(OUT_TO_NATIVE, amountOutMinDest, to, omReceiver, payloadForCall);
        }

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(stargateRouter).swap{value:msg.value - nativeAmountIn}(
            dstChainId,                                     // the destination chain id
            srcPoolId,                                      // the source Stargate poolId
            dstPoolId,                                      // the destination Stargate poolId
            payable(msg.sender),                            // refund adddress. if msg.sender pays too much gas, return extra eth
            bridgeAmount,                                   // total tokens to send to destination chain
            amountOutMinSg,                                 // minimum
            IStargateRouter.lzTxObj(500000, 0, "0x"),       // 500,000 for the sgReceive()
            abi.encodePacked(dstOmniseaRouter),             // destination address, the sgReceive() implementer
            data                                           // bytes payload
        );
    }

    //-----------------------------------------------------------------------------------------------------------------------
    // sgReceive() - the destination contract must implement this function to receive the tokens and payload
    function sgReceive(uint16 _srcChainId, bytes memory _srcAddress, uint /*_nonce*/, address _token, uint amountLD, bytes memory payload) override external {
        require(msg.sender == address(stargateRouter), "only stargate router can call sgReceive!");

        (address _tokenOut, uint _amountOutMin, address _toAddr, address _omReceiver, bytes memory _payloadForCall)
        = abi.decode(payload, (address, uint, address, address, bytes));

        // so that router can swap our tokens
        IERC20(_token).approve(address(ammRouter), amountLD);

        if(_tokenOut == address(0x0)){
            // get native
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = IUniswapV2Router02(ammRouter).WETH();
            bool isComposed = address(_omReceiver) != address(0);
            address nativeReceiver = isComposed ? address(this) : _toAddr;
            uint _toBalancePreTransferOut = nativeReceiver.balance;

            // use ammRouter to swap incoming bridge token into native tokens
            try IUniswapV2Router02(ammRouter).swapExactTokensForETH(
                amountLD,                               // the stable received from stargate at the destination
                _amountOutMin,                          // slippage param, min amount native token out
                path,                                   // path[0]: stable token address, path[1]: WETH from AMM router
                nativeReceiver,                         // the address to send the *out* native to
                (block.timestamp + 1 hours)             // the unix timestamp deadline
            ) {
                // success, the ammRouter should have sent the eth to them
                emit ReceivedOnDestination(OUT_TO_NATIVE, nativeReceiver.balance - _toBalancePreTransferOut, 0);

                // stack too deep workaround
                uint16 srcChainId = _srcChainId;
                bytes memory srcAddress = _srcAddress;

                if (isComposed) {
                    try IOmniseaReceiver(_omReceiver).omReceive{value: nativeReceiver.balance - _toBalancePreTransferOut}(srcChainId, srcAddress, _payloadForCall) {
                        emit SuccessOnCall(_omReceiver, srcAddress, srcChainId);
                    } catch {
                        (bool p,) = payable(_toAddr).call{value : nativeReceiver.balance - _toBalancePreTransferOut}("");
                        require(p);

                        emit ErrorOnCall(_omReceiver, srcAddress, srcChainId);
                    }
                }
            } catch {
                // send transfer _token/amountLD to msg.sender because the swap failed for some reason
                IERC20(_token).transfer(_toAddr, amountLD);
                emit ReceivedOnDestination(_token, amountLD, 1);
            }

        } else {
            // Fallback if _tokenOut is not intended to be native
            IERC20(_token).transfer(_toAddr, amountLD);
            emit ReceivedOnDestination(_token, amountLD, 2);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

interface IStargateRouter {
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

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOmniseaReceiver {
    function omReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        bytes memory _payload
    ) external payable;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}