/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.15;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {function createPair(address tokenA, address tokenB) external returns (address pair);}
interface IDEXPair {function sync() external;}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken,uint256 amountETH,uint256 liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Houdini is IBEP20 {
    string constant _name = "HoudiniTest";
    string constant _symbol = "HoudiniTest";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 100_000_000 * (10**_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public addressWithoutLimits;

    uint256 public tax = 5;
    uint256 private liq = 1;
    uint256 private buyBack = 1;
    uint256 private team = 1;
    uint256 private staking = 1;
    uint256 private burn = 1;
    uint256 private taxDivisor = 100;
    uint256 private launchTime = type(uint256).max;

    bool private isSwapping;
    
    IDEXRouter public router = IDEXRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    address public constant CEO = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
                
    address public buyBackWallet;
    address public teamWallet;
    address public stakingWallet;
    address public pair;
    address public WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address[] private pathForSelling = new address[](2);
    
    modifier onlyOwner() {if(msg.sender != CEO) return; _;}
    modifier contractSelling() {isSwapping = true; _; isSwapping = false;}

    constructor() {
        pair = IDEXFactory(IDEXRouter(router).factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        addressWithoutLimits[CEO] = true;
        addressWithoutLimits[address(this)] = true;

        pathForSelling[0] = address(this);
        pathForSelling[1] = WETH;

        _balances[CEO] = _totalSupply;
        emit Transfer(address(0), CEO, _totalSupply);
    }

    receive() external payable {}
    function name() public pure override returns (string memory) {return _name;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function decimals() public pure override returns (uint8) {return _decimals;}
    function symbol() public pure override returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) public view override returns (uint256) {return _allowances[holder][spender];}
    function approveMax(address spender) public returns (bool) {return approve(spender, type(uint256).max);}
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }
        
        return _transferFrom(sender, recipient, amount);
    }

    function manualSell() external onlyOwner {
        letTheContractSell();
    }

    function setWallets(address buyBackAddress, address teamAddress, address stakingAddress) external onlyOwner {
        buyBackWallet = buyBackAddress;
        teamWallet = teamAddress;
        stakingWallet = stakingAddress;
    }

    function rescueAnyToken(address token) external onlyOwner {
        IBEP20(token).transfer(msg.sender, IBEP20(token).balanceOf(address(this)));
    }

    function rescueBnb() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTax(
        uint256 newTax,
        uint256 newTaxDivisor,
        uint256 newLiq,
        uint256 newBuyBack,
        uint256 newTeam,
        uint256 newBurn,
        uint256 newStaking
    ) external onlyOwner {
        tax = newTax;
        taxDivisor = newTaxDivisor;
        liq = newLiq;
        buyBack = newBuyBack;
        team = newTeam;
        burn = newBurn;
        staking = newStaking;
        require(tax <= taxDivisor / 10, "Taxes are limited to max. 10%");
    }

    function setAddressWithoutTax(address unTaxedAddress, bool status) external onlyOwner {
        addressWithoutLimits[unTaxedAddress] = status;
    }

    function launch() external payable onlyOwner {
        launchTime = block.timestamp;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (
            isSwapping == true ||
            addressWithoutLimits[sender] == true ||
            addressWithoutLimits[recipient] == true
        ) return _lowGasTransfer(sender, recipient, amount);

        if (launchTime > block.timestamp) return true;

        if (conditionsToSwapAreMet(sender)) letTheContractSell();
        amount = takeTax(sender, amount);
        return _lowGasTransfer(sender, recipient, amount);
    }

    function takeTax(address sender, uint256 amount) internal returns (uint256) {
        uint256 taxAmount = amount * (tax - burn) / taxDivisor;
        uint256 burnAmount = amount * burn / taxDivisor;
        if (burnAmount > 0) _lowGasTransfer(sender, DEAD, taxAmount);
        if (taxAmount > 0) _lowGasTransfer(sender, address(this), taxAmount);
        return amount - taxAmount;
    }

    function conditionsToSwapAreMet(address sender) internal view returns (bool) {
        return sender != pair && !isSwapping;
    }

    function _lowGasTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function letTheContractSell() internal {
        uint256 swapAmount = _balances[address(this)] * (buyBack + team + staking) / (tax - burn);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            pathForSelling,
            address(this),
            block.timestamp
        );

        _lowGasTransfer(address(this), pair, _balances[address(this)]);
        IDEXPair(pair).sync();

        uint256 onePercent = address(this).balance / (buyBack + team + staking);
        payable(buyBackWallet).transfer(onePercent * buyBack);
        payable(stakingWallet).transfer(onePercent * staking);
        payable(teamWallet).transfer(address(this).balance);
    }
}