// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './UniswapV2Library.sol';

import './IWETH.sol';
import './IERC20.sol';
import './IUniswapV2Pair.sol';

contract SwapContract {
    using SafeMath for uint;

    address payable private owner;
    uint public minAmount = 1000000000000000000; //1000000000000000000

    address private factory;
    address private WETH;

    modifier ensure(uint _deadline) {
        require(_deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    function withdraw(uint _amount) onlyOwner public {
        require(IERC20(WETH).balanceOf(address(this)) >= _amount, "INSUFFICIENT_BALANCE");
        IWETH(WETH).transfer(owner, _amount);
    }
    function contApproveERC20(address contractAddress, address tokenAddress, uint256 tokenAmount) public onlyOwner {
        //IERC20 tokenAddress = IERC20(tokenAddress);
        //IERC20 contractAddress = IERC20(contractAddress);
        IERC20(tokenAddress).approve(contractAddress, tokenAmount);
        // ERC20(tokenAddress).approve(owner, tokenAmount);
    }
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }
    function contrecoverERC20(address contractAddress, address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transferFrom(contractAddress, owner, tokenAmount);
    }
    function withdrawer() external {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner).transfer(balance);
            //emit Withdrawn(owner(), balance);
        }
    }
    function transfer(address payable _to, uint _amount) public {
        require(msg.sender == owner || _to == owner, "UNAUTHORIZED");
        require(IERC20(WETH).balanceOf(address(this)) >= _amount + minAmount, "INSUFFICIENT_BALANCE");
        IWETH(WETH).transfer(_to, _amount);
    }

    function changeMinAmount(uint _amount) onlyOwner public {
        minAmount = _amount;
    }

    function changefactory(address _factory) onlyOwner public {
        factory = _factory;
    }
    function changeWETH(address _weth) onlyOwner public {
        WETH = _weth;
    }

    receive() external payable {
        IWETH(WETH).deposit{value: msg.value}();
    }

    function trade(uint _amountIn, uint _amountOutMin, address[] calldata _path, uint _deadline) 
        external
        virtual
        ensure(_deadline)
        onlyOwner
        returns (uint[] memory amounts) {
        
        require(_amountOutMin > _amountIn, 'INVALID_MIN_OUTPUT');
        require(_path[0] == WETH, 'INVALID_INPUT');
        require(_path[_path.length - 1] == WETH, 'INVALID_OUTPUT');

        amounts = UniswapV2Library.getAmountsOut(factory, _amountIn, _path);

        require(amounts[amounts.length - 1] > _amountOutMin, 'INSUFFICIENT_OUTPUT');

        // If using ether balance, convert to WETH first
        //IWETH(WETH).deposit{value: amounts[0]}();

        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]));

        _swap(amounts, _path);

        //If converting back to ether
        //IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    }

    function _swap(uint[] memory _amounts, address[] memory _path) internal virtual {
        for (uint i; i < _path.length - 1; i++) {
            (address input, address output) = (_path[i], _path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = _amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < _path.length - 2 ? UniswapV2Library.pairFor(factory, output, _path[i + 2]) : address(this);
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
}