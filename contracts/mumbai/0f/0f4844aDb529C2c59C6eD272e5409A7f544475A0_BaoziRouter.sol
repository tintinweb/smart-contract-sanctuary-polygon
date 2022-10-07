pragma solidity >=0.8.0;

import './IBaoziRouter02.sol';
import './IWTRX.sol';
import './ITRC20.sol';
import './IBaoziFactory.sol';
import './IBaoziTRC20.sol';

import './BaoziLibrary.sol';
import './SafeMath.sol';
import './TransferHelper.sol';

contract BaoziRouter is IBaoziRouter02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WTRX;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BaoziRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WTRX) {
        factory = _factory;
        WTRX = _WTRX;
    }

    receive() external payable { // TODO ASSERT
        require(msg.sender == WTRX); // only accept TRX via fallback from the WTRX contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) { // TODO ASSERT
        // create the pair if it doesn't exist yet
        if (IBaoziFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IBaoziFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = BaoziLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = BaoziLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'BaoziRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = BaoziLibrary.quote(amountBDesired, reserveB, reserveA);
                require(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'BaoziRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = IBaoziFactory(factory).getPair(tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IBaoziPair(pair).mint(to);
    }
    function addLiquidityTRX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountTRX, uint liquidity) { // TODO WTRX
        (amountToken, amountTRX) = _addLiquidity(
            token,
            WTRX,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountTRXMin
        );
        address pair = IBaoziFactory(factory).getPair(token, WTRX);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWTRX(WTRX).deposit{value: amountTRX}();
        require(IWTRX(WTRX).transfer(pair, amountTRX));
        liquidity = IBaoziPair(pair).mint(to);
        // refund dust eth, if any
        unchecked {
            if (msg.value > amountTRX) TransferHelper.safeTransferTRX(msg.sender, msg.value - amountTRX);
        }
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = IBaoziFactory(factory).getPair(tokenA, tokenB);
        require(IBaoziTRC20(pair).transferFrom(msg.sender, pair, liquidity)); // send liquidity to pair
        (uint amount0, uint amount1) = IBaoziPair(pair).burn(to);
        (address token0,) = BaoziLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'BaoziRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'BaoziRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityTRX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountTRX) {
        (amountToken, amountTRX) = removeLiquidity(
            token,
            WTRX,
            liquidity,
            amountTokenMin,
            amountTRXMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWTRX(WTRX).withdraw(amountTRX);
        TransferHelper.safeTransferTRX(to, amountTRX);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = IBaoziFactory(factory).getPair(tokenA, tokenB);
        uint value = approveMax ? type(uint256).max : liquidity;
        IBaoziTRC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityTRXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountTRX) {
        address pair = IBaoziFactory(factory).getPair(token, WTRX);
        uint value = approveMax ? type(uint256).max : liquidity;
        IBaoziTRC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountTRX) = removeLiquidityTRX(token, liquidity, amountTokenMin, amountTRXMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityTRXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountTRX) {
        (, amountTRX) = removeLiquidity(
            token,
            WTRX,
            liquidity,
            amountTokenMin,
            amountTRXMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, ITRC20(token).balanceOf(address(this)));
        IWTRX(WTRX).withdraw(amountTRX);
        TransferHelper.safeTransferTRX(to, amountTRX);
    }
    function removeLiquidityTRXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountTRX) {
        address pair = IBaoziFactory(factory).getPair(token, WTRX);
        uint value = approveMax ? type(uint256).max : liquidity;
        IBaoziTRC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountTRX = removeLiquidityTRXSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountTRXMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        unchecked {
            for (uint256 i; i < path.length - 1; i++) { // TODO PATH LENGTH
                (address input, address output) = (path[i], path[i + 1]);
                (address token0,) = BaoziLibrary.sortTokens(input, output);
                uint amountOut = amounts[i + 1];
                (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
                address to = i < path.length - 2 ? BaoziLibrary.pairFor(factory, output, path[i + 2]) : _to;
                IBaoziPair(BaoziLibrary.pairFor(factory, input, output)).swap(
                    amount0Out, amount1Out, to, ''
                );
            }
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = BaoziLibrary.getAmountsOut(factory, amountIn, path);
        unchecked {
            require(amounts[amounts.length - 1] >= amountOutMin, 'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        }
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = BaoziLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'BaoziRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactTRXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WTRX, 'BaoziRouter: INVALID_PATH');
        amounts = BaoziLibrary.getAmountsOut(factory, msg.value, path);
        unchecked {
            require(amounts[amounts.length - 1] >= amountOutMin, 'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        }
        IWTRX(WTRX).deposit{value: amounts[0]}();
        require(IWTRX(WTRX).transfer(BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactTRX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        unchecked {
            require(path[path.length - 1] == WTRX, 'BaoziRouter: INVALID_PATH');
            amounts = BaoziLibrary.getAmountsIn(factory, amountOut, path);
            require(amounts[0] <= amountInMax, 'BaoziRouter: EXCESSIVE_INPUT_AMOUNT');
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]
            );
            _swap(amounts, path, address(this));
            IWTRX(WTRX).withdraw(amounts[amounts.length - 1]);
            TransferHelper.safeTransferTRX(to, amounts[amounts.length - 1]);
        }
    }
    function swapExactTokensForTRX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        unchecked {
            require(path[path.length - 1] == WTRX, 'BaoziRouter: INVALID_PATH');
            amounts = BaoziLibrary.getAmountsOut(factory, amountIn, path);
            require(amounts[amounts.length - 1] >= amountOutMin, 'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT');
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]
            );
            _swap(amounts, path, address(this));
            IWTRX(WTRX).withdraw(amounts[amounts.length - 1]);
            TransferHelper.safeTransferTRX(to, amounts[amounts.length - 1]);
        }
    }
    function swapTRXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WTRX, 'BaoziRouter: INVALID_PATH');
        amounts = BaoziLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'BaoziRouter: EXCESSIVE_INPUT_AMOUNT');
        IWTRX(WTRX).deposit{value: amounts[0]}();
        require(IWTRX(WTRX).transfer(BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        unchecked {
            if (msg.value > amounts[0]) TransferHelper.safeTransferTRX(msg.sender, msg.value - amounts[0]);
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = BaoziLibrary.sortTokens(input, output);
            IBaoziPair pair = IBaoziPair(BaoziLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = ITRC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = BaoziLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? BaoziLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = ITRC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ITRC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTRXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WTRX, 'BaoziRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWTRX(WTRX).deposit{value: amountIn}();
        require(IWTRX(WTRX).transfer(BaoziLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = ITRC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ITRC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForTRXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WTRX, 'BaoziRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = ITRC20(WTRX).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWTRX(WTRX).withdraw(amountOut);
        TransferHelper.safeTransferTRX(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual override returns (uint amountB) {
        return BaoziLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return BaoziLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return BaoziLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return BaoziLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return BaoziLibrary.getAmountsIn(factory, amountOut, path);
    }
}