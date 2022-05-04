//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Interfaces.sol";
import "./Libraries.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
  ILendingPool public immutable LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) public {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(provider.getLendingPool());
  }
}

contract PolyMultiCallFL is FlashLoanReceiverBase, IUniswapV2Callee {
    address private immutable owner;
    address private immutable executor;

    // Testnet
    address private constant SAND = address(0xe11A86849d99F524cAC3E7A0Ec1241828e332C62);
    address public WETH_address = address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    IWETH private constant WETH = IWETH(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    address private constant ETH_address = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address private constant UNISWAP_Factory = address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    address private constant UNISWAP_Router = address(0x8954AfA98594b838bda56FE4C12a09D7739D179b);

    // Mainnet
    // address private constant SAND = address(0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683);
    // address public WETH_address = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    // IWETH private constant WETH = IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    // address private constant ETH_address = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    // address private constant UNISWAP_Factory = address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    // address private constant UNISWAP_Router = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public payable {
        owner = msg.sender;
        executor = msg.sender;
    }


    function flashloanParams(address _baseToken, uint256 _amountToFirstMarket, bytes memory _params, uint256 _totalDebt) internal {
        (uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) = abi.decode(_params, (uint256, address[], bytes[]));
        require(_targets.length == _payloads.length, "len target != payload");
        IERC20 TOKEN = IERC20(_baseToken);
        uint256 _wethBalanceBefore = TOKEN.balanceOf(address(this));
        TOKEN.transfer(_targets[0], _amountToFirstMarket);
        uint256 len = _targets.length;
        for (uint256 i = 0; i < len; ++i) {
            (bool _success, /* bytes memory _response */) = _targets[i].call(_payloads[i]);
            require(_success); 
        }
        uint256 _wethBalanceAfter = TOKEN.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase + _totalDebt);
        uint256 _profit = _wethBalanceAfter - _totalDebt - _ethAmountToCoinbase;

        if (_ethAmountToCoinbase > 0) {
            if (_baseToken == WETH_address) {
                WETH.withdraw(_ethAmountToCoinbase + _profit);
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
        }
    }

    /* 
        Aave Flashloan
    */

    function flashloanAave(address borrowedTokenAddress, uint256 amountToBorrow, bytes memory _params) external onlyExecutor {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = borrowedTokenAddress;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountToBorrow;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        address onBehalfOf = address(this);
        uint16 referralCode = 0;
        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            _params,
            referralCode
        );
    }


    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address /* initiator */,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        address pool_address = address(LENDING_POOL);
        require(msg.sender == pool_address);
        uint amountOwing = amounts[0].add(premiums[0]);
        flashloanParams(assets[0], amounts[0], params, amountOwing);
        WETH.approve(pool_address, amountOwing);
        return true;
    }

    /* 
        QuickSwap Flashloan
    */

    function flashloanSwap(address borrowedTokenAddress, uint256 amountToBorrow, bytes memory _params) external onlyExecutor {
        address pair;
        if (borrowedTokenAddress == WETH_address || borrowedTokenAddress == SAND) {
            // WMATIC-USDC
            pair = address(0xabd99B35a91dD3e4BC02dca75730F9E337662519);
        } else {
            pair = IUniswapV2Factory(UNISWAP_Factory).getPair(borrowedTokenAddress, address(WETH_address));
            require(pair != address(0), "!pair");
        }
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = borrowedTokenAddress == token0 ? amountToBorrow : 0;
        uint amount1Out = borrowedTokenAddress == token1 ? amountToBorrow : 0;
        

        bytes memory data = abi.encode(borrowedTokenAddress, amountToBorrow, _params);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }


    function uniswapV2Call(
        address _sender,
        uint /* _amount0 */,
        uint /* _amount1 */,
        bytes calldata _data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(UNISWAP_Factory).getPair(token0, token1);

        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address borrowedTokenAddress, uint amountToBorrow, bytes memory _params) = abi.decode(_data, (address, uint, bytes));

        uint fee = ((amountToBorrow * 3) / 997) + 1;
        uint amountToRepay = amountToBorrow + fee;

        flashloanParams(borrowedTokenAddress, amountToBorrow, _params, amountToRepay);
        IERC20(borrowedTokenAddress).transfer(pair, amountToRepay);
    }

    /* 
        Simple Trade
    */


    function uniswapTrade(address _baseToken, uint256 _wethAmountToFirstMarket, uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) external payable onlyExecutor {
        require(_targets.length == _payloads.length, "len target != payload");

        IERC20 TOKEN = IERC20(_baseToken);
        
        if (msg.value > 0) {    
            WETH.deposit{value : msg.value}();
        } 

        uint256 _wethBalanceBefore = TOKEN.balanceOf(address(this));
        if (_baseToken == WETH_address && _wethBalanceBefore < _wethAmountToFirstMarket) { 
            WETH.deposit{value : _wethAmountToFirstMarket - _wethBalanceBefore}();
        }
        
        uint256 len = _targets.length;
        TOKEN.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < len; ++i) {
            (bool _success, ) = _targets[i].call(_payloads[i]);
            require(_success); 
        }

        uint256 _wethBalanceAfter = TOKEN.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase);

        if (_ethAmountToCoinbase > 0) {
            if (_baseToken == WETH_address) {
                uint256 _ethBalance = address(this).balance;
                if (_ethBalance < _ethAmountToCoinbase) {
                    WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
                }
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
        }
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = payable(_to).call{value: _value}(_data);
        require(_success);
        return _result;
    }

    receive() external payable {
    }

    function withdraw(address token) external onlyOwner {
        if (token == ETH_address) {
            payable(msg.sender).transfer(address(this).balance);
        } else if (token != ETH_address) {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(msg.sender, bal);
        }
    }
}