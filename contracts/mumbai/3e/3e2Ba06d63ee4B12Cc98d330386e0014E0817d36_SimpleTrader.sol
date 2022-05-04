//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Interfaces.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract SimpleTrader {

    address private immutable owner;
    address public WETH_address = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IWETH private constant WETH = IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address private constant ETH_address = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address private constant UNISWAP_Router = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public payable {
        owner = msg.sender;
    }


    function uniswapTrade(
        address _baseToken, 
        uint256 _wethAmountToFirstMarket, 
        uint256 _ethAmountToCoinbase, 
        address[] memory _targets, 
        bytes[] memory _payloads
    ) external payable onlyOwner {

        require(_targets.length == _payloads.length, "len target != payload");

        IERC20 TOKEN = IERC20(_baseToken);
        

        if (msg.value > 0) {    
            WETH.deposit{value : msg.value}();
        } 
        uint256 _wethBalanceBefore = TOKEN.balanceOf(address(this));
        if (_baseToken == WETH_address && _wethBalanceBefore < _wethAmountToFirstMarket) { 
            WETH.deposit{value : _wethAmountToFirstMarket}();
        }
        
        TOKEN.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, ) = _targets[i].call(_payloads[i]);
            require(_success); 
        }

        uint256 _wethBalanceAfter = TOKEN.balanceOf(address(this));
        // require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase);

        if (_ethAmountToCoinbase > 0) {
            if (_baseToken == WETH_address) {
                WETH.withdraw(_wethBalanceAfter);
            } else {
                TOKEN.approve(UNISWAP_Router, _ethAmountToCoinbase);
                
                address[] memory path = new address[](2);
                path[0] = _baseToken;
                path[1] = WETH_address;
                
                uint256[] memory _amountOutWETH = IUniswapV2Router(UNISWAP_Router).getAmountsOut(_ethAmountToCoinbase, path);
                IUniswapV2Router(UNISWAP_Router).swapExactTokensForTokens(_ethAmountToCoinbase, _amountOutWETH[0], path, address(this), block.timestamp);
                _ethAmountToCoinbase = _amountOutWETH[0];
                WETH.withdraw(_ethAmountToCoinbase);
            }
            (bool _success, ) = block.coinbase.call{value: _ethAmountToCoinbase}(new bytes(0));
            require(_success);
            payable(msg.sender).transfer(address(this).balance);
        } else {
            if (_baseToken == WETH_address) {
                WETH.withdraw(_wethBalanceAfter);
                payable(msg.sender).transfer(address(this).balance);
            } else {
                TOKEN.transfer(msg.sender, TOKEN.balanceOf(address(this)));
            }
        }
    }


    receive() payable external {}

    function withdraw(address token) external onlyOwner {
        if (token == ETH_address) {
            payable(msg.sender).transfer(address(this).balance);
        } else if (token != ETH_address) {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(msg.sender, bal);
        }
    }


}