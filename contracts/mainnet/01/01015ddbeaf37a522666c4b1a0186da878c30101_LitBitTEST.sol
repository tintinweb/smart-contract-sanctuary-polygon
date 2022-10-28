/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

/*  
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.17;

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract LitBitTEST is IBEP20 {
    string constant _name = "LitBitTEST";
    string constant _symbol = "LitTEST";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1_000_000_000 * (10**_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public limitless;
    mapping(address => bool) public badWallet;

    uint256 public  buyTax = 10;
    uint256 private buyLiq = 5;
    uint256 private buyMarketing = 5;
    uint256 private buyToken = 0;
    uint256 private buyBurn = 0;
    uint256 public  sellTax = 10;
    uint256 private sellLiq = 5;
    uint256 private sellMarketing = 5;
    uint256 private sellToken = 0;
    uint256 private sellBurn = 0;   
    uint256 private taxDivisor = 100;
    uint256 private collectedBuyLiqTax;
    uint256 private collectedBuyMarketingTax;
    uint256 private collectedSellLiqTax;
    uint256 private collectedSellMarketingTax;
    uint256 private minTokensToSell = _totalSupply / 100;
    uint256 private launchTime = type(uint256).max;

    IDEXRouter public router = IDEXRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    address public constant CEO = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    address private constant WBNB = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
           
    address public marketingWallet = CEO;
    address public tokenWallet = CEO;
    address[] public pairs;
    address public pcsPair;

    mapping(address => bool) public isVested;
    mapping(address => uint256) private vestedAmount;
    mapping(address => uint256) private percentageAtLaunch;
    mapping(address => uint256) private percentageEveryMonth;

    address[] private pathForSelling = new address[](2);

    modifier onlyCEO(){
        require (msg.sender == CEO, "Only the CEO can do that");
        _;
    }

    event WalletsChanged(address marketingWallet, address tokenWallet);
    event MinTokensToSellSet(uint256 minTokensToSell);
    event TokenRescued(address tokenRescued, uint256 amountRescued);
    event BnbRescued(uint256 balanceRescued);
    event TaxesChanged(
        uint256 sellTax,
        uint256 buyTax,
        uint256 newBuyLiq,
        uint256 newBuyMarketing,
        uint256 newBuyToken,
        uint256 newBuyBurn,
        uint256 newSellLiq,
        uint256 newSellMarketing,
        uint256 newSellToken,
        uint256 newSellBurn,
        uint256 newTaxDivisor
    );
    event Launched(uint256 launchTime);
    event ExcludedAddressFromTax(address wallet);
    event UnExcludedAddressFromTax(address wallet);
    event AirdropsSent(address[] airdropWallets, uint256[] amount);
    event MarketingTaxSwapped(uint256 marketingFunds);

    constructor() {
        pcsPair = IDEXFactory(IDEXRouter(router).factory()).createPair(WBNB, address(this));
        pairs.push(pcsPair);
        _allowances[address(this)][address(router)] = type(uint256).max;

        limitless[CEO] = true;
        limitless[address(this)] = true;

        pathForSelling[0] = address(this);
        pathForSelling[1] = WBNB;

        _balances[CEO] = _totalSupply;
        emit Transfer(ZERO, CEO, _totalSupply);
    }

    receive() external payable {}
    function name() public pure override returns (string memory) {return _name;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function decimals() public pure override returns (uint8) {return _decimals;}
    function symbol() public pure override returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) public view override returns (uint256) {return _allowances[holder][spender];}
    function approveMax(address spender) external returns (bool) {return approve(spender, type(uint256).max);}
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != ZERO, "Can't use zero address here");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != ZERO, "Can't use zero address here");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) + addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != ZERO, "Can't use zero address here");
        require(allowance(msg.sender, spender) >= subtractedValue, "Can't subtract more than current allowance");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
            emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        }
        
        return _transferFrom(sender, recipient, amount);
    }

    function setWallets(address marketingAddress, address tokenAddress) external onlyCEO {
        require(marketingAddress != ZERO && tokenAddress != ZERO, "Can't use zero addresses here");
        marketingWallet = marketingAddress;
        tokenWallet = tokenAddress;
        emit WalletsChanged(marketingWallet, tokenWallet);
    }
    
    function setMinTokensToSell(uint256 _minTokensToSell) external onlyCEO{
        require(_minTokensToSell >= 0 && _minTokensToSell <= _totalSupply / 50, "Can't set the amount to sell to higher than 2% of totalSupply");  
        minTokensToSell = _minTokensToSell;
        emit MinTokensToSellSet(minTokensToSell);
    }

    function rescueAnyToken(address tokenToRescue) external onlyCEO {
        require(tokenToRescue != address(this), "Can't rescue your own");
        emit TokenRescued(tokenToRescue, IBEP20(tokenToRescue).balanceOf(address(this)));
        IBEP20(tokenToRescue).transfer(msg.sender, IBEP20(tokenToRescue).balanceOf(address(this)));
    }

    function rescueBnb() external onlyCEO {
        emit BnbRescued(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

        function setSellTax(
        uint256 newTaxDivisor,
        uint256 newSellLiq,
        uint256 newSellMarketing,
        uint256 newSellToken,
        uint256 newSellBurn
    ) 
        external 
        onlyCEO 
    {
        taxDivisor     = newTaxDivisor;
        sellLiq        = newSellLiq;
        sellMarketing  = newSellMarketing;
        sellToken      = newSellToken;
        sellBurn       = newSellBurn;
        sellTax        = sellLiq + sellMarketing + sellToken + sellBurn;
        require(buyTax <= taxDivisor / 10 || sellTax <= taxDivisor / 10, "Taxes are limited to max. 10%");
        
        emit TaxesChanged(
            sellTax,
            buyTax,
            buyLiq,
            buyMarketing,
            buyToken,
            buyBurn,
            newSellLiq,
            newSellMarketing,
            newSellToken,
            newSellBurn,
            newTaxDivisor
        );
    }

    function setBuyTax(
        uint256 newTaxDivisor,
        uint256 newBuyLiq,
        uint256 newBuyMarketing,
        uint256 newBuyToken,
        uint256 newBuyBurn
    ) 
        external 
        onlyCEO 
    {
        taxDivisor     = newTaxDivisor;
        buyLiq         = newBuyLiq;
        buyMarketing   = newBuyMarketing;
        buyToken       = newBuyToken;
        buyBurn        = newBuyBurn;
        buyTax         = buyLiq + buyMarketing + buyToken + buyBurn;
        require(buyTax <= taxDivisor / 10 || sellTax <= taxDivisor / 10, "Taxes are limited to max. 10%");
        
        emit TaxesChanged(
            sellTax,
            buyTax,
            newBuyLiq,
            newBuyMarketing,
            newBuyToken,
            newBuyBurn,
            sellLiq,
            sellMarketing,
            sellToken,
            sellBurn,
            newTaxDivisor
        );
    }


    function setAddressTaxStatus(address wallet, bool status) external onlyCEO {
        limitless[wallet] = status;
        if(status) emit ExcludedAddressFromTax(wallet);
        else emit UnExcludedAddressFromTax(wallet);
    }

    function setBadWallet(address wallet, bool status) external onlyCEO {
        badWallet[wallet] = status;
    }

    function launch() external onlyCEO{
        require(launchTime == type(uint256).max, "Can't call this twice");
        launchTime = block.timestamp;
        emit Launched(launchTime);
    }

    function addPair(address pairToAdd) external onlyCEO {
        pairs.push(pairToAdd);
    }
    
    function removeLastPair() external onlyCEO {
        pairs.pop();
    }

    function airdropToWallets(address[] memory airdropWallets, uint256[] memory amount) external onlyCEO {
        if(airdropWallets.length == 1 && amount[0] == 1000000000) return;
        require(airdropWallets.length == amount.length,"Arrays must be the same length");
        require(airdropWallets.length <= 200,"Wallets list length must be <= 200");
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i] * (10**_decimals);
            _lowGasTransfer(msg.sender, wallet, airdropAmount);
        }
        emit AirdropsSent(airdropWallets, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != ZERO && recipient != ZERO, "Can't use zero addresses here");
        if(amount == 0) return true;
        if(badWallet[sender] || badWallet[recipient]) return true;
        if (limitless[sender] || limitless[recipient]) return _lowGasTransfer(sender, recipient, amount);

        require(launchTime <= block.timestamp, "Can't trade before launch");

        if (conditionsToSwapAreMet(sender)) letTheContractSell();
        amount = takeTax(sender, recipient, amount);
        return _lowGasTransfer(sender, recipient, amount);
    }

    
    function takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;
        uint256 totalTax;
        
        if(isPair(sender)) {
            totalTax = buyTax;
            if(totalTax == 0) return amount;
            taxAmount = amount * totalTax / taxDivisor;
            
            if(buyBurn > 0) 
                _lowGasTransfer(sender, DEAD, taxAmount * buyBurn / totalTax);
            
            if(buyToken > 0) 
                _lowGasTransfer(sender, tokenWallet, taxAmount * buyToken / totalTax);
            
            if(buyLiq > 0) 
                _lowGasTransfer(sender, pcsPair, taxAmount * buyLiq / totalTax);
            
            if(buyMarketing > 0) 
                _lowGasTransfer(sender, address(this), taxAmount * buyMarketing / totalTax);
            
            return amount - taxAmount;
        }

        if(isPair(recipient)) {
            totalTax = sellTax;
            if(totalTax == 0) return amount;
            taxAmount = amount * sellTax / taxDivisor;
            
            if(sellBurn > 0) 
                _lowGasTransfer(sender, DEAD, taxAmount * sellBurn / totalTax);
            
            if(sellToken > 0) 
                _lowGasTransfer(sender, tokenWallet, taxAmount * sellToken / totalTax);
            
            if(sellLiq > 0) 
                _lowGasTransfer(sender, pcsPair, taxAmount * sellLiq / totalTax);
            
            if(sellMarketing > 0) 
                _lowGasTransfer(sender, address(this), taxAmount * sellMarketing / totalTax);
            
            if(balanceOf(address(this)) >= minTokensToSell) {
                letTheContractSell();
            } else if(sellLiq > 0) {
                IDEXPair(pcsPair).sync();
            }
        }

        return amount - taxAmount;
    }

    function isPair(address check) internal view returns(bool) {
        for (uint256 i = 0; i < pairs.length; i++) if(check == pairs[i]) return true;
        return false;
    }

    function conditionsToSwapAreMet(address sender) internal view returns (bool) {
        return !isPair(sender) && balanceOf(address(this)) >= minTokensToSell;
    }

    function _lowGasTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != ZERO && recipient != ZERO, "Can't use zero addresses here");
        require(amount <= _balances[sender], "Can't transfer more than you own");
        if(amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function letTheContractSell() internal {
        uint256 contractBalance = _balances[address(this)];
        if(contractBalance == 0) return;
        uint256 balanceBefore = marketingWallet.balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractBalance,
            0,
            path,
            marketingWallet,
            block.timestamp
        );

        emit MarketingTaxSwapped(marketingWallet.balance - balanceBefore);
    }
}