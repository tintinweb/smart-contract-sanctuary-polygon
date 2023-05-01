// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./utils/UpgradeableBase.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/IUniswapV3.sol";
import "./interfaces/IDODOSwap.sol";
import "./interfaces/IAlgebra.sol";

interface IWETH {
    function withdraw(uint256 wad) external;
}

library SwapGatewayLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 private constant BASE = 10**18;
    address private constant ZERO_ADDRESS = address(0);

    /**
     * @notice Generate abi.encodePacked path for UniswapV3 multihop swap
     * @param tokens list of tokens
     * @param fees list of pool fees
     */
    function generateEncodedPathWithFee(
        address[] memory tokens,
        uint24[] memory fees
    ) public pure returns (bytes memory) {
        require(tokens.length == fees.length + 1, "SG3");

        bytes memory path = new bytes(0);

        for (uint256 i = 0; i < fees.length; i++) {
            path = abi.encodePacked(path, tokens[i], fees[i]);
        }

        path = abi.encodePacked(path, tokens[tokens.length - 1]);

        return path;
    }

    /**
     * @notice Generate abi.encodePacked path for QuickswapV3 multihop swap
     * @param tokens list of tokens
     */
    function generateEncodedPath(address[] memory tokens)
        public
        pure
        returns (bytes memory)
    {
        bytes memory path = new bytes(0);

        for (uint256 i = 0; i < tokens.length; i++) {
            path = abi.encodePacked(path, tokens[i]);
        }

        return path;
    }

    /**
     * @notice get UniswapV3 amount out for 1 decimal
     * if token 1 = wBNB (deciaml = 18, price = 331USD), token 2 = USDC(decmail = 6), amountOut = 331000000
     * @param swapRouter swap router address
     * @param tokenIn Address of token input
     * @param tokenOut Address of token output
     * @return amountOut amount of tokenOut : decimal = tokenOut.decimals + 18 - tokenIn.decimals;
     */
    function getUniswapV3Quote(
        address swapRouter,
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 amountOut) {
        // Find Pool
        (address uniswapV3Pool, ) = _findUniswapV3Pool(
            swapRouter,
            tokenIn,
            tokenOut
        );

        // Calulate Quote
        Slot0 memory slot0 = IUniswapV3Pool(uniswapV3Pool).slot0();

        amountOut = _calcUniswapV3Quote(
            tokenIn,
            IUniswapV3Pool(uniswapV3Pool).token0(),
            slot0.sqrtPriceX96
        );
    }

    /**
     * @notice get QuickswapV3 amount out for 1 decimal
     * if token 1 = wBNB (deciaml = 18, price = 331USD), token 2 = USDC(decmail = 6), amountOut = 331000000
     * @param swapRouter swap router address
     * @param tokenIn Address of token input
     * @param tokenOut Address of token output
     * @return amountOut amount of tokenOut : decimal = tokenOut.decimals + 18 - tokenIn.decimals;
     */
    function getQuickswapV3Quote(
        address swapRouter,
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 amountOut) {
        // Find Pool
        (address pool, ) = _findQuickswapV3Pool(swapRouter, tokenIn, tokenOut);

        // Calulate Quote
        (uint160 price, , , , , , ) = IQuickswapV3Pool(pool).globalState();

        amountOut = _calcUniswapV3Quote(
            tokenIn,
            IQuickswapV3Pool(pool).token0(),
            price
        );
    }

    /**
     * @notice Calculate UniswapV3 price quote
     * @param tokenIn Address of token input
     * @param baseToken Base token of pool
     * @param price slot0 of pool
     * @return amountOut calculated result
     */
    function _calcUniswapV3Quote(
        address tokenIn,
        address baseToken,
        uint160 price
    ) private pure returns (uint256 amountOut) {
        if (tokenIn == baseToken) {
            if (price > 10**29) {
                amountOut = ((price * 10**9) / 2**96)**2;
            } else {
                amountOut = (uint256(price)**2 * BASE) / (2**192);
            }
        } else {
            if (price > 10**35) {
                amountOut = ((2**96 * 10**9) / (price))**2;
            } else {
                amountOut = (2**192 * BASE) / (uint256(price)**2);
            }
        }
    }

    /**
     * @notice Get pool, fee of uniswapV3
     * @param uniswapV3Router Address of uniswapRouter
     * @param tokenA Address of TokenA
     * @param tokenB Address of TokenB
     * @return pool address of pool
     * @return fee fee, 3000, 5000, 1000, if 0, pool isn't exist
     */
    function _findUniswapV3Pool(
        address uniswapV3Router,
        address tokenA,
        address tokenB
    ) private view returns (address pool, uint24 fee) {
        uint24[] memory fees = new uint24[](3);
        fees[0] = 3000;
        fees[1] = 5000;
        fees[2] = 10000;

        for (uint8 i = 0; i < 3; ) {
            pool = IUniswapV3Factory(
                IUniswapV3Router(uniswapV3Router).factory()
            ).getPool(tokenA, tokenB, fees[i]);
            if (pool != ZERO_ADDRESS) {
                fee = fees[i];
                break;
            }
            unchecked {
                ++i;
            }
        }

        require(fee > 0, "SG2");
    }

    /**
     * @notice Get pool, fee of QuickswapV3
     * @param quickswapV3Router Address of uniswapRouter
     * @param tokenA Address of TokenA
     * @param tokenB Address of TokenB
     * @return pool address of pool, address(0) if pool isn't exist
     * @return fee fee
     */
    function _findQuickswapV3Pool(
        address quickswapV3Router,
        address tokenA,
        address tokenB
    ) private view returns (address pool, uint24 fee) {
        pool = IQuickswapV3Factory(
            IQuickswapV3Router(quickswapV3Router).factory()
        ).poolByPair(tokenA, tokenB);

        if (pool != ZERO_ADDRESS) {
            (, , uint16 fee16, , , , ) = IQuickswapV3Pool(pool).globalState();
            fee = uint24(fee16);
        } else {
            revert("SG2");
        }
    }
}

contract SwapGateway is ISwapGateway, UpgradeableBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant ZERO_ADDRESS = address(0);
    uint256 private constant BASE = 10**18;
    address private wETH;

    // 0: unregistered
    // 2: Pancakeswap/UniswapV2
    // 3: UniswapV3
    // 4: DODOV2
    // 5: QuickswapV3
    mapping(address => uint8) swapRouterVersion;

    event SetWETH(address wETH);
    event AddSwapRouter(address swapRouter, uint8 version);

    function __SwapGateway_init() public initializer {
        UpgradeableBase.initialize();
    }

    receive() external payable {}

    fallback() external payable {}

    /*** Owner function ***/

    /**
     * @notice Set wETH
     * @param _wETH Address of Wrapped ETH
     */
    function setWETH(address _wETH) external onlyOwnerAndAdmin {
        wETH = _wETH;
        emit SetWETH(_wETH);
    }

    /**
     * @notice Add SwapRouter
     * @param swapRouter Address of swapRouter
     * @param version version of swapRouter (2, 3)
     */
    function addSwapRouter(address swapRouter, uint8 version)
        external
        onlyOwnerAndAdmin
    {
        if (version > 0) {
            swapRouterVersion[swapRouter] = version;
            emit AddSwapRouter(swapRouter, version);
        }
    }

    /**
     * @notice Swap tokens using swapRouter
     * @param swapRouter Address of swapRouter contract
     * @param amountIn Amount for in
     * @param amountOut Amount for out
     * @param path swap path, path[0] is in, path[last] is out
     * @param isExactInput true : swapExactTokensForTokens, false : swapTokensForExactTokens
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable override returns (uint256[] memory amounts) {
        uint8 version = swapRouterVersion[swapRouter];
        require(version > 0, "SG4");

        // Change ZERO_ADDRESS to WETH in path
        address _wETH = wETH;
        for (uint256 i = 0; i < path.length; ) {
            if (path[i] == ZERO_ADDRESS) path[i] = _wETH;
            unchecked {
                ++i;
            }
        }

        if (version == 2) {
            if (isExactInput) {
                return
                    _swapV2ExactIn(
                        swapRouter,
                        amountIn,
                        amountOut,
                        path,
                        deadline
                    );
            } else {
                return
                    _swapV2ExactOut(
                        swapRouter,
                        amountOut,
                        amountIn,
                        path,
                        deadline
                    );
            }
        } else if (version == 3) {
            if (isExactInput) {
                return
                    _swapV3ExactIn(
                        swapRouter,
                        amountIn,
                        amountOut,
                        path,
                        deadline
                    );
            } else {
                return
                    _swapV3ExactOut(
                        swapRouter,
                        amountOut,
                        amountIn,
                        path,
                        deadline
                    );
            }
        } else if (version == 4) {
            return
                _swapDODOV2(
                    swapRouter,
                    amountIn,
                    amountOut,
                    path,
                    isExactInput,
                    deadline
                );
        } else if (version == 5) {
            if (isExactInput) {
                return
                    _swapV5ExactIn(
                        swapRouter,
                        amountIn,
                        amountOut,
                        path,
                        deadline
                    );
            } else {
                return
                    _swapV5ExactOut(
                        swapRouter,
                        amountOut,
                        amountIn,
                        path,
                        deadline
                    );
            }
        } else {
            revert("SG6");
        }
    }

    /**
     * @notice get swap out amount
     * @param swapRouter swap router address
     * @param amountIn amount of tokenIn : decimal = token.decimals;
     * @param path path of swap
     * @return amountOut amount of tokenOut : decimal = token.decimals;
     */
    function quoteExactInput(
        address swapRouter,
        uint256 amountIn,
        address[] memory path
    ) external view override returns (uint256 amountOut) {
        if (amountIn > 0) {
            uint8 version = swapRouterVersion[swapRouter];
            address _wETH = wETH;
            uint256 i;

            // Change ZERO_ADDRESS to wETH
            for (i = 0; i < path.length; ) {
                if (path[i] == ZERO_ADDRESS) path[i] = _wETH;
                unchecked {
                    ++i;
                }
            }

            if (version == 2) {
                uint256[] memory amountOutList = IPancakeRouter01(swapRouter)
                    .getAmountsOut(amountIn, path);

                amountOut = amountOutList[amountOutList.length - 1];
            } else if (version == 3) {
                amountOut = amountIn;
                for (i = 0; i < path.length - 1; ) {
                    amountOut =
                        (amountOut *
                            SwapGatewayLib.getUniswapV3Quote(
                                swapRouter,
                                path[i],
                                path[i + 1]
                            )) /
                        BASE;

                    unchecked {
                        ++i;
                    }
                }
            } else if (version == 4) {
                // path[0] : tokenIn, path[1...] array of pools
                require(path.length > 1, "SG5");

                address tokenIn = path[0];
                amountOut = amountIn;

                for (i = 1; i < path.length; ) {
                    address pool = path[i];
                    if (tokenIn == IDODOStorage(pool)._BASE_TOKEN_()) {
                        (amountOut, ) = IDODOStorage(pool).querySellBase(
                            tx.origin,
                            amountOut
                        );
                        tokenIn = IDODOStorage(pool)._QUOTE_TOKEN_();
                    } else if (tokenIn == IDODOStorage(pool)._QUOTE_TOKEN_()) {
                        (amountOut, ) = IDODOStorage(pool).querySellQuote(
                            tx.origin,
                            amountOut
                        );
                        tokenIn = IDODOStorage(pool)._BASE_TOKEN_();
                    } else {
                        revert("SG6");
                    }

                    unchecked {
                        ++i;
                    }
                }
            } else if (version == 5) {
                amountOut = amountIn;
                for (i = 0; i < path.length - 1; ) {
                    amountOut =
                        (amountOut *
                            SwapGatewayLib.getQuickswapV3Quote(
                                swapRouter,
                                path[i],
                                path[i + 1]
                            )) /
                        BASE;

                    unchecked {
                        ++i;
                    }
                }
            } else {
                revert("SG7");
            }
        }
    }

    /*** Private Function ***/

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swapRouter Address of swap router
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * address(0) will be used for wrapped ETH
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV2ExactIn(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        address _wETH = wETH;

        // swapExactETHForTokens
        if (path[0] == _wETH) {
            require(msg.value >= amountIn, "SG0");

            amounts = IPancakeRouter01(swapRouter).swapExactETHForTokens{
                value: amountIn
            }(amountOutMin, path, msg.sender, deadline);

            // If too mucn ETH has been sent, send it back to sender
            uint256 remainedToken = msg.value - amountIn;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }

            return amounts;
        }

        IERC20Upgradeable(path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        _approveTokenForSwapRouter(path[0], swapRouter, amountIn);

        // swapExactTokensForETH
        if (path[path.length - 1] == _wETH) {
            return
                IPancakeRouter01(swapRouter).swapExactTokensForETH(
                    amountIn,
                    amountOutMin,
                    path,
                    msg.sender,
                    deadline
                );
        }

        // swapExactTokensForTokens
        return
            IPancakeRouter01(swapRouter).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swapRouter Address of swap router
     * @param amountOut Payable amount of input tokens.
     * @param amountInMax The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * address(0) will be used for wrapped ETH
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV2ExactOut(
        address swapRouter,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        address _wETH = wETH;
        uint256 remainedToken;

        // swapETHForExactTokens
        if (path[0] == _wETH) {
            require(msg.value >= amountInMax, "SG0");

            amounts = IPancakeRouter01(swapRouter).swapETHForExactTokens{
                value: amountInMax
            }(amountOut, path, msg.sender, deadline);

            remainedToken = address(this).balance;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }

            return amounts;
        }

        IERC20Upgradeable(path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            amountInMax
        );
        _approveTokenForSwapRouter(path[0], swapRouter, amountInMax);

        // swapTokensForExactETH
        if (path[path.length - 1] == _wETH) {
            amounts = IPancakeRouter01(swapRouter).swapTokensForExactETH(
                amountOut,
                amountInMax,
                path,
                msg.sender,
                deadline
            );
        } else {
            // swapTokensForExactTokens
            amounts = IPancakeRouter01(swapRouter).swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                msg.sender,
                deadline
            );
        }

        remainedToken = IERC20Upgradeable(path[0]).balanceOf(address(this));
        if (remainedToken > 0) {
            IERC20Upgradeable(path[0]).safeTransfer(msg.sender, remainedToken);
        }

        return amounts;
    }

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swapRouter Address of swap router
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path path to swap
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV3ExactIn(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        amounts = new uint256[](1);
        uint256 length = path.length;
        address recipient = msg.sender;
        address _wETH = wETH;

        if (path[0] == _wETH) {
            require(msg.value >= amountIn, "SG0");
        } else {
            IERC20Upgradeable(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
            _approveTokenForSwapRouter(path[0], swapRouter, amountIn);
        }

        if (path[length - 1] == _wETH) {
            recipient = address(this);
        }

        // Single
        if (length == 2) {
            // Check pool and fee
            (, uint24 fee) = _findUniswapV3Pool(swapRouter, path[0], path[1]);

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    fee: fee,
                    recipient: recipient,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });

            if (path[0] == _wETH) {
                amounts[0] = ISwapRouter(swapRouter).exactInputSingle{
                    value: amountIn
                }(params);

                // If too much ETH has been sent, send it back to sender
                uint256 remainedToken = msg.value - amountIn;
                if (remainedToken > 0) {
                    _send(payable(msg.sender), remainedToken);
                }
            } else {
                amounts[0] = ISwapRouter(swapRouter).exactInputSingle(params);
            }
        } else {
            // Multihop
            uint24[] memory fees = new uint24[](length - 1);

            for (uint256 i = 0; i < length - 1; ) {
                // Get fee
                (, fees[i]) = _findUniswapV3Pool(
                    swapRouter,
                    path[i],
                    path[i + 1]
                );

                unchecked {
                    ++i;
                }
            }

            ISwapRouter.ExactInputParams memory params = ISwapRouter
                .ExactInputParams({
                    path: SwapGatewayLib.generateEncodedPathWithFee(path, fees),
                    recipient: recipient,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin
                });

            if (path[0] == _wETH) {
                amounts[0] = ISwapRouter(swapRouter).exactInput{
                    value: amountIn
                }(params);
            } else {
                amounts[0] = ISwapRouter(swapRouter).exactInput(params);
            }
        }

        // If too much ETH has been sent, send it back to sender
        if (path[0] == _wETH) {
            uint256 remainedToken = msg.value - amountIn;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }
        }

        // If receive ETH, unWrap it
        if (path[length - 1] == _wETH) {
            IWETH(_wETH).withdraw(
                IERC20Upgradeable(_wETH).balanceOf(address(this))
            );
            _send(payable(msg.sender), address(this).balance);
        }
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swapRouter Address of swap router
     * @param amountOut Payable amount of input tokens.
     * @param amountInMax The minimum amount tokens to input.
     * @param path path to swap
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV3ExactOut(
        address swapRouter,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        uint256 remainedToken;
        amounts = new uint256[](1);
        uint256 length = path.length;
        address recipient = msg.sender;
        address _wETH = wETH;

        if (path[0] == _wETH) {
            require(msg.value >= amountInMax, "SG0");
        } else {
            IERC20Upgradeable(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountInMax
            );
            _approveTokenForSwapRouter(path[0], swapRouter, amountInMax);
        }

        if (path[length - 1] == _wETH) {
            recipient = address(this);
        }

        // Single Swap
        if (length == 2) {
            // Check pool and fee
            (, uint24 fee) = _findUniswapV3Pool(swapRouter, path[0], path[1]);

            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    fee: fee,
                    recipient: recipient,
                    deadline: deadline,
                    amountOut: amountOut,
                    amountInMaximum: amountInMax,
                    sqrtPriceLimitX96: 0
                });

            if (path[0] == _wETH) {
                amounts[0] = ISwapRouter(swapRouter).exactOutputSingle{
                    value: amountInMax
                }(params);
            } else {
                amounts[0] = ISwapRouter(swapRouter).exactOutputSingle(params);
            }
        } else {
            // Multihop
            uint24[] memory fees = new uint24[](length - 1);

            // Get reverse path
            address[] memory reversePath = new address[](length);
            for (uint256 i = 0; i < length; ) {
                reversePath[i] = path[length - 1 - i];

                unchecked {
                    ++i;
                }
            }

            for (uint256 i = 0; i < length - 1; ) {
                // Get fee
                (, fees[i]) = _findUniswapV3Pool(
                    swapRouter,
                    reversePath[i],
                    reversePath[i + 1]
                );

                unchecked {
                    ++i;
                }
            }

            ISwapRouter.ExactOutputParams memory params = ISwapRouter
                .ExactOutputParams({
                    path: SwapGatewayLib.generateEncodedPathWithFee(
                        reversePath,
                        fees
                    ),
                    recipient: recipient,
                    deadline: deadline,
                    amountOut: amountOut,
                    amountInMaximum: amountInMax
                });

            if (path[0] == _wETH) {
                amounts[0] = ISwapRouter(swapRouter).exactOutput{
                    value: amountInMax
                }(params);
            } else {
                amounts[0] = ISwapRouter(swapRouter).exactOutput(params);
            }
        }

        // send back remained token
        if (path[0] == _wETH) {
            IUniswapV3Router(swapRouter).refundETH(); // Take back leftover ETH
            remainedToken = address(this).balance;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }
        } else {
            remainedToken = IERC20Upgradeable(path[0]).balanceOf(address(this));
            if (remainedToken > 0) {
                IERC20Upgradeable(path[0]).safeTransfer(
                    msg.sender,
                    remainedToken
                );
            }
        }

        // If receive ETH, unWrap it
        if (path[length - 1] == _wETH) {
            IWETH(_wETH).withdraw(
                IERC20Upgradeable(_wETH).balanceOf(address(this))
            );
            _send(payable(msg.sender), address(this).balance);
        }
    }

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swapRouter Address of swap router
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path path to swap
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV5ExactIn(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        amounts = new uint256[](1);
        uint256 length = path.length;
        address recipient = msg.sender;
        address _wETH = wETH;

        if (path[0] == _wETH) {
            require(msg.value >= amountIn, "SG0");
        } else {
            IERC20Upgradeable(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
            _approveTokenForSwapRouter(path[0], swapRouter, amountIn);
        }

        if (path[length - 1] == _wETH) {
            recipient = address(this);
        }

        // Single
        if (length == 2) {
            // Check pool and fee
            _findQuickswapV3Pool(swapRouter, path[0], path[1]);

            IAlgebraSwapRouter.ExactInputSingleParams
                memory params = IAlgebraSwapRouter.ExactInputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    recipient: recipient,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin,
                    limitSqrtPrice: 0
                });

            if (path[0] == _wETH) {
                amounts[0] = IAlgebraSwapRouter(swapRouter).exactInputSingle{
                    value: amountIn
                }(params);

                // If too much ETH has been sent, send it back to sender
                uint256 remainedToken = msg.value - amountIn;
                if (remainedToken > 0) {
                    _send(payable(msg.sender), remainedToken);
                }
            } else {
                amounts[0] = IAlgebraSwapRouter(swapRouter).exactInputSingle(
                    params
                );
            }
        } else {
            // Multihop
            // Check pool and fee
            for (uint256 i = 0; i < length - 1; ) {
                _findQuickswapV3Pool(swapRouter, path[i], path[i + 1]);

                unchecked {
                    ++i;
                }
            }

            IAlgebraSwapRouter.ExactInputParams
                memory params = IAlgebraSwapRouter.ExactInputParams({
                    path: SwapGatewayLib.generateEncodedPath(path),
                    recipient: recipient,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin
                });

            if (path[0] == _wETH) {
                amounts[0] = IAlgebraSwapRouter(swapRouter).exactInput{
                    value: amountIn
                }(params);
            } else {
                amounts[0] = IAlgebraSwapRouter(swapRouter).exactInput(params);
            }
        }

        // If too much ETH has been sent, send it back to sender
        if (path[0] == _wETH) {
            uint256 remainedToken = msg.value - amountIn;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }
        }

        // If receive ETH, unWrap it
        if (path[length - 1] == _wETH) {
            IWETH(_wETH).withdraw(
                IERC20Upgradeable(_wETH).balanceOf(address(this))
            );
            _send(payable(msg.sender), address(this).balance);
        }
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swapRouter Address of swap router
     * @param amountOut Payable amount of input tokens.
     * @param amountInMax The minimum amount tokens to input.
     * @param path path to swap
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV5ExactOut(
        address swapRouter,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        uint256 remainedToken;
        amounts = new uint256[](1);
        uint256 length = path.length;
        address recipient = msg.sender;
        address _wETH = wETH;

        if (path[0] == _wETH) {
            require(msg.value >= amountInMax, "SG0");
        } else {
            IERC20Upgradeable(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountInMax
            );
            _approveTokenForSwapRouter(path[0], swapRouter, amountInMax);
        }

        if (path[length - 1] == _wETH) {
            recipient = address(this);
        }

        // Single Swap
        if (length == 2) {
            // Check pool and fee
            (, uint24 fee) = _findQuickswapV3Pool(swapRouter, path[0], path[1]);

            IAlgebraSwapRouter.ExactOutputSingleParams
                memory params = IAlgebraSwapRouter.ExactOutputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    fee: fee,
                    recipient: recipient,
                    deadline: deadline,
                    amountOut: amountOut,
                    amountInMaximum: amountInMax,
                    limitSqrtPrice: 0
                });

            if (path[0] == _wETH) {
                amounts[0] = IAlgebraSwapRouter(swapRouter).exactOutputSingle{
                    value: amountInMax
                }(params);
            } else {
                amounts[0] = IAlgebraSwapRouter(swapRouter).exactOutputSingle(
                    params
                );
            }
        } else {
            // Multihop

            // Get reverse path
            address[] memory reversePath = new address[](length);
            for (uint256 i = 0; i < length; ) {
                reversePath[i] = path[length - 1 - i];

                unchecked {
                    ++i;
                }
            }

            // Check pool, fee
            for (uint256 i = 0; i < length - 1; ) {
                _findQuickswapV3Pool(
                    swapRouter,
                    reversePath[i],
                    reversePath[i + 1]
                );

                unchecked {
                    ++i;
                }
            }

            IAlgebraSwapRouter.ExactOutputParams
                memory params = IAlgebraSwapRouter.ExactOutputParams({
                    path: SwapGatewayLib.generateEncodedPath(reversePath),
                    recipient: recipient,
                    deadline: deadline,
                    amountOut: amountOut,
                    amountInMaximum: amountInMax
                });

            if (path[0] == _wETH) {
                amounts[0] = IAlgebraSwapRouter(swapRouter).exactOutput{
                    value: amountInMax
                }(params);
            } else {
                amounts[0] = IAlgebraSwapRouter(swapRouter).exactOutput(params);
            }
        }

        // send back remained token
        if (path[0] == _wETH) {
            IQuickswapV3Router(swapRouter).refundNativeToken(); // Take back leftover ETH
            remainedToken = address(this).balance;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }
        } else {
            remainedToken = IERC20Upgradeable(path[0]).balanceOf(address(this));
            if (remainedToken > 0) {
                IERC20Upgradeable(path[0]).safeTransfer(
                    msg.sender,
                    remainedToken
                );
            }
        }

        // If receive ETH, unWrap it
        if (path[length - 1] == _wETH) {
            IWETH(_wETH).withdraw(
                IERC20Upgradeable(_wETH).balanceOf(address(this))
            );
            _send(payable(msg.sender), address(this).balance);
        }
    }

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swapRouter Address of swap router
     * @param amountIn Amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path path to swap path[0] : tokenIn, tokenOut, path[2...] pool, path[last] : tokenOut
     * @param isIncentive true : it is incentive
     * @param deadline Unix timestamp deadline
     */
    function _swapDODOV2(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        bool isIncentive,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        uint256 remainedToken;
        address _wETH = wETH;
        uint256 length = path.length;

        require(length > 2, "SG5");
        amounts = new uint256[](1);

        // Get pairs, directions
        address[] memory dodoPairs = new address[](length - 2);
        uint256 directions = 0;
        {
            address tokenIn = path[0];
            uint256 i;

            for (i = 0; i < length - 2; ) {
                dodoPairs[i] = path[i + 1];

                if (IDODOStorage(path[i + 1])._BASE_TOKEN_() == tokenIn) {
                    directions = directions + (0 << i);
                    tokenIn = IDODOStorage(path[i + 1])._QUOTE_TOKEN_();
                } else {
                    directions = directions + (1 << i);
                    tokenIn = IDODOStorage(path[i + 1])._BASE_TOKEN_();
                }

                unchecked {
                    ++i;
                }
            }
        }

        if (path[0] == _wETH) {
            require(msg.value >= amountIn, "SG0");
        } else {
            IERC20Upgradeable(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );

            // Approve to DODO_APPROVE
            _approveTokenForSwapRouter(
                path[0],
                IDODOApproveProxy(
                    IDODOV2Proxy02(swapRouter)._DODO_APPROVE_PROXY_()
                )._DODO_APPROVE_(),
                amountIn
            );
        }

        if (path[0] == _wETH) {
            amounts[0] = IDODOV2Proxy02(swapRouter).dodoSwapV2ETHToToken{
                value: amountIn
            }(
                path[length - 1],
                amountOutMin,
                dodoPairs,
                directions,
                isIncentive,
                deadline
            );

            IERC20Upgradeable(path[length - 1]).safeTransfer(
                msg.sender,
                amounts[0]
            );
        } else if (path[length - 1] == _wETH) {
            amounts[0] = IDODOV2Proxy02(swapRouter).dodoSwapV2TokenToETH(
                path[0],
                amountIn,
                amountOutMin,
                dodoPairs,
                directions,
                isIncentive,
                deadline
            );

            _send(payable(msg.sender), amounts[0]);
        } else {
            amounts[0] = IDODOV2Proxy02(swapRouter).dodoSwapV2TokenToToken(
                path[0],
                path[length - 1],
                amountIn,
                amountOutMin,
                dodoPairs,
                directions,
                isIncentive,
                deadline
            );

            IERC20Upgradeable(path[length - 1]).safeTransfer(
                msg.sender,
                amounts[0]
            );
        }

        // send back remained token
        if (path[0] == _wETH) {
            remainedToken = address(this).balance;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }
        } else {
            remainedToken = IERC20Upgradeable(path[0]).balanceOf(address(this));
            if (remainedToken > 0) {
                IERC20Upgradeable(path[0]).safeTransfer(
                    msg.sender,
                    remainedToken
                );
            }
        }
    }

    /**
     * @notice Get pool, fee of uniswapV3
     * @param uniswapV3Router Address of uniswapRouter
     * @param tokenA Address of TokenA
     * @param tokenB Address of TokenB
     * @return pool address of pool
     * @return fee fee, 3000, 5000, 1000, if 0, pool isn't exist
     */
    function _findUniswapV3Pool(
        address uniswapV3Router,
        address tokenA,
        address tokenB
    ) private view returns (address pool, uint24 fee) {
        uint24[] memory fees = new uint24[](3);
        fees[0] = 3000;
        fees[1] = 5000;
        fees[2] = 10000;

        for (uint8 i = 0; i < 3; ) {
            pool = IUniswapV3Factory(
                IUniswapV3Router(uniswapV3Router).factory()
            ).getPool(tokenA, tokenB, fees[i]);
            if (pool != ZERO_ADDRESS) {
                fee = fees[i];
                break;
            }
            unchecked {
                ++i;
            }
        }

        require(fee > 0, "SG2");
    }

    /**
     * @notice Get pool, fee of QuickswapV3
     * @param quickswapV3Router Address of uniswapRouter
     * @param tokenA Address of TokenA
     * @param tokenB Address of TokenB
     * @return pool address of pool, address(0) if pool isn't exist
     * @return fee fee
     */
    function _findQuickswapV3Pool(
        address quickswapV3Router,
        address tokenA,
        address tokenB
    ) private view returns (address pool, uint24 fee) {
        pool = IQuickswapV3Factory(
            IQuickswapV3Router(quickswapV3Router).factory()
        ).poolByPair(tokenA, tokenB);

        if (pool != ZERO_ADDRESS) {
            (, , uint16 fee16, , , , ) = IQuickswapV3Pool(pool).globalState();
            fee = uint24(fee16);
        } else {
            revert("SG2");
        }
    }

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "SG1");
    }

    function _approveTokenForSwapRouter(
        address token,
        address swapRouter,
        uint256 amount
    ) private {
        uint256 allowance = IERC20Upgradeable(token).allowance(
            address(this),
            swapRouter
        );

        if (allowance == 0) {
            IERC20Upgradeable(token).safeApprove(swapRouter, amount);
            return;
        }

        if (allowance < amount) {
            IERC20Upgradeable(token).safeIncreaseAllowance(
                swapRouter,
                amount - allowance
            );
        }
    }
}

contract SwapGatewayOld is ISwapGateway, UpgradeableBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant ZERO_ADDRESS = address(0);
    uint256 private constant BASE = 10**18;
    address private wETH;
    // 0: unregistered, 2: Pancakeswap/UniswapV2, 3: UniswapV3, 4: DODOV2
    mapping(address => uint8) swapRouterVersion;

    event SetWETH(address wETH);
    event AddSwapRouter(address swapRouter, uint8 version);

    function __SwapGateway_init() public initializer {
        UpgradeableBase.initialize();
    }

    receive() external payable {}

    fallback() external payable {}

    /*** Owner function ***/

    /**
     * @notice Set wETH
     * @param _wETH Address of Wrapped ETH
     */
    function setWETH(address _wETH) external onlyOwnerAndAdmin {
        wETH = _wETH;
        emit SetWETH(_wETH);
    }

    /**
     * @notice Add SwapRouter
     * @param swapRouter Address of swapRouter
     * @param version version of swapRouter (2, 3)
     */
    function addSwapRouter(address swapRouter, uint8 version)
        external
        onlyOwnerAndAdmin
    {
        if (version > 0) {
            swapRouterVersion[swapRouter] = version;
            emit AddSwapRouter(swapRouter, version);
        }
    }

    /**
     * @notice Swap tokens using swapRouter
     * @param swapRouter Address of swapRouter contract
     * @param amountIn Amount for in
     * @param amountOut Amount for out
     * @param path swap path, path[0] is in, path[last] is out
     * @param isExactInput true : swapExactTokensForTokens, false : swapTokensForExactTokens
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable override returns (uint256[] memory amounts) {
        uint8 version = swapRouterVersion[swapRouter];
        require(version > 0, "SG4");

        // Change ZERO_ADDRESS to WETH in path
        address _wETH = wETH;
        for (uint256 i = 0; i < path.length; ) {
            if (path[i] == ZERO_ADDRESS) path[i] = _wETH;
            unchecked {
                ++i;
            }
        }

        if (version == 2) {
            if (isExactInput) {
                return
                    _swapV2ExactIn(
                        swapRouter,
                        amountIn,
                        amountOut,
                        path,
                        deadline
                    );
            } else {
                return
                    _swapV2ExactOut(
                        swapRouter,
                        amountOut,
                        amountIn,
                        path,
                        deadline
                    );
            }
        } else if (version == 3) {
            if (isExactInput) {
                return
                    _swapV3ExactIn(
                        swapRouter,
                        amountIn,
                        amountOut,
                        path,
                        deadline
                    );
            } else {
                return
                    _swapV3ExactOut(
                        swapRouter,
                        amountOut,
                        amountIn,
                        path,
                        deadline
                    );
            }
        } else if (version == 4) {
            return
                _swapDODOV2(
                    swapRouter,
                    amountIn,
                    amountOut,
                    path,
                    isExactInput,
                    deadline
                );
        } else {
            revert("SG6");
        }
    }

    /**
     * @notice get swap out amount
     * @param swapRouter swap router address
     * @param amountIn amount of tokenIn : decimal = token.decimals;
     * @param path path of swap
     * @return amountOut amount of tokenOut : decimal = token.decimals;
     */
    function quoteExactInput(
        address swapRouter,
        uint256 amountIn,
        address[] memory path
    ) external view override returns (uint256 amountOut) {
        if (amountIn > 0) {
            uint8 version = swapRouterVersion[swapRouter];
            address _wETH = wETH;
            uint256 i;

            // Change ZERO_ADDRESS to wETH
            for (i = 0; i < path.length; ) {
                if (path[i] == ZERO_ADDRESS) path[i] = _wETH;
                unchecked {
                    ++i;
                }
            }

            if (version == 2) {
                uint256[] memory amountOutList = IPancakeRouter01(swapRouter)
                    .getAmountsOut(amountIn, path);

                amountOut = amountOutList[amountOutList.length - 1];
            } else if (version == 3) {
                amountOut = amountIn;
                for (i = 0; i < path.length - 1; ) {
                    amountOut =
                        (amountOut *
                            _getQuoteV3(swapRouter, path[i], path[i + 1])) /
                        BASE;

                    unchecked {
                        ++i;
                    }
                }
            } else if (version == 4) {
                // path[0] : tokenIn, path[1...] array of pools
                require(path.length > 1, "SG5");

                address tokenIn = path[0];
                amountOut = amountIn;

                for (i = 1; i < path.length; ) {
                    address pool = path[i];
                    if (tokenIn == IDODOStorage(pool)._BASE_TOKEN_()) {
                        (amountOut, ) = IDODOStorage(pool).querySellBase(
                            tx.origin,
                            amountOut
                        );
                        tokenIn = IDODOStorage(pool)._QUOTE_TOKEN_();
                    } else if (tokenIn == IDODOStorage(pool)._QUOTE_TOKEN_()) {
                        (amountOut, ) = IDODOStorage(pool).querySellQuote(
                            tx.origin,
                            amountOut
                        );
                        tokenIn = IDODOStorage(pool)._BASE_TOKEN_();
                    } else {
                        revert("SG6");
                    }

                    unchecked {
                        ++i;
                    }
                }
            } else {
                revert("SG7");
            }
        }
    }

    /*** Private Function ***/

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swapRouter Address of swap router
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * address(0) will be used for wrapped ETH
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV2ExactIn(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        address _wETH = wETH;

        // swapExactETHForTokens
        if (path[0] == _wETH) {
            require(msg.value >= amountIn, "SG0");

            amounts = IPancakeRouter01(swapRouter).swapExactETHForTokens{
                value: amountIn
            }(amountOutMin, path, msg.sender, deadline);

            // If too mucn ETH has been sent, send it back to sender
            uint256 remainedToken = msg.value - amountIn;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }

            return amounts;
        }

        IERC20Upgradeable(path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        _approveTokenForSwapRouter(path[0], swapRouter, amountIn);

        // swapExactTokensForETH
        if (path[path.length - 1] == _wETH) {
            return
                IPancakeRouter01(swapRouter).swapExactTokensForETH(
                    amountIn,
                    amountOutMin,
                    path,
                    msg.sender,
                    deadline
                );
        }

        // swapExactTokensForTokens
        return
            IPancakeRouter01(swapRouter).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swapRouter Address of swap router
     * @param amountOut Payable amount of input tokens.
     * @param amountInMax The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * address(0) will be used for wrapped ETH
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV2ExactOut(
        address swapRouter,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        address _wETH = wETH;
        uint256 remainedToken;

        // swapETHForExactTokens
        if (path[0] == _wETH) {
            require(msg.value >= amountInMax, "SG0");

            amounts = IPancakeRouter01(swapRouter).swapETHForExactTokens{
                value: amountInMax
            }(amountOut, path, msg.sender, deadline);

            remainedToken = address(this).balance;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }

            return amounts;
        }

        IERC20Upgradeable(path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            amountInMax
        );
        _approveTokenForSwapRouter(path[0], swapRouter, amountInMax);

        // swapTokensForExactETH
        if (path[path.length - 1] == _wETH) {
            amounts = IPancakeRouter01(swapRouter).swapTokensForExactETH(
                amountOut,
                amountInMax,
                path,
                msg.sender,
                deadline
            );
        } else {
            // swapTokensForExactTokens
            amounts = IPancakeRouter01(swapRouter).swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                msg.sender,
                deadline
            );
        }

        remainedToken = IERC20Upgradeable(path[0]).balanceOf(address(this));
        if (remainedToken > 0) {
            IERC20Upgradeable(path[0]).safeTransfer(msg.sender, remainedToken);
        }

        return amounts;
    }

    /*** UniswapV3 function ***/

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swapRouter Address of swap router
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path path to swap
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV3ExactIn(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        amounts = new uint256[](1);
        uint256 length = path.length;
        address recipient = msg.sender;
        address _wETH = wETH;

        if (path[0] == _wETH) {
            require(msg.value >= amountIn, "SG0");
        } else {
            IERC20Upgradeable(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
            _approveTokenForSwapRouter(path[0], swapRouter, amountIn);
        }

        if (path[length - 1] == _wETH) {
            recipient = address(this);
        }

        // Single
        if (length == 2) {
            // Check pool and fee
            (, uint24 fee) = _findUniswapV3Pool(swapRouter, path[0], path[1]);
            require(fee > 0, "SG2");

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    fee: fee,
                    recipient: recipient,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });

            if (path[0] == _wETH) {
                amounts[0] = ISwapRouter(swapRouter).exactInputSingle{
                    value: amountIn
                }(params);

                // If too much ETH has been sent, send it back to sender
                uint256 remainedToken = msg.value - amountIn;
                if (remainedToken > 0) {
                    _send(payable(msg.sender), remainedToken);
                }
            } else {
                amounts[0] = ISwapRouter(swapRouter).exactInputSingle(params);
            }
        } else {
            // Multihop
            uint24[] memory fees = new uint24[](length - 1);

            for (uint256 i = 0; i < length - 1; ) {
                // Get fee
                (, fees[i]) = _findUniswapV3Pool(
                    swapRouter,
                    path[i],
                    path[i + 1]
                );
                require(fees[i] > 0, "SG2");

                unchecked {
                    ++i;
                }
            }

            ISwapRouter.ExactInputParams memory params = ISwapRouter
                .ExactInputParams({
                    path: _generateEncodedPath(path, fees),
                    recipient: recipient,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin
                });

            if (path[0] == _wETH) {
                amounts[0] = ISwapRouter(swapRouter).exactInput{
                    value: amountIn
                }(params);
            } else {
                amounts[0] = ISwapRouter(swapRouter).exactInput(params);
            }
        }

        // If too much ETH has been sent, send it back to sender
        if (path[0] == _wETH) {
            uint256 remainedToken = msg.value - amountIn;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }
        }

        // If receive ETH, unWrap it
        if (path[length - 1] == _wETH) {
            IWETH(_wETH).withdraw(
                IERC20Upgradeable(_wETH).balanceOf(address(this))
            );
            _send(payable(msg.sender), address(this).balance);
        }
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swapRouter Address of swap router
     * @param amountOut Payable amount of input tokens.
     * @param amountInMax The minimum amount tokens to input.
     * @param path path to swap
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function _swapV3ExactOut(
        address swapRouter,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        uint256 remainedToken;
        amounts = new uint256[](1);
        uint256 length = path.length;
        address recipient = msg.sender;
        address _wETH = wETH;

        if (path[0] == _wETH) {
            require(msg.value >= amountInMax, "SG0");
        } else {
            IERC20Upgradeable(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountInMax
            );
            _approveTokenForSwapRouter(path[0], swapRouter, amountInMax);
        }

        if (path[length - 1] == _wETH) {
            recipient = address(this);
        }

        // Single Swap
        if (length == 2) {
            // Check pool and fee
            (, uint24 fee) = _findUniswapV3Pool(swapRouter, path[0], path[1]);
            require(fee > 0, "SG2");

            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    fee: fee,
                    recipient: recipient,
                    deadline: deadline,
                    amountOut: amountOut,
                    amountInMaximum: amountInMax,
                    sqrtPriceLimitX96: 0
                });

            if (path[0] == _wETH) {
                amounts[0] = ISwapRouter(swapRouter).exactOutputSingle{
                    value: amountInMax
                }(params);
            } else {
                amounts[0] = ISwapRouter(swapRouter).exactOutputSingle(params);
            }
        } else {
            // Multihop
            uint24[] memory fees = new uint24[](length - 1);

            // Get reverse path
            address[] memory reversePath = new address[](length);
            for (uint256 i = 0; i < length; ) {
                reversePath[i] = path[length - 1 - i];

                unchecked {
                    ++i;
                }
            }

            for (uint256 i = 0; i < length - 1; ) {
                // Get fee
                (, fees[i]) = _findUniswapV3Pool(
                    swapRouter,
                    reversePath[i],
                    reversePath[i + 1]
                );
                require(fees[i] > 0, "SG2");

                unchecked {
                    ++i;
                }
            }

            ISwapRouter.ExactOutputParams memory params = ISwapRouter
                .ExactOutputParams({
                    path: _generateEncodedPath(reversePath, fees),
                    recipient: recipient,
                    deadline: deadline,
                    amountOut: amountOut,
                    amountInMaximum: amountInMax
                });

            if (path[0] == _wETH) {
                amounts[0] = ISwapRouter(swapRouter).exactOutput{
                    value: amountInMax
                }(params);
            } else {
                amounts[0] = ISwapRouter(swapRouter).exactOutput(params);
            }
        }

        // send back remained token
        if (path[0] == _wETH) {
            IUniswapV3Router(swapRouter).refundETH(); // Take back leftover ETH
            remainedToken = address(this).balance;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }
        } else {
            remainedToken = IERC20Upgradeable(path[0]).balanceOf(address(this));
            if (remainedToken > 0) {
                IERC20Upgradeable(path[0]).safeTransfer(
                    msg.sender,
                    remainedToken
                );
            }
        }

        // If receive ETH, unWrap it
        if (path[length - 1] == _wETH) {
            IWETH(_wETH).withdraw(
                IERC20Upgradeable(_wETH).balanceOf(address(this))
            );
            _send(payable(msg.sender), address(this).balance);
        }
    }

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swapRouter Address of swap router
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path path to swap path[0] : tokenIn, path[1]: tokenOut, path[2...] pool
     * @param isIncentive true : it is incentive
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     * deadline / 10**18 = directions
     */
    function _swapDODOV2(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        bool isIncentive,
        uint256 deadline
    ) private returns (uint256[] memory amounts) {
        uint256 remainedToken;
        address _wETH = wETH;
        uint256 length = path.length;

        require(length > 2, "SG5");
        amounts = new uint256[](1);

        address[] memory dodoPairs = new address[](length - 2);
        uint256 directions = deadline / BASE;
        deadline = deadline % BASE;

        for (uint256 i = 0; i < length - 2; ) {
            dodoPairs[i] = path[i + 2];
            unchecked {
                ++i;
            }
        }

        if (path[0] == _wETH) {
            require(msg.value >= amountIn, "SG0");
        } else {
            IERC20Upgradeable(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );

            // Approve to DODO_APPROVE
            _approveTokenForSwapRouter(
                path[0],
                IDODOApproveProxy(
                    IDODOV2Proxy02(swapRouter)._DODO_APPROVE_PROXY_()
                )._DODO_APPROVE_(),
                amountIn
            );
        }

        if (path[0] == _wETH) {
            amounts[0] = IDODOV2Proxy02(swapRouter).dodoSwapV2ETHToToken{
                value: amountIn
            }(
                path[1],
                amountOutMin,
                dodoPairs,
                directions,
                isIncentive,
                deadline
            );

            IERC20Upgradeable(path[1]).safeTransfer(msg.sender, amounts[0]);
        } else if (path[1] == _wETH) {
            amounts[0] = IDODOV2Proxy02(swapRouter).dodoSwapV2TokenToETH(
                path[0],
                amountIn,
                amountOutMin,
                dodoPairs,
                directions,
                isIncentive,
                deadline
            );

            _send(payable(msg.sender), amounts[0]);
        } else {
            amounts[0] = IDODOV2Proxy02(swapRouter).dodoSwapV2TokenToToken(
                path[0],
                path[1],
                amountIn,
                amountOutMin,
                dodoPairs,
                directions,
                isIncentive,
                deadline
            );

            IERC20Upgradeable(path[1]).safeTransfer(msg.sender, amounts[0]);
        }

        // send back remained token
        if (path[0] == _wETH) {
            remainedToken = address(this).balance;
            if (remainedToken > 0) {
                _send(payable(msg.sender), remainedToken);
            }
        } else {
            remainedToken = IERC20Upgradeable(path[0]).balanceOf(address(this));
            if (remainedToken > 0) {
                IERC20Upgradeable(path[0]).safeTransfer(
                    msg.sender,
                    remainedToken
                );
            }
        }
    }

    /**
     * @notice get V3 amount out for 1 decimal
     * if token 1 = wBNB (deciaml = 18, price = 331USD), token 2 = USDC(decmail = 6), amountOut = 331000000
     * @param swapRouter swap router address
     * @param tokenIn Address of token input
     * @param tokenOut Address of token output
     * @return amountOut amount of tokenOut : decimal = tokenOut.decimals + 18 - tokenIn.decimals;
     */
    function _getQuoteV3(
        address swapRouter,
        address tokenIn,
        address tokenOut
    ) private view returns (uint256 amountOut) {
        // Find Pool
        (address uniswapV3Pool, ) = _findUniswapV3Pool(
            swapRouter,
            tokenIn,
            tokenOut
        );

        // Calulate Quote
        Slot0 memory slot0 = IUniswapV3Pool(uniswapV3Pool).slot0();

        if (tokenIn == IUniswapV3Pool(uniswapV3Pool).token0()) {
            if (slot0.sqrtPriceX96 > 10**29) {
                amountOut = ((slot0.sqrtPriceX96 * 10**9) / 2**96)**2;
            } else {
                amountOut = (uint256(slot0.sqrtPriceX96)**2 * BASE) / (2**192);
            }
        } else {
            if (slot0.sqrtPriceX96 > 10**35) {
                amountOut = ((2**96 * 10**9) / (slot0.sqrtPriceX96))**2;
            } else {
                amountOut = (2**192 * BASE) / (uint256(slot0.sqrtPriceX96)**2);
            }
        }
    }

    /**
     * @notice get V4 amount out for 1 decimal
     * if token 1 = wBNB (deciaml = 18, price = 331USD), token 2 = USDC(decmail = 6), amountOut = 331000000
     * @param swapRouter swap router address
     * @param path path[0]: tokenIn, path[1]: tokenOut, path[2...] pairs of pool
     * @param amountIn amount of tokenIn
     * @return amountOut amount of tokenOut : decimal = tokenOut.decimals + 18 - tokenIn.decimals;
     */
    function _getQuoteV4(
        address swapRouter,
        address[] calldata path,
        uint256 amountIn
    ) private view returns (uint256 amountOut) {}

    /**
     * @notice Get pool, fee of uniswapV2
     * @param uniswapV3Router Address of uniswapRouter
     * @param tokenA Address of TokenA
     * @param tokenB Address of TokenB
     * @return pool address of pool
     * @return fee fee, 3000, 5000, 1000, if 0, pool isn't exist
     */
    function _findUniswapV3Pool(
        address uniswapV3Router,
        address tokenA,
        address tokenB
    ) private view returns (address pool, uint24 fee) {
        uint24[] memory fees = new uint24[](3);
        fees[0] = 3000;
        fees[1] = 5000;
        fees[2] = 10000;

        for (uint8 i = 0; i < 3; ) {
            pool = IUniswapV3Factory(
                IUniswapV3Router(uniswapV3Router).factory()
            ).getPool(tokenA, tokenB, fees[i]);
            if (pool != ZERO_ADDRESS) {
                fee = fees[i];
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "SG1");
    }

    /**
     * @notice Generate abi.encodePacked path for multihop swap
     * @param tokens list of tokens
     * @param fees list of pool fees
     */
    function _generateEncodedPath(address[] memory tokens, uint24[] memory fees)
        public
        pure
        returns (bytes memory)
    {
        require(tokens.length == fees.length + 1, "SG3");

        bytes memory path = new bytes(0);

        for (uint256 i = 0; i < fees.length; i++) {
            path = abi.encodePacked(path, tokens[i], fees[i]);
        }

        path = abi.encodePacked(path, tokens[tokens.length - 1]);

        return path;
    }

    function _approveTokenForSwapRouter(
        address token,
        address swapRouter,
        uint256 amount
    ) private {
        uint256 allowance = IERC20Upgradeable(token).allowance(
            address(this),
            swapRouter
        );

        if (allowance == 0) {
            IERC20Upgradeable(token).safeApprove(swapRouter, amount);
            return;
        }

        if (allowance < amount) {
            IERC20Upgradeable(token).safeIncreaseAllowance(
                swapRouter,
                amount - allowance
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./OwnableUpgradeableVersionable.sol";
import "./OwnableUpgradeableAdminable.sol";

abstract contract UpgradeableBase is
    Initializable,
    OwnableUpgradeableVersionable,
    OwnableUpgradeableAdminable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    function initialize() public onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

interface IPancakeRouter01 {
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IMasterChef {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function userInfo(uint256 _pid, address account)
        external
        view
        returns (uint256, uint256);
}

interface IMasterChefPancakeswap is IMasterChef {
    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function CAKE() external view returns (address);
}

interface IMasterChefApeswap is IMasterChef {
    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function cake() external view returns (address);
}

interface IMasterChefBiswap is IMasterChef {
    function pendingBSW(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function BSW() external view returns (address);
}

interface ISwapGateway {
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quoteExactInput(
        address swapRouter,
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IUniswapV3Router {
    function factory() external view returns (address);

    function refundETH() external payable;
}

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the most-recently updated index of the observations array
    uint16 observationIndex;
    // the current maximum number of observations that are being stored
    uint16 observationCardinality;
    // the next maximum number of observations to store, triggered in observations.write
    uint16 observationCardinalityNext;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
    // whether the pool is locked
    bool unlocked;
}

interface IUniswapV3Pool {
    function slot0() external view returns (Slot0 memory);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IDODOV2Proxy02 {
    function _DODO_APPROVE_PROXY_() external returns (address);

    function dodoSwapV2ETHToToken(
        address toToken,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function dodoSwapV2TokenToETH(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);
}

interface IDODOApproveProxy {
    function _DODO_APPROVE_() external returns (address);
}

interface IDODOStorage {
    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function querySellBase(address trader, uint256 payBaseAmount)
        external
        view
        returns (uint256 receiveQuoteAmount, uint256 mtFee);

    function querySellQuote(address trader, uint256 payQuoteAmount)
        external
        view
        returns (uint256 receiveBaseAmount, uint256 mtFee);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IAlgebraSwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

interface IQuickswapV3Router {
    function factory() external view returns (address);

    function refundNativeToken() external payable;
}

interface IQuickswapV3Factory {
    function poolByPair(address tokenA, address tokenB)
        external
        view
        returns (address pool);
}

interface IQuickswapV3Pool {
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            uint16 fee,
            uint16 timepointIndex,
            uint8 communityFeeToken0,
            uint8 communityFeeToken1,
            bool unlocked
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableVersionable is OwnableUpgradeable {
    string private _version;
    string private _purpose;

    event UpgradeVersion(string version, string purpose);

    function getVersion() external view returns (string memory) {
        return _version;
    }

    function getPurpose() external view returns (string memory) {
        return _purpose;
    }

    /**
     * @notice Set version and purpose
     * @param version Version string, ex : 1.2.0
     * @param purpose Purpose string
     */
    function upgradeVersion(string memory version, string memory purpose)
        external
        onlyOwner
    {
        require(bytes(version).length != 0, "OV1");

        _version = version;
        _purpose = purpose;

        emit UpgradeVersion(version, purpose);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableAdminable is OwnableUpgradeable {
    address private _admin;

    event SetAdmin(address admin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "OA1");
        _;
    }

    modifier onlyOwnerAndAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "OA2");
        _;
    }

    /**
     * @notice Set admin
     * @param newAdmin Addres of new admin
     */
    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
        emit SetAdmin(newAdmin);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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