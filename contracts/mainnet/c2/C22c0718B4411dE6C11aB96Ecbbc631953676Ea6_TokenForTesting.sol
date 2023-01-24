// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IFactoryV2 {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address lpPair,
        uint
    );

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address lpPair);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract TokenForTesting is IERC20 {
    mapping(address => uint256) public _refBalance;
    mapping(address => uint256) public _tokenBalance;
    mapping(address => bool) public lpPairs;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => bool) public _liquidityHolders;
    mapping(address => bool) public _isExcludedFromProtection;
    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isExcludedFromReflection;
    mapping(address => bool) public _isExcludedFromLimits;
    mapping(address => bool) public _isBlacklisted;
    address[] public _refExclusionList;
    mapping(address => bool) public presaleAddresses;

    string private constant _name = "TestToken_7";
    string private constant _symbol = "TST_7";
    uint8 private constant _decimals = 9;
    uint256 private constant _tokenTotalSupply = 900_000_000 * 10 ** _decimals;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _refTotal = (MAX - (MAX % _tokenTotalSupply));

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 reflection;
        uint16 liquidity;
        uint16 marketing;
        uint16 development;
        uint16 charity;
        uint16 buyback;
        uint16 totalSwap;
    }

    Fees public _taxRates = Fees({buyFee: 400, sellFee: 500, transferFee: 0});

    Ratios public _ratios =
        Ratios({
            reflection: 90 * 1, // 10%
            liquidity: 90 * 2, // 20%
            marketing: 90 * 2, // 20%
            development: 90 * 1, // 10%
            charity: 90 * 2, // 20%
            buyback: 90 * 2, // 20%
            totalSwap: 90 * (2 + 2 + 1 + 2 + 2)
        });

    // maximum limit of taxes
    uint256 public constant maxBuyTaxes = 2000; // 20%
    uint256 public constant maxSellTaxes = 2000; // 20%
    uint256 public constant maxTransferTaxes = 2000; // 20%
    uint256 constant masterTaxDivisor = 10000;

    bool public taxesAreLocked;

    IRouter02 public dexRouter;
    address public lpPair;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address payable marketing;
        address payable development;
        address payable charity;
        address payable buyback;
    }

    TaxWallets public _taxWallets =
        TaxWallets({
            marketing: payable(0x6B4b39F11B3b0E9E1b15aCB5244010d949a19b6B),
            development: payable(0xdDaFa704EB9991B04edA78802A288AB8C6eDda4e),
            charity: payable(0x7F47A2afC96d640fE260b30c1ee90977962319a2),
            buyback: payable(0x3cD82E844080e912d09021F42A6937C8152020FC)
        });

    bool inSwap;

    // is swapping ability enabled in contract?
    bool public contractSwapEnabled = false;
    //
    uint256 public swapThreshold;
    //
    uint256 public swapAmount;

    // should enable price impacted swap ?
    bool public piContractSwapsEnabled;
    // price impact swap percent
    uint256 public piSwapPercent = 10;

    uint256 private _maxTxAmount = (_tokenTotalSupply * 2) / 100; // 2%
    uint256 private _maxWalletSize = (_tokenTotalSupply * 2) / 100; // 2%

    // is trading enabled?
    bool public tradingEnabled = false;
    // is liquidity added?
    bool public _hasLiqBeenAdded = false;

    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);

    modifier inSwapFlag() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() payable {
        _owner = msg.sender;

        _refBalance[_owner] = _refTotal;
        emit Transfer(address(0), _owner, _tokenTotalSupply);

        if (block.chainid == 137) {
            dexRouter = IRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        } else if (block.chainid == 80001) {
            dexRouter = IRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        } else if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        } else if (
            block.chainid == 1 ||
            block.chainid == 3 ||
            block.chainid == 4 ||
            block.chainid == 5
        ) {
            dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            //Ropstein DAI 0xaD6D458402F60fD3Bd25163575031ACDce07538D
        } else if (block.chainid == 43114) {
            dexRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        } else if (block.chainid == 250) {
            dexRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        } else {
            revert("Unsupported network");
        }

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[_owner] = true;
    }

    receive() external payable {}

    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not owner.");
        _;
    }
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function transferOwner(address newOwner) external onlyOwner {
        require(
            newOwner != address(0) && newOwner != DEAD,
            "Can not transfer ownership to these addresses"
        );
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);

        if (balanceOf(_owner) > 0) {
            finalizeTransfer(
                _owner,
                newOwner,
                balanceOf(_owner),
                false,
                false,
                true
            );
        }

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function totalSupply() external pure override returns (uint256) {
        if (_tokenTotalSupply == 0) {
            revert();
        }
        return _tokenTotalSupply;
    }

    function decimals() external pure override returns (uint8) {
        if (_tokenTotalSupply == 0) {
            revert();
        }
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return _owner;
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReflection[account]) return _tokenBalance[account];
        return tokenFromReflection(_refBalance[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() external onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setDexRouter(address newRouter) external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot change after liquidity.");
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(
            address(this),
            _newRouter.WETH()
        );
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(
                address(this),
                _newRouter.WETH()
            );
        } else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        lpPairs[lpPair] = true;

        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (!enabled) {
            lpPairs[pair] = false;
        } else {
            lpPairs[pair] = true;
        }
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromProtection(
        address account
    ) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function isExcludedFromLimits(
        address account
    ) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function setExcludedFromFees(
        address account,
        bool enabled
    ) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function setExcludedFromProtection(
        address account,
        bool enabled
    ) external onlyOwner {
        _isExcludedFromProtection[account] = enabled;
    }

    function setExcludedFromLimits(
        address account,
        bool enabled
    ) public onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tokenTotalSupply - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function setBlacklistEnabled(
        address account,
        bool enabled
    ) external onlyOwner {
        _isBlacklisted[account] = enabled;
    }

    function setBlacklistEnabledMultiple(
        address[] memory accounts,
        bool enabled
    ) external onlyOwner {
        for (uint16 i = 0; i < accounts.length; i++) {
            _isBlacklisted[accounts[i]] = enabled;
        }
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    function lockTaxes() external onlyOwner {
        taxesAreLocked = true;
    }

    function setTaxes(
        uint16 buyFee,
        uint16 sellFee,
        uint16 transferFee
    ) external onlyOwner {
        require(!taxesAreLocked, "Taxes are locked.");
        require(
            buyFee <= maxBuyTaxes &&
                sellFee <= maxSellTaxes &&
                transferFee <= maxTransferTaxes,
            "Cannot exceed maximums."
        );
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(
        uint16 reflection,
        uint16 liquidity,
        uint16 charity,
        uint16 development,
        uint16 marketing,
        uint16 buyback
    ) external onlyOwner {
        _ratios.reflection = reflection;
        _ratios.liquidity = liquidity;
        _ratios.marketing = marketing;
        _ratios.charity = charity;
        _ratios.development = development;
        _ratios.buyback = buyback;
        _ratios.totalSwap =
            liquidity +
            marketing +
            charity +
            development +
            buyback;
        uint256 total = _taxRates.buyFee + _taxRates.sellFee;
        require(
            _ratios.totalSwap + _ratios.reflection <= total,
            "Cannot exceed sum of buy and sell fees."
        );
    }

    function setWallets(
        address payable marketing,
        address payable charity,
        address payable development,
        address payable buyback
    ) external onlyOwner {
        require(
            marketing != address(0) &&
                development != address(0) &&
                charity != address(0) &&
                buyback != address(0),
            "Cannot be zero address."
        );
        _taxWallets.marketing = payable(marketing);
        _taxWallets.development = payable(development);
        _taxWallets.charity = payable(charity);
        _taxWallets.buyback = payable(buyback);
    }

    function setMaxTxPercent(
        uint256 percent,
        uint256 divisor
    ) external onlyOwner {
        require(
            (_tokenTotalSupply * percent) / divisor >=
                ((_tokenTotalSupply * 5) / 1000),
            "Max Transaction amt must be above 0.5% of total supply."
        );
        _maxTxAmount = (_tokenTotalSupply * percent) / divisor;
    }

    function setMaxWalletSize(
        uint256 percent,
        uint256 divisor
    ) external onlyOwner {
        require(
            (_tokenTotalSupply * percent) / divisor >=
                (_tokenTotalSupply / 100),
            "Max Wallet amt must be above 1% of total supply."
        );
        _maxWalletSize = (_tokenTotalSupply * percent) / divisor;
    }

    function getMaxTX() external view returns (uint256) {
        return _maxTxAmount / (10 ** _decimals);
    }

    function getMaxWallet() external view returns (uint256) {
        return _maxWalletSize / (10 ** _decimals);
    }

    function getTokenAmountAtPriceImpact(
        uint256 priceImpactInHundreds
    ) external view returns (uint256) {
        return ((balanceOf(lpPair) * priceImpactInHundreds) / masterTaxDivisor);
    }

    function setSwapSettings(
        uint256 thresholdPercent,
        uint256 thresholdDivisor,
        uint256 amountPercent,
        uint256 amountDivisor
    ) external onlyOwner {
        swapThreshold =
            (_tokenTotalSupply * thresholdPercent) /
            thresholdDivisor;
        swapAmount = (_tokenTotalSupply * amountPercent) / amountDivisor;
        require(
            swapThreshold <= swapAmount,
            "Threshold cannot be above amount."
        );
        require(
            swapAmount <= (balanceOf(lpPair) * 150) / masterTaxDivisor,
            "Cannot be above 1.5% of current PI."
        );
        require(
            swapAmount >= _tokenTotalSupply / 1_000_000,
            "Cannot be lower than 0.00001% of total supply."
        );
        require(
            swapThreshold >= _tokenTotalSupply / 1_000_000,
            "Cannot be lower than 0.00001% of total supply."
        );
    }

    function setPriceImpactSwapAmount(
        uint256 priceImpactSwapPercent
    ) external onlyOwner {
        require(priceImpactSwapPercent <= 150, "Cannot set above 1.5%.");
        piSwapPercent = priceImpactSwapPercent;
    }

    function setContractSwapEnabled(
        bool swapEnabled,
        bool priceImpactSwapEnabled
    ) external onlyOwner {
        contractSwapEnabled = swapEnabled;
        piContractSwapsEnabled = priceImpactSwapEnabled;
        emit ContractSwapEnabledUpdated(swapEnabled);
    }

    function excludePresaleAddress(address presale) external onlyOwner {
        require(presale != address(this) && lpPair != presale, "Just don't.");

        _liquidityHolders[presale] = true;
        presaleAddresses[presale] = true;
        setExcludedFromFees(presale, true);
        setExcludedFromReflection(presale, true);
        setExcludedFromLimits(presale, true);
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return
            from != _owner &&
            to != _owner &&
            tx.origin != _owner &&
            !_liquidityHolders[to] &&
            !_liquidityHolders[from] &&
            to != DEAD &&
            to != address(0) &&
            from != address(this);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _isBlacklisted[from] == false,
            "ERC20: transfer from blacklisted address"
        );
        require(
            _isBlacklisted[to] == false,
            "ERC20: transfer to blacklisted address"
        );

        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;
        if (lpPairs[from]) {
            buy = true;
        } else if (lpPairs[to]) {
            sell = true;
        } else {
            other = true;
        }
        if (_hasLimits(from, to)) {
            if (!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if (buy || sell) {
                if (
                    !_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]
                ) {
                    require(
                        amount <= _maxTxAmount,
                        "Transfer amount exceeds the maxTxAmount."
                    );
                }
            }
            if (to != address(dexRouter) && !sell) {
                if (!_isExcludedFromLimits[to] && !presaleAddresses[from]) {
                    require(
                        balanceOf(to) + amount <= _maxWalletSize,
                        "Transfer amount exceeds the maxWalletSize."
                    );
                }
            }
        }

        if (sell) {
            if (!inSwap) {
                if (
                    contractSwapEnabled &&
                    !presaleAddresses[to] &&
                    !presaleAddresses[from]
                ) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        uint256 swapAmt = swapAmount;
                        if (piContractSwapsEnabled) {
                            swapAmt =
                                (balanceOf(lpPair) * piSwapPercent) /
                                masterTaxDivisor;
                        }
                        if (contractTokenBalance >= swapAmt) {
                            contractTokenBalance = swapAmt;
                        }
                        contractSwap(contractTokenBalance);
                    }
                }
            }
        }
        return finalizeTransfer(from, to, amount, buy, sell, other);
    }

    function contractSwap(uint256 contractTokenBalance) internal inSwapFlag {
        Ratios memory ratios = _ratios;
        if (ratios.totalSwap == 0) {
            return;
        }

        if (
            _allowances[address(this)][address(dexRouter)] != type(uint256).max
        ) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) /
            ratios.totalSwap) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        try
            dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmt,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            return;
        }

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            try
                dexRouter.addLiquidityETH{value: liquidityBalance}(
                    address(this),
                    toLiquify,
                    0,
                    0,
                    DEAD,
                    block.timestamp
                )
            {
                emit AutoLiquify(liquidityBalance, toLiquify);
            } catch {
                return;
            }
        } // totalSwap = liquidity + dev + mar + char + buyback

        amtBalance -= liquidityBalance;
        ratios.totalSwap -= ratios.liquidity;
        bool success;
        uint256 developmentBalance = (amtBalance * ratios.development) /
            ratios.totalSwap;
        uint256 marketingBalance = (amtBalance * ratios.marketing) /
            ratios.totalSwap;
        uint256 charityBalance = (amtBalance * ratios.charity) /
            ratios.totalSwap;
        uint256 buybackBalance = amtBalance -
            developmentBalance -
            marketingBalance -
            charityBalance;
        if (ratios.development > 0) {
            (success, ) = _taxWallets.development.call{
                value: developmentBalance,
                gas: 55000
            }("");
        }
        if (ratios.marketing > 0) {
            (success, ) = _taxWallets.marketing.call{
                value: marketingBalance,
                gas: 55000
            }("");
        }
        if (ratios.charity > 0) {
            (success, ) = _taxWallets.charity.call{
                value: charityBalance,
                gas: 55000
            }("");
        }
        if (ratios.buyback > 0) {
            (success, ) = _taxWallets.buyback.call{
                value: buybackBalance,
                gas: 55000
            }("");
        }
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _isExcludedFromFees[from] = true;
            _hasLiqBeenAdded = true;
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        tradingEnabled = true;
        swapThreshold = (balanceOf(lpPair) * 10) / 10000;
        swapAmount = (balanceOf(lpPair) * 30) / 10000;
    }

    function batchSender(
        address[] memory accounts,
        uint256[] memory amounts
    ) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint16 i = 0; i < accounts.length; i++) {
            require(
                balanceOf(msg.sender) >= amounts[i] * 10 ** _decimals,
                "Not enough tokens."
            );
            finalizeTransfer(
                msg.sender,
                accounts[i],
                amounts[i] * 10 ** _decimals,
                false,
                false,
                true
            );
        }
    }

    function isExcludedFromReflection(
        address account
    ) public view returns (bool) {
        return _isExcludedFromReflection[account];
    }

    function setExcludedFromReflection(
        address account,
        bool enabled
    ) public onlyOwner {
        if (enabled) {
            if (_isExcludedFromReflection[account]) {
                return; // "Account is already excluded."
            }
            if (_refBalance[account] > 0) {
                _tokenBalance[account] = tokenFromReflection(
                    _refBalance[account]
                );
            }
            _isExcludedFromReflection[account] = true;
            if (account != lpPair) {
                _refExclusionList.push(account);
            }
        } else if (!enabled) {
            if (!_isExcludedFromReflection[account]) {
                return; // "Account is already excluded."
            }
            if (account == lpPair) {
                _refBalance[account] = _tokenBalance[account] * _getRate();
                _tokenBalance[account] = 0;
                _isExcludedFromReflection[account] = false;
            } else if (_refExclusionList.length == 1) {
                _refBalance[account] = _tokenBalance[account] * _getRate();
                _tokenBalance[account] = 0;
                _isExcludedFromReflection[account] = false;
                _refExclusionList.pop();
            } else {
                for (uint256 i = 0; i < _refExclusionList.length; i++) {
                    if (_refExclusionList[i] == account) {
                        _refExclusionList[i] = _refExclusionList[
                            _refExclusionList.length - 1
                        ];
                        _refBalance[account] =
                            _tokenBalance[account] *
                            _getRate();
                        _tokenBalance[account] = 0;
                        _isExcludedFromReflection[account] = false;
                        _refExclusionList.pop();
                        break;
                    }
                }
            }
        }
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _refTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    struct ExtraValues {
        uint256 tokenTransferAmount;
        uint256 tokenFee;
        uint256 tokenSwap;
        uint256 refTransferAmount;
        uint256 refAmount;
        uint256 refFee;
        uint256 currentRate;
    }

    function finalizeTransfer(
        address from,
        address to,
        uint256 tAmount,
        bool buy,
        bool sell,
        bool other
    ) internal returns (bool) {
        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        ExtraValues memory values = takeTaxes(
            from,
            tAmount,
            takeFee,
            buy,
            sell
        );

        _refBalance[from] = _refBalance[from] - values.refAmount;
        _refBalance[to] = _refBalance[to] + values.refTransferAmount;

        if (_isExcludedFromReflection[from]) {
            _tokenBalance[from] = _tokenBalance[from] - tAmount;
        }
        if (_isExcludedFromReflection[to]) {
            _tokenBalance[to] = _tokenBalance[to] + values.tokenTransferAmount;
        }

        if (values.refFee > 0 || values.tokenFee > 0) {
            _refTotal -= values.refFee;
        }
        emit Transfer(from, to, values.tokenTransferAmount);
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (
                !_hasLiqBeenAdded &&
                _hasLimits(from, to) &&
                !_isExcludedFromProtection[from] &&
                !_isExcludedFromProtection[to] &&
                !other
            ) {
                // can not
                revert("Pre-liquidity transfer protection.");
            }
        }

        return true;
    }

    function takeTaxes(
        address from,
        uint256 tAmount,
        bool takeFee,
        bool buy,
        bool sell
    ) internal returns (ExtraValues memory) {
        ExtraValues memory values;
        Ratios memory ratios = _ratios;
        values.currentRate = _getRate();

        values.refAmount = tAmount * values.currentRate;

        uint256 total = ratios.totalSwap + ratios.reflection;
        if (total == 0) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 currentFee;

            if (buy) {
                currentFee = _taxRates.buyFee;
            } else if (sell) {
                currentFee = _taxRates.sellFee;
            } else {
                currentFee = _taxRates.transferFee;
            }

            uint256 feeAmount = (tAmount * currentFee) / masterTaxDivisor;
            values.tokenFee = (feeAmount * ratios.reflection) / total; // reflection fee
            values.tokenSwap = feeAmount - values.tokenFee;
            values.tokenTransferAmount =
                tAmount -
                (values.tokenFee + values.tokenSwap);

            values.refFee = values.tokenFee * values.currentRate;
        } else {
            values.tokenTransferAmount = tAmount;
        }

        if (values.tokenSwap > 0) {
            _refBalance[address(this)] += values.tokenSwap * values.currentRate;
            if (_isExcludedFromReflection[address(this)]) {
                _tokenBalance[address(this)] += values.tokenSwap;
            }
            emit Transfer(from, address(this), values.tokenSwap);
        }

        values.refTransferAmount =
            values.refAmount -
            (values.refFee + (values.tokenSwap * values.currentRate));
        return values;
    }

    function _getRate() internal view returns (uint256) {
        uint256 rTotal = _refTotal;
        uint256 tTotal = _tokenTotalSupply;
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;
        if (_isExcludedFromReflection[lpPair]) {
            uint256 rLPOwned = _refBalance[lpPair];
            uint256 tLPOwned = _tokenBalance[lpPair];
            if (rLPOwned > rSupply || tLPOwned > tSupply)
                return rTotal / tTotal;
            rSupply -= rLPOwned;
            tSupply -= tLPOwned;
        }
        if (_refExclusionList.length > 0) {
            for (uint8 i = 0; i < _refExclusionList.length; i++) {
                uint256 rOwned = _refBalance[_refExclusionList[i]];
                uint256 tOwned = _tokenBalance[_refExclusionList[i]];
                if (rOwned > rSupply || tOwned > tSupply)
                    return rTotal / tTotal;
                rSupply = rSupply - rOwned;
                tSupply = tSupply - tOwned;
            }
        }
        if (rSupply < rTotal / tTotal) return rTotal / tTotal;
        return rSupply / tSupply;
    }
}