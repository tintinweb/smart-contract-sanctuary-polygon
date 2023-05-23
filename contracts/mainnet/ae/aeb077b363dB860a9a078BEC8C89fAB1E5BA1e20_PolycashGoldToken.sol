/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) { return _owner; }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract PolycashGoldToken is Ownable {

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);

    string public name = "Polycash Gold Token";
    string public symbol = "PLG";
    uint256 public decimals = 18;
    uint256 public totalSupply =   1_000_000 * (10**decimals);
    
    IDEXRouter public router;
    address public pair;
    address public receiver;
    bool basicTransfer;

    uint256 tradingTax = 3;
    uint256 denominator = 100;
    uint256 swapthreshold = 0;
    bool public enabledTrading;

    mapping(address => uint256) public balances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() {
        receiver = msg.sender;
        router = IDEXRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        allowance[address(this)][address(router)] = type(uint256).max;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(router)] = true;
        isFeeExempt[address(msg.sender)] = true;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
    }
    
    function balanceOf(address adr) public view returns(uint256) { return balances[adr]; }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transferFrom(msg.sender,to,amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        allowance[from][msg.sender] -= amount;
        _transferFrom(from,to,amount);
        return true;
    }

    function _transferFrom(address from,address to, uint256 amount) internal {
        if(basicTransfer){ return _basictransfer(from,to,amount); }else{
            if(balances[address(this)] > swapthreshold && msg.sender != pair){
                basicTransfer = true;
                uint256 distribute = balances[address(this)] / 2;
                uint256 liquidfy = distribute / 2;
                uint256 amountToSwap = distribute + liquidfy;
                uint256 before = address(this).balance;
                swap2ETH(amountToSwap);
                uint256 increase = address(this).balance - before;
                uint256 torecevier = increase * 2 / 3;
                uint256 tolp = increase - torecevier;
                (bool success,) = receiver.call{ value: torecevier }("");
                require(success, "!fail to send eth");
                autoAddLP(liquidfy,tolp);
                basicTransfer = false;
            }
            _transfer(from,to,amount);
        }
    }

    function approve(address to, uint256 amount) public returns (bool) {
        require(to != address(0));
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function _transfer(address from,address to, uint256 amount) internal {
        if(from==pair){ require(enabledTrading,"Trading Was Not Open Yet"); }
        balances[from] -= amount;
        balances[to] += amount;
        uint256 fee;
        if(from==pair){ fee = amount * tradingTax / denominator; }
        if(to==pair){ fee = amount * tradingTax / denominator; }
        if(fee>0){ _basictransfer(to,address(this),fee); }
        emit Transfer(from, to, amount - fee);
    }

    function _basictransfer(address from,address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function swap2ETH(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        amount,
        0,
        path,
        address(this),
        block.timestamp
        );
    }

    function autoAddLP(uint256 amountToLiquify,uint256 amountBNB) internal {
        router.addLiquidityETH{value: amountBNB }(
        address(this),
        amountToLiquify,
        0,
        0,
        receiver,
        block.timestamp
        );
    }

    function enableTrading() public onlyOwner() returns (bool) {
        require(!enabledTrading,"Trading Already Enabled");
        enabledTrading = true;
        return true;
    }

    function settingFeeExempt(address _account,bool _flag) public onlyOwner() returns (bool) {
        isFeeExempt[_account] = _flag;
        return true;
    }
    
    function settingTokenomics(uint256 _tax,uint256 _swapTreshold,uint256 _denominator) public onlyOwner() returns (bool) {
        tradingTax = _tax;
        denominator = _denominator;
        swapthreshold = _swapTreshold;
        return true;
    }

    receive() external payable {}
}