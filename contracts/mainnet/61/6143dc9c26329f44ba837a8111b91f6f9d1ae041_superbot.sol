/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IuniswapRouter {
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
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

interface IquickswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IsushiswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract superbot {

    // dexes swap router addresses
    address quickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address sushiswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // signatory 
    address public signatory;
    string public signatoryEmail;

    // arbitrage smart contract owner
    address owner;
    bool swapRouterStx;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == signatory, "sender not owner");
        _;
    }

        modifier onlyOwners() {
        require(msg.sender == owner);
        _;
    }


    function updateSignatory (address _signatoryAddress, string memory _signatoryEmail ) public onlyOwner returns(bool) {
        signatory = _signatoryAddress;
        signatoryEmail = _signatoryEmail;
        return true;
    }

    // buy matic on quickswap and sell on sushiswap
    function quicktosushiARB(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _amountOutMin1,
    uint256 _expectedProfit
    ) public onlyOwner returns (bool success) {
        address[] memory path1 = new address[](2);
        path1[0] = _baseCurrency;
        path1[1] = _qouteCurrency;
        uint256 deadline = block.timestamp + 300;
        IERC20(_baseCurrency).approve(quickswapRouter,_baseAmount);
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            _baseAmount,
            _amountOutMin1,
            path1,
            address(this),
            deadline
        );

        address[] memory path2 = new address[](2);
        path2[0] = _qouteCurrency;
        path2[1] = _baseCurrency;
        uint256 amountIn2 = IERC20(_qouteCurrency).balanceOf(address(this));
        IERC20(_qouteCurrency).approve(sushiswapRouter,amountIn2);
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            amountIn2,
            _expectedProfit,
            path2,
            address(this),
            deadline
        );
        return true;
    }

    // buy matic on sushiswap and sell on quickswap
    function sushitoquickARB(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _amountOutMin1,
    uint256 _expectedProfit
    ) public onlyOwner returns (bool success) {
        address[] memory path1 = new address[](2);
        path1[0] = _baseCurrency;
        path1[1] = _qouteCurrency;
        uint256 deadline = block.timestamp + 300;
        IERC20(_baseCurrency).approve(sushiswapRouter,_baseAmount);
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            _baseAmount,
            _amountOutMin1,
            path1,
            address(this),
            deadline
        );
        address[] memory path2 = new address[](2);
        path2[0] = _qouteCurrency;
        path2[1] = _baseCurrency;
        uint256 amountIn2 = IERC20(_qouteCurrency).balanceOf(address(this));
        IERC20(_qouteCurrency).approve(quickswapRouter,amountIn2);
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            amountIn2,
            _expectedProfit,
            path2,
            address(this),
            deadline
        );
        return true;
    }

    // buy on uniswap and sell on sushiswap
    function unitosushiARB(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _amountOutMin1,
    uint256 _expectedProfit
    ) public onlyOwner returns (bool success) {
        uint256 deadline = block.timestamp + 300;
        IuniswapRouter.ExactInputSingleParams memory params = IuniswapRouter
            .ExactInputSingleParams({
                tokenIn: _baseCurrency,
                tokenOut: _qouteCurrency,
                fee: 3000,
                recipient: address(this),
                deadline: deadline,
                amountIn: _baseAmount,
                amountOutMinimum: _amountOutMin1,
                sqrtPriceLimitX96: 0
            });
        IERC20(_baseCurrency).approve(uniswapRouter,_baseAmount);
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        address[] memory path2 = new address[](2);
        path2[0] = _qouteCurrency;
        path2[1] = _baseCurrency;
        uint256 amountIn2 = IERC20(_qouteCurrency).balanceOf(address(this));
        IERC20(_qouteCurrency).approve(sushiswapRouter,amountIn2);
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            amountIn2,
            _expectedProfit,
            path2,
            address(this),
            deadline
        );
        return true;
    }

    // buy on sushiswap and sell on uniswap
    function sushitouniARB(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _amountOutMin1,
    uint256 _expectedProfit
    ) public onlyOwner returns (bool success) {
        uint256 deadline = block.timestamp + 300;
        address[] memory path1 = new address[](2);
        path1[0] = _baseCurrency;
        path1[1] = _qouteCurrency;
        IERC20(_baseCurrency).approve(sushiswapRouter,_baseAmount);
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            _baseAmount,
            _amountOutMin1,
            path1,
            address(this),
            deadline
        );
        uint256 amountIn2 = IERC20(_qouteCurrency).balanceOf(address(this));
        IERC20(_qouteCurrency).approve(uniswapRouter,amountIn2);
        IuniswapRouter.ExactInputSingleParams memory params = IuniswapRouter
            .ExactInputSingleParams({
                tokenIn: _qouteCurrency,
                tokenOut: _baseCurrency,
                fee: 3000,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn2,
                amountOutMinimum: _expectedProfit,
                sqrtPriceLimitX96: 0
            });
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        return true;
    }

    ////////////////////////////////////////////////

        // buy on uniswap and sell on quickswap
    function unitoquickARB(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _amountOutMin1,
    uint256 _expectedProfit
    ) public onlyOwner returns (bool success) {
    uint256 deadline = block.timestamp + 300;
        IuniswapRouter.ExactInputSingleParams memory params = IuniswapRouter
            .ExactInputSingleParams({
                tokenIn: _baseCurrency,
                tokenOut: _qouteCurrency,
                fee: 3000,
                recipient: address(this),
                deadline: deadline,
                amountIn: _baseAmount,
                amountOutMinimum: _amountOutMin1,
                sqrtPriceLimitX96: 0
            });
        IERC20(_baseCurrency).approve(uniswapRouter,_baseAmount);
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        address[] memory path2 = new address[](2);
        path2[0] = _qouteCurrency;
        path2[1] = _baseCurrency;
        uint256 amountIn2 = IERC20(_qouteCurrency).balanceOf(address(this));
        IERC20(_qouteCurrency).approve(quickswapRouter,amountIn2);
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            amountIn2,
            _expectedProfit,
            path2,
            address(this),
            deadline
        );
        return true;
    }

    // buy on quickswap sell on uniswap
    function quicktouniARB(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _amountOutMin1,
    uint256 _expectedProfit
    ) public onlyOwner returns (bool success) {
        uint256 deadline = block.timestamp + 300;
        address[] memory path1 = new address[](2);
        path1[0] = _baseCurrency;
        path1[1] = _qouteCurrency;
        IERC20(_baseCurrency).approve(quickswapRouter,_baseAmount);
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            _baseAmount,
            _amountOutMin1,
            path1,
            address(this),
            deadline
        );
        uint256 amountIn2 = IERC20(_qouteCurrency).balanceOf(address(this));
        IERC20(_qouteCurrency).approve(uniswapRouter,amountIn2);
        IuniswapRouter.ExactInputSingleParams memory params = IuniswapRouter
            .ExactInputSingleParams({
                tokenIn: _qouteCurrency,
                tokenOut: _baseCurrency,
                fee: 3000,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn2,
                amountOutMinimum: _expectedProfit,
                sqrtPriceLimitX96: 0
            });
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        return true;
    }

        function withdrawERC20(uint256 _amount, address _ERC20Address, address _receiver)
        public
        onlyOwner
        returns (uint256 amount)
    {
        IERC20(_ERC20Address).transfer(_receiver, _amount);
        return amount;
    }

        function withdrawMATIC(uint256 _amount)
        public
        onlyOwner
        returns (uint256 amount)
    {
        payable(msg.sender).transfer(_amount);
        return amount;
    }

    function sushiLimitOrder(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _expectedProfit
    ) public onlyOwner returns(bool){
        address[] memory path1 = new address[](2);
        path1[0] = _baseCurrency;
        path1[1] = _qouteCurrency;
        uint256 deadline = block.timestamp + 300;
        IERC20(_baseCurrency).approve(sushiswapRouter,_baseAmount);
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            _baseAmount,
            _expectedProfit,
            path1,
            address(this),
            deadline
        );
        return true;
    }

    function quickLimitOrder(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _expectedProfit
    ) public onlyOwner returns(bool){
        address[] memory path1 = new address[](2);
        path1[0] = _baseCurrency;
        path1[1] = _qouteCurrency;
        uint256 deadline = block.timestamp + 300;
        IERC20(_baseCurrency).approve(quickswapRouter,_baseAmount);
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            _baseAmount,
            _expectedProfit,
            path1,
            address(this),
            deadline
        );
        return true;
    }


    function uniLimitOrder(
    uint256 _baseAmount,
    address _baseCurrency,
    address _qouteCurrency,
    uint256 _expectedProfit
    ) public onlyOwner returns(bool){
        address[] memory path1 = new address[](2);
        path1[0] = _baseCurrency;
        path1[1] = _qouteCurrency;
        uint256 deadline = block.timestamp + 300;
        IERC20(_baseCurrency).approve(uniswapRouter,_baseAmount);
        IuniswapRouter.ExactInputSingleParams memory params = IuniswapRouter
            .ExactInputSingleParams({
                tokenIn: _baseCurrency,
                tokenOut: _qouteCurrency,
                fee: 3000,
                recipient: address(this),
                deadline: deadline,
                amountIn: _baseAmount,
                amountOutMinimum: _expectedProfit,
                sqrtPriceLimitX96: 0
            });
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        return true;
    }
    
}