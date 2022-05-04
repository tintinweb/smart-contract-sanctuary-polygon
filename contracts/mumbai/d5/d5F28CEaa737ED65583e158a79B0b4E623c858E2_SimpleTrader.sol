//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Interfaces.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract SimpleTrader {

    event Deposited(uint balance, uint blockNumber, string message);
    event AltDeposit(uint balance, uint blockNumber, string message);
    event Transfered(uint balance, uint blockNumber, string message);
    event Swap(bool success, uint blockNumber, string message);

    address private immutable owner;
    address public WETH_address = address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    IWETH private constant WETH = IWETH(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    address private constant ETH_address = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address private constant UNISWAP_Router = address(0x8954AfA98594b838bda56FE4C12a09D7739D179b);

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
            emit Deposited(TOKEN.balanceOf(address(this)), block.number, "deposited");
        } 
        // (block.timestamp, block.number, "logged setttled block");
        uint256 _wethBalanceBefore = TOKEN.balanceOf(address(this));
        if (_baseToken == WETH_address && _wethBalanceBefore < _wethAmountToFirstMarket) { 
            WETH.deposit{value : _wethAmountToFirstMarket}();
            emit AltDeposit(_wethBalanceBefore, block.number, "second if clause");
        }
        
        TOKEN.transfer(_targets[0], _wethAmountToFirstMarket);
        emit Transfered(TOKEN.balanceOf(address(this)), block.number, "transfered ammount to first market");
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, ) = _targets[i].call(_payloads[i]);
            emit Swap(_success, block.number, "Market Swap successful?");
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

    
    // function shell() external returns (uint, uint, string memory) {
    //     emit Stamped(block.timestamp, block.number, "logged setttled block");
    //     return (block.timestamp, block.number, "logged setttled block");
    // }

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