pragma solidity >=0.6.6;

import "./UniswapV2Library.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";

contract SushiSwapFlashSwap {
    using SafeERC20 for IERC20;

    address private trade1Token;
    address private trade2Token;
    address private trade3Token;
    address private trade1Router;
    address private trade1Factory;

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    function placeTrade(
        address _fromToken,
        address _toToken,
        address _router,
        address _factory,
        uint256 _amountIn
    ) private returns (uint256) {

        IERC20(_fromToken).safeApprove(address(_router), _amountIn);

        address pair = IUniswapV2Factory(_factory).getPair(
            _fromToken,
            _toToken
        );
        require(pair != address(0), "Pool does not exist");

        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(_router)
            .getAmountsOut(_amountIn, path)[1];

        uint deadline = block.timestamp + 300;

        uint256 amountReceived = IUniswapV2Router01(_router)
            .swapExactTokensForTokens(
                _amountIn,
                amountRequired,
                path,
                address(this),
                deadline
            )[1];

        require(amountReceived > 0, "Aborted Tx: Trade returned zero");

        return amountReceived;
    }

    function checkProfitability(uint256 _input, uint256 _output)
        private
        returns (bool)
    {
        return _output > _input;
    }

    function calculateTrade(
        address _base,
        address _quote,
        address _router,
        address _factory,
        uint256 _amount
    ) internal view returns (uint256) {

        address pair = IUniswapV2Factory(_factory).getPair(
            _base,
            _quote
        );

        require(pair != address(0), "Pool does not exist");
        
        address[] memory path = new address[](2);
        path[0] = _base;
        path[1] = _quote;

        uint256 amountOut = IUniswapV2Router01(_router).getAmountsOut(_amount, path)[1];
        return amountOut;
    }

    function calculateArbitrage(
        address _token1,
        address _token2,
        address _token3,
        address _trade1Router,
        address _trade1Factory,
        uint256 amount
    ) external view returns (uint256) {

        uint256 amountTrade1 = calculateTrade(_token1, _token2, _trade1Router, _trade1Factory, amount);
        assert(amountTrade1 > 0);

        uint256 amountTrade2 = calculateTrade(_token2, _token3, _trade1Router, _trade1Factory, amountTrade1);
        assert(amountTrade2 > 0);

        uint256 amountTrade3 = calculateTrade(_token3, _token1, _trade1Router, _trade1Factory, amountTrade2);
        assert(amountTrade3 > 0);

        return amountTrade3;
    }

    function startArbitrage(
        address _trade1Token,
        address _trade2Token,
        address _trade3Token,
        address _trade1Router,
        address _trade1Factory,
        address _flashquote,
        uint256 _amount
    ) external {

        address pair = IUniswapV2Factory(_trade1Factory).getPair(
            _trade1Token,
            _flashquote
        );

        require(pair != address(0), "Pool does not exist");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = _trade1Token == token0 ? _amount : 0;
        uint256 amount1Out = _trade1Token == token1 ? _amount : 0;

        bytes memory data = abi.encode(_trade1Token, _amount, msg.sender);

        trade1Token = _trade1Token;
        trade2Token = _trade2Token;
        trade3Token = _trade3Token;
        trade1Router = _trade1Router;
        trade1Factory = _trade1Factory;

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);

    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {

        (address tokenBorrow, uint256 amount, address myAddress) = abi.decode(
            _data,
            (address, uint256, address)
        );
        
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(trade1Factory).getPair(
            token0,
            token1
        );
        require(msg.sender == pair, "The sender needs to match the pair");
        require(_sender == address(this), "Sender should match this contract");

        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;

        uint256 trade1AcquiredCoin = placeTrade(
            trade1Token,
            trade2Token,
            trade1Router,
            trade1Factory,
            loanAmount
        );

        uint256 trade2AcquiredCoin = placeTrade(
            trade2Token,
            trade3Token,
            trade1Router,
            trade1Factory,
            trade1AcquiredCoin
        );

        uint256 trade3AcquiredCoin = placeTrade(
            trade3Token,
            trade1Token,
            trade1Router,
            trade1Factory,
            trade2AcquiredCoin
        );

        bool profCheck = checkProfitability(amountToRepay, trade3AcquiredCoin);
        require(profCheck, "Arbitrage not profitable");

        IERC20 otherToken = IERC20(trade1Token);
        otherToken.transfer(myAddress, trade3AcquiredCoin - amountToRepay);

        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }
}