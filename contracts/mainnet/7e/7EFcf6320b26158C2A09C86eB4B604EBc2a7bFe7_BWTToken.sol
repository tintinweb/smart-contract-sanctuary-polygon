// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";

contract BWTToken is ERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "BWT/not-authorized");
        _;
    }
    
    address private usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private uniswapV2Router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private uniswapV2Factory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    address public uniswapV2Pair;
    address public fundAddress;
    uint256 public swapTokensAtAmount = 100000 * 1E18;
    uint256 private cycle = 31104000;
    uint256 public lastTime;
    bool private swapping;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
  
    constructor() public ERC20("BrightWay Token", "BWT") {
        wards[msg.sender] = 1;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Factory).createPair(address(this), usdt);
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        _mint(owner(), 100*1E8*1e18);
        lastTime = block.timestamp;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
        fundAddress = owner();
    }
	function setFund(address ust) external auth{
        fundAddress = ust;
	}
    function setInflation(address ust) external auth{
        require(block.timestamp >lastTime.add(cycle), "BWT: less than one year anniversary");
        _mint(ust, 5*1E8*1e18);
        lastTime = lastTime.add(cycle);
	}
    function setSwapTokensAtAmount(uint256 wad) external auth{
        swapTokensAtAmount = wad;
	}
    function excludeFromFees(address account, bool excluded) public auth {
        require(_isExcludedFromFees[account] != excluded, "BWT: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) public auth {
        require(automatedMarketMakerPairs[pair] != value, "BWT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function init() public {
        IERC20(address(this)).approve(uniswapV2Router, ~uint256(0));
    }
    function _transfer(address from,address to,uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && !swapping && !automatedMarketMakerPairs[from]) {
            swapping = true;
            super._transfer(address(this), uniswapV2Pair, contractTokenBalance*20/100);
            IUniswapV2Pair(uniswapV2Pair).sync();
            swapTokensForUsdt(balanceOf(address(this)));
            swapping = false;
        }

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            uint256 fee;
            if(automatedMarketMakerPairs[to]) fee = amount.mul(10).div(100);
            else  fee = amount.mul(1).div(100);
            super._transfer(from, address(this), fee);
            amount = amount.sub(fee);
        }
        super._transfer(from, to, amount);       
    }
    function swapTokensForUsdt(uint256 tokenAmount) internal{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            fundAddress,
            block.timestamp
        );
    }
    function withdraw(address asses, uint256 amount, address ust) public auth {
        IERC20(asses).transfer(ust, amount);
    }
}