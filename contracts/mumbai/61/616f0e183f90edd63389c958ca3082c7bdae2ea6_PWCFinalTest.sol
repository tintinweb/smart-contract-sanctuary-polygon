//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract PWCFinalTest is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isAuthorized;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromAutoLiquidity;

    address[] private _excluded;
    address public _marketingWallet =
        0x25186fdbd4fa09d15c9f29ea1902EA55F4d4f426;
    address public _burnWallet = 0x000000000000000000000000000000000000dEaD;
    address private burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000 * 10**12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "PWCFinalTest";
    string private _symbol = "PFT";
    uint8 private _decimals = 9;

    uint256 public _sellRewardFee = 3;
    uint256 public _sellLiquidityFee = 2;
    uint256 public _sellMarketingFee = 0;
    uint256 public _sellburnFee = 5;

    uint256 public _buyRewardFee = 3;
    uint256 public _buyLiquidityFee = 2;
    uint256 public _buyMarketingFee = 0;
    uint256 public _buyburnFee = 0;

    uint256 private _totalFeesToContract = 0;
    uint256 private _taxFee = 0;

    uint256 public _swapTokensAt = 100 * 10**6 * 10**9;

    bool tradeEnable = true;
    // auto liquidity
    bool public _swapAndLiquifyEnabled = true;
    bool _inSwapAndLiquify;
    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniswapV2Pair;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor() {

        address newOwner = 0xdaaFB8DBD3eDc6D8745f308B5Fc6a6100B8f98ba;
        _rOwned[newOwner] = _rTotal;

        // uniswap
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        );
        _uniswapV2Router = uniswapV2Router;
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        // exclude system contracts
        _isExcludedFromFee[newOwner] = true;
        _isExcludedFromFee[address(this)] = true;

        // authorized to do transactions before add liquidity
        _isAuthorized[newOwner] = true;

        _isExcludedFromAutoLiquidity[_uniswapV2Pair] = true;
        _isExcludedFromAutoLiquidity[address(_uniswapV2Router)] = true;


        emit Transfer(address(0), newOwner, _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );

        (, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, , ) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            currentRate
        );

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();

        if (!deductTransferFee) {
            (uint256 rAmount, , ) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                currentRate
            );
            return rAmount;
        } else {
            (, uint256 rTransferAmount, ) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                currentRate
            );
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setMarketingWallet(address marketingWallet) external onlyOwner {
        _marketingWallet = marketingWallet;
    }

    function setburnWallet(address newWallet) external onlyOwner {
        _burnWallet = newWallet;
    }

    function changeSwapAmount(uint256 amount) external onlyOwner {
        _swapTokensAt = amount * 10**9;
    }

    function setExcludedFromFee(address account, bool e) external onlyOwner {
        _isExcludedFromFee[account] = e;
    }

    function tradingEnable(bool status) external onlyOwner {
        tradeEnable = status;
    }

    // update fees
    function updateBuyFees(
        uint256 rewardFee,
        uint256 liquidityFee,
        uint256 marketingFee,
        uint256 teamFee
    ) external onlyOwner {
        _buyRewardFee = rewardFee;
        _buyLiquidityFee = liquidityFee;
        _buyMarketingFee = marketingFee;
        _buyburnFee = teamFee;
    }
     function updateSellFees(
        uint256 rewardFee,
        uint256 liquidityFee,
        uint256 marketingFee,
        uint256 teamFee
    ) external onlyOwner {
        _sellRewardFee = rewardFee;
        _sellLiquidityFee = liquidityFee;
        _sellMarketingFee = marketingFee;
        _sellburnFee = teamFee;
    }

    function setSwapAndLiquifyEnabled(bool e) public onlyOwner {
        _swapAndLiquifyEnabled = e;
        emit SwapAndLiquifyEnabledUpdated(e);
    }

    receive() external payable {}

    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(r);
        _uniswapV2Router = uniswapV2Router;
    }

    function setUniswapPair(address p) external onlyOwner {
        _uniswapV2Pair = p;
    }

    function setAuthorizedWallets(address wallet, bool status)
        external
        onlyOwner
    {
        _isAuthorized[wallet] = status;
    }

    function setExcludedFromAutoLiquidity(address a, bool b)
        external
        onlyOwner
    {
        _isExcludedFromAutoLiquidity[a] = b;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateFee(tAmount, _taxFee);
        uint256 tLiquidity = calculateFee(tAmount, _totalFeesToContract);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function takeTokenFees(uint256 tokenAmount, uint256 currentRate,address from) private {
        if (tokenAmount <= 0) {
            return;
        }
        // send tokens to contract
        takeTransactionFee(address(this), tokenAmount, currentRate);
        emit Transfer(from, address(this), tokenAmount);
    }

    function takeTransactionFee(
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        if (tAmount <= 0) {
            return;
        }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
         
    }

    function calculateFee(uint256 amount, uint256 fee)
        private
        pure
        returns (uint256)
    {
        return amount.mul(fee).div(100);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if ((to == _uniswapV2Pair || from == _uniswapV2Pair) && !tradeEnable) {
            require(
                (_isAuthorized[to] || _isAuthorized[from]),
                "Trading not enabled yet."
            );
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */
        uint256 contractTokenBalance = balanceOf(address(this));

        bool isOverMinTokenBalance = contractTokenBalance >= _swapTokensAt;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromAutoLiquidity[from] &&
            _swapAndLiquifyEnabled
        ) {
            // contractTokenBalance = _swapTokensAt;
            swapAndSendBnb(contractTokenBalance);
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndSendBnb(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalSwapFees = _buyLiquidityFee.add(_buyMarketingFee).add(_buyburnFee);
        uint256 tokensToAddLiquidity = contractTokenBalance
            .mul(_buyLiquidityFee)
            .div(totalSwapFees);
        uint256 tokensToSwap = contractTokenBalance.sub(tokensToAddLiquidity);
        // swap tokens in to bnb
        swapTokensForBnb(tokensToSwap);

        uint256 swappedBnb = address(this).balance;
        uint256 bnbForCoverGasFees = swappedBnb.mul(10).div(100);
        uint256 bnbForDistribute = swappedBnb.sub(bnbForCoverGasFees);
        // calculate total bnb ratio
        uint256 totalBnbRatio = totalSwapFees.sub(_buyLiquidityFee);
        uint256 bnbToMarketing = bnbForDistribute.mul(_buyMarketingFee).div(
            totalBnbRatio
        );
        uint256 bnbToTeam = bnbForDistribute.mul(_buyburnFee).div(totalBnbRatio);

        // send bnb to marketing wallet
        payable(_marketingWallet).transfer(bnbToMarketing);
        payable(_burnWallet).transfer(bnbToTeam);
        // add liquidity
        swapAndLiquify(tokensToAddLiquidity);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if(recipient == _uniswapV2Pair)
        {
         _taxFee = _sellRewardFee;
        _totalFeesToContract = _sellLiquidityFee.add(_sellMarketingFee).add(_sellburnFee);
        }
        else{
        _taxFee = _buyRewardFee;
        _totalFeesToContract = _buyLiquidityFee.add(_buyMarketingFee).add(_buyburnFee);
        }
       
        if (!takeFee) {
           _taxFee = 0;
            _totalFeesToContract = 0;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (takeFee) {
            _taxFee = 0;
            _totalFeesToContract = 0;
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            currentRate
        );
        _reflectFee(rFee, tFee);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTokenFees(tLiquidity, currentRate,sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            currentRate
        );

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTokenFees(tLiquidity, currentRate,sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            currentRate
        );

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTokenFees(tLiquidity, currentRate,sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            currentRate
        );

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTokenFees(tLiquidity, currentRate,sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}