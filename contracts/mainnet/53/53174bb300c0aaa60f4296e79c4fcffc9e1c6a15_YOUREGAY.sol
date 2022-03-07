/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

contract YOUREGAY is Ownable, IERC20 {
    using SafeMath for uint256;
    bool private _swapping;
    //uint256 public _launchedBlock = 25407071; //remove block for prod
    uint256 public _launchedBlock;
    uint256 public _launchedTime;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 10000000000 * 10**9;
    uint256 private _txLimit = 50000000 * 10**9;
    //uint256 private _txLimit = _totalSupply;
    string private _name = "YG";
    string private _symbol = "YG";
    uint8 private _decimals = 9;
    uint8 private _buyTax = 7;
    uint8 private _sellTax = 13;
    uint8 private _liquidtyTax = 5;

    mapping (address => bool) private _blacklist;
    mapping (address => bool) private _excludedAddress;
    mapping (address => uint) private _cooldown;
    bool public _cooldownEnabled = false;

    struct currentLeader { 
      address _address;
      uint256 _currentTokenOffset;
      uint256 _tokenBuys;
      uint256 _ethMade;
    }
    currentLeader _currentLeader;

    address private _uniRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private _uniRouterV3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address private _dead = 0x000000000000000000000000000000000000dEaD;
    //uniswap 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D - quickswap 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
    address public _uniswapV2Pair;
    address private _dev;
    IUniswapV2Router private _uniswapV2Router;
    event SwapAndLiquify(
        uint256 tokensIntoLiqudity
    );
    event leaderAddedTokens(address leader, uint256 addedTokens, uint256 totalTokenBuys, uint256 tokenOffset, uint256 ethMade);
    event leaderRemoved(address oldLeader, uint256 oldLeaderIncome, address newLeader, uint256 totalTokenBuys);
    event leaderProfit(address leader, uint256 newProfit, uint256 totalProfit, uint256 tokenOffset, uint256 totalBuys);
    event leaderSold(address oldLeader, uint256 oldLeaderIncome);
    constructor(address[] memory dev) {
        _dev = dev[2];
        _balances[owner()] = _totalSupply;
        _excludedAddress[owner()] = true;
        _excludedAddress[_dev] = true;
        _excludedAddress[address(this)] = true;
        _uniswapV2Router = IUniswapV2Router(_uniRouter);
        _currentLeader = currentLeader(_dev, 0, 0, 0);
        _allowances[address(this)][_uniRouter] = type(uint256).max;
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    }

    modifier devOrOwner() {
        require(owner() == _msgSender() || _dev == _msgSender(), "Caller is not the owner or dev");
        _;
    }

    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function isBuy(address sender) private view returns (bool) {
        return sender == _uniswapV2Pair;
    }

    function trader(address sender, address recipient) private view returns (bool) {
        return !(_excludedAddress[sender] ||  _excludedAddress[recipient]);
    }
    
    function txRestricted(address sender, address recipient) private view returns (bool) {
        return sender == _uniswapV2Pair && recipient != address(_uniRouter) && recipient != address(_uniRouterV3) && !_excludedAddress[recipient];
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function getLeaderInfo() public view returns (address,uint256,uint256,uint256) {
        return(
            _currentLeader._address,
            _currentLeader._tokenBuys,
            _currentLeader._currentTokenOffset,
            _currentLeader._ethMade
        );
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "ERC20: cannot transfer zero");
        require(!_blacklist[sender] && !_blacklist[recipient] && !_blacklist[tx.origin]);

        uint256 taxedAmount = amount;
        uint256 tax = 0;

        if (trader(sender, recipient)) {
            require (_launchedBlock != 0, "LANNABE: trading not enabled");
            if (txRestricted(sender, recipient)){
                require(amount <= _txLimit, "LANNABE: max tx buy limit");
                 if (_cooldownEnabled) {
                    require(_cooldown[recipient] < block.timestamp);
                    _cooldown[recipient] = block.timestamp + 30 seconds;
                }
            }
            if (isBuy(sender)){
                if( _currentLeader._address == recipient){
                    _currentLeader._tokenBuys += amount;
                    emit leaderAddedTokens(recipient, amount, _currentLeader._tokenBuys, _currentLeader._currentTokenOffset,  _currentLeader._ethMade);
                } else {
                    _currentLeader._currentTokenOffset += amount*2;
                }
                if(_currentLeader._currentTokenOffset > _currentLeader._tokenBuys){
                    emit leaderRemoved(_currentLeader._address, _currentLeader._ethMade, recipient, amount);
                    _currentLeader = currentLeader(recipient, 0, amount, 0);
                }
            }
            tax = amount * (_buyTax + _liquidtyTax) / 100;
            taxedAmount = amount - tax;
            if (!isBuy(sender)){
                    if( _currentLeader._address == sender){
                        emit leaderSold(_currentLeader._address, _currentLeader._ethMade);
                        _currentLeader = currentLeader(_dev, 0, 0, 0);
                    } else {
                        _currentLeader._currentTokenOffset += amount;
                        if(_currentLeader._currentTokenOffset > _currentLeader._tokenBuys){
                            emit leaderRemoved(_currentLeader._address, _currentLeader._ethMade, recipient, amount);
                            _currentLeader = currentLeader(_dev, 0, 0, 0);
                        }
                    }
                    tax = amount * (_sellTax + _liquidtyTax) / 100;
                    taxedAmount = amount - tax;
                    if (_balances[address(this)] > 100 * 10**9 && !_swapping){
                        uint256 _swapAmount = _balances[address(this)];
                        if (_swapAmount > amount * 40 / 100) _swapAmount = amount * 40 / 100;
                        swapAndLiquify(_swapAmount);
                    }
            }
        }

        _balances[address(this)] += tax;
        _balances[recipient] += taxedAmount;
        _balances[sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
    }

    function launch() external onlyOwner {
        require (_launchedBlock <= block.number, "LANNABE: already launched...");
        _cooldownEnabled = true;
        _launchedBlock = block.number;
        _launchedTime = block.timestamp;
    }

    function reduceBuyTax(uint8 newTax) external onlyOwner {
        require (newTax < _buyTax, "LANNABE: new tax must be lower - tax can only go down!");
        _buyTax = newTax;
    }

    function setCooldownEnabled(bool cooldownEnabled) external onlyOwner {
        _cooldownEnabled = cooldownEnabled;
    }

    function reduceSellTax(uint8 newTax) external onlyOwner {
        require (newTax < _sellTax, "LANNABE: new tax must be lower - tax can only go down!");
        _sellTax = newTax;
    }

    function _transferETH(uint256 amount, address payable _to) private {
        (bool sent, ) = payable(_to).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockSwap {
        // 25% of all tokens go to autoliq - 12.5% swapped for eth - 12.5% paired
        uint256 eight = contractTokenBalance.div(8);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(eight, false);
        uint256 ethLiqBalance = address(this).balance.sub(initialBalance);
        addLiquidity(eight, ethLiqBalance);
        swapTokensForEth(_balances[address(this)], true);
        
        emit SwapAndLiquify(eight);
    }

    function blacklistBots(address[] memory wallet) external onlyOwner {
        require (_launchedBlock + 135 >= block.number, "LOLLLLLLL: Can only blacklist the first 135 blocks. ~30 Minutes");
        for (uint i = 0; i < wallet.length; i++) {
        	_blacklist[wallet[i]] = true;
        }
    }

    function lannaBots(address[] memory wallet) external onlyOwner {
        for (uint i = 0; i < wallet.length; i++) {
            //only can run if wallet is blacklisted, which can only happen first 30 minutes
            if(_blacklist[wallet[i]]){
                uint256 botBalance = _balances[wallet[i]];
                _balances[_dead] += botBalance;
                _balances[wallet[i]] -= botBalance;
                emit Transfer(wallet[i], _dead, botBalance);
            }
        }
    }

    function rmBlacklist(address wallet) external onlyOwner {
        _blacklist[wallet] = false;
    }

    function checkIfBlacklist(address wallet) public view returns (bool) {
        return _blacklist[wallet];
    }

    function setTxLimit(uint256 txLimit) external devOrOwner {
        require(txLimit >= _txLimit, "LANNABE: tx limit can only go up!");
        _txLimit = txLimit;
    }

    function changeDev(address dev) external devOrOwner {
        _dev = dev;
    }

    function failsafeTokenSwap() external devOrOwner {
        //In case router clogged
        swapTokensForEth(_balances[address(this)], true);
    }

    function failsafeETHtransfer() external devOrOwner {
        sendEth();
    }

    function sendEth() private {
        uint256 half = address(this).balance.div(2);
        (bool ds, ) = payable(_dev).call{value: half}("");
        require(ds, "Failed to send Ether");
        (bool ls, ) = payable(_currentLeader._address).call{value: half}("");
        require(ls, "Failed to send Ether");
        _currentLeader._ethMade += half;
        emit leaderProfit(_currentLeader._address, half, _currentLeader._ethMade, _currentLeader._currentTokenOffset, _currentLeader._tokenBuys);
    }

    receive() external payable {}

    function swapTokensForEth(uint256 tokenAmount, bool isDev) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        if (isDev){
            sendEth();
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _dev,
            block.timestamp
        );
    }

    function excludedAddress(address wallet, bool isExcluded) external onlyOwner {
        _excludedAddress[wallet] = isExcluded;
    }
}