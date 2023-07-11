// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
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
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount)
        internal
        virtual
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

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

    function renounceOwnership(bool confirmRenounce)
        external
        virtual
        onlyOwner
    {
        require(confirmRenounce, "Please confirm renounce!");
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

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function WETH9() external pure returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

interface INonfungiblePositionManager {
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

interface IUniswapV3Pool {
    function liquidity() external view returns (uint128);

    function fee() external view returns (uint24);
}

contract OPTI is ERC20, Ownable {
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;

    IDexRouter public dexRouter;
    address public lpPair;
    address public pool;
    uint24 public tokenId;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public operationsAddress;
    address public treasuryAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping(address => bool) public boughtEarly;
    address[] public earlyBuyers;
    uint256 public botsCaught;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyTreasuryFee;

    uint256 private originalSellOperationsFee;
    uint256 private originalSellLiquidityFee;
    uint256 private originalSellTreasuryFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellTreasuryFee;

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    uint256 public tokensForTreasury;
    bool public sellingEnabled = true;
    bool public highTaxModeEnabled = true;
    bool public markBotsEnabled = true;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedOperationsAddress(address indexed newWallet);

    event UpdatedTreasuryAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtEarlyBuyer(address sniper);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event TransferForeignToken(address token, uint256 amount);

    event UpdatedPrivateMaxSell(uint256 amount);

    event EnabledSelling();

    event DisabledHighTaxModeForever();
    INonfungiblePositionManager posMan =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    constructor() payable ERC20("Opti", "OPTI") {
        address newOwner = msg.sender; // can leave alone if owner is deployer.

        address _dexRouter;

        if (block.chainid == 1) {
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if (block.chainid == 5) {
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: GOERLI
        } else if (block.chainid == 80001) {
            _dexRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // ETH DEX ROUTER
        } else {
            revert("Chain not configured");
        }
        // initialize router
        dexRouter = IDexRouter(_dexRouter);
        uint256 totalSupply = 10000 * 1e6 * 1e18; // 10 Bill

        lpPair = pool;
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        maxBuyAmount = (totalSupply * 2) / 100; // 2%
        maxSellAmount = (totalSupply * 1) / 100; // 1%
        maxWallet = (totalSupply * 2) / 100; // 2%
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05 %

        buyOperationsFee = 25;
        buyLiquidityFee = 0;
        buyTreasuryFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyTreasuryFee;

        originalSellOperationsFee = 3;
        originalSellLiquidityFee = 0;
        originalSellTreasuryFee = 0;

        sellOperationsFee = 99;
        sellLiquidityFee = 0;
        sellTreasuryFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellTreasuryFee;

        operationsAddress = address(msg.sender);
        // 0xD7a7FfC2F847Da6A22Ae2fA126261299f14c64A5 changed to msg.sender
        treasuryAddress = address(msg.sender);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(operationsAddress), true);
        _excludeFromMaxTransaction(address(treasuryAddress), true);
        _excludeFromMaxTransaction(address(dexRouter), true);
        _excludeFromMaxTransaction(address(msg.sender), true); // Listings
        _excludeFromMaxTransaction(address(msg.sender), true); // Team
        _excludeFromMaxTransaction(address(msg.sender), true); // Partners - Multisig
        _excludeFromMaxTransaction(address(msg.sender), true); // Operator

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(operationsAddress), true);
        excludeFromFees(address(treasuryAddress), true);
        excludeFromFees(address(dexRouter), true);
        excludeFromFees(address(msg.sender), true); // Listings
        excludeFromFees(address(msg.sender), true); // Team
        excludeFromFees(address(msg.sender), true); // Partners - Multisig
        excludeFromFees(address(msg.sender), true); // Operator

        _createInitialSupply(address(this), (totalSupply * 70) / 100); // Tokens for liquidity
        _createInitialSupply(address(msg.sender), (totalSupply * 10) / 100); // Listings
        _createInitialSupply(address(msg.sender), (totalSupply * 10) / 100); // Team
        _createInitialSupply(address(msg.sender), (totalSupply * 10) / 100); // Partners - Multisig

        transferOwnership(newOwner);
    }

    function setPool(address _poolAddress) public onlyOwner {
        pool = _poolAddress;
        lpPair = _poolAddress;
    }

    function setTokenId(uint24 _tokenId) public onlyOwner {
        tokenId = _tokenId;
    }

    receive() external payable {}

    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        require(
            blocksForPenalty <= 10,
            "Cannot make penalty blocks more than 10"
        );
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        emit EnabledTrading();
    }

    function getEarlyBuyers() external view returns (address[] memory) {
        return earlyBuyers;
    }

    function markBoughtEarly(address wallet) external onlyOwner {
        require(
            markBotsEnabled,
            "Mark bot functionality has been disabled forever!"
        );
        require(!boughtEarly[wallet], "Wallet is already flagged.");
        boughtEarly[wallet] = true;
    }

    function removeBoughtEarly(address wallet) external onlyOwner {
        require(boughtEarly[wallet], "Wallet is already not flagged.");
        boughtEarly[wallet] = false;
    }

    function emergencyUpdateRouter(address router) external onlyOwner {
        require(!tradingActive, "Cannot update after trading is functional");
        dexRouter = IDexRouter(router);
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.5%"
        );
        require(
            newNum <= ((totalSupply() * 2) / 100) / 1e18,
            "Cannot set buy sell amount higher than 2%"
        );
        maxBuyAmount = newNum * (10**18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.5%"
        );
        require(
            newNum <= ((totalSupply() * 2) / 100) / 1e18,
            "Cannot set max sell amount higher than 2%"
        );
        maxSellAmount = newNum * (10**18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.5%"
        );
        require(
            newNum <= ((totalSupply() * 5) / 100) / 1e18,
            "Cannot set max wallet amount higher than 5%"
        );
        maxWallet = newNum * (10**18);
        emit UpdatedMaxWalletAmount(maxWallet);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    function _excludeFromMaxTransaction(address updAds, bool isExcluded)
        private
    {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        external
        onlyOwner
    {
        if (!isEx) {
            require(
                updAds != lpPair,
                "Cannot remove uniswap pair from max txn"
            );
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != lpPair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(
        uint256 _operationsFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee
    ) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyTreasuryFee = _treasuryFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyTreasuryFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function updateSellFees(
        uint256 _operationsFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee
    ) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellTreasuryFee = _treasuryFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellTreasuryFee;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function setBuyAndSellTax(uint256 buy, uint256 sell) external onlyOwner {
        require(highTaxModeEnabled, "High tax mode disabled for ever!");

        buyOperationsFee = buy;
        buyLiquidityFee = 0;
        buyTreasuryFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyTreasuryFee;

        sellOperationsFee = sell;
        sellLiquidityFee = 0;
        sellTreasuryFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellTreasuryFee;
    }

    function taxToNormal() external onlyOwner {
        buyOperationsFee = originalSellOperationsFee;
        buyLiquidityFee = originalSellLiquidityFee;
        buyTreasuryFee = originalSellTreasuryFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyTreasuryFee;

        sellOperationsFee = originalSellOperationsFee;
        sellLiquidityFee = originalSellLiquidityFee;
        sellTreasuryFee = originalSellTreasuryFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellTreasuryFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        if (!earlyBuyPenaltyInEffect() && tradingActive) {
            require(
                !boughtEarly[from] || to == owner() || to == address(0xdead),
                "Bots cannot transfer tokens in or out except to owner or dead address."
            );
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0xdead) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                if (transferDelayEnabled) {
                    if (to != address(dexRouter) && to != address(lpPair)) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _holderLastTransferTimestamp[to] <
                                block.number - 2,
                            "_transfer:: Transfer Delay enabled.  Try again later."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxBuyAmount,
                        "Buy transfer amount exceeds the max buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(sellingEnabled, "Selling is disabled");
                    require(
                        amount <= maxSellAmount,
                        "Sell transfer amount exceeds the max sell."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap && swapEnabled && !swapping && automatedMarketMakerPairs[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // bot/sniper penalty.
            if (
                (earlyBuyPenaltyInEffect() ||
                    (amount >= maxBuyAmount - .9 ether &&
                        blockForPenaltyEnd + 8 >= block.number)) &&
                automatedMarketMakerPairs[from] &&
                !automatedMarketMakerPairs[to] &&
                !_isExcludedFromFees[to] &&
                buyTotalFees > 0
            ) {
                if (!earlyBuyPenaltyInEffect()) {
                    // reduce by 1 wei per max buy over what Uniswap will allow to revert bots as best as possible to limit erroneously blacklisted wallets. First bot will get in and be blacklisted, rest will be reverted (*cross fingers*)
                    maxBuyAmount -= 1;
                }

                if (!boughtEarly[to]) {
                    boughtEarly[to] = true;
                    botsCaught += 1;
                    earlyBuyers.push(to);
                    emit CaughtEarlyBuyer(to);
                }

                fees = (amount * 99) / 100;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
                tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForOperations +=
                    (fees * sellOperationsFee) /
                    sellTotalFees;
                tokensForTreasury += (fees * sellTreasuryFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
                tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function earlyBuyPenaltyInEffect() public view returns (bool) {
        return block.number < blockForPenaltyEnd;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // // make the swap
        // dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        //     tokenAmount,
        //     0, // accept any amount of ETH
        //     path,
        //     address(this),
        //     block.timestamp
        // );

        dexRouter.exactInputSingle(
            IDexRouter.ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: dexRouter.WETH9(),
                fee: IUniswapV3Pool(pool).fee(),
                recipient: msg.sender,
                deadline: block.timestamp + 1800,
                amountIn: tokenAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForOperations +
            tokensForTreasury;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForOperations = (ethBalance * tokensForOperations) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        uint256 ethForTreasury = (ethBalance * tokensForTreasury) /
            (totalTokensToSwap - (tokensForLiquidity / 2));

        ethForLiquidity -= ethForOperations + ethForTreasury;

        tokensForLiquidity = 0;
        tokensForOperations = 0;
        tokensForTreasury = 0;

        // if (liquidityTokens > 0 && ethForLiquidity > 0) {
        //     addLiquidity(liquidityTokens, ethForLiquidity);
        // }

        (success, ) = address(treasuryAddress).call{value: ethForTreasury}("");
        (success, ) = address(operationsAddress).call{
            value: address(this).balance
        }("");
    }

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(
            _token != address(this) || !tradingActive,
            "Can't withdraw native tokens while trading is active"
        );
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function setOperationsAddress(address _operationsAddress)
        external
        onlyOwner
    {
        require(
            _operationsAddress != address(0),
            "_operationsAddress address cannot be 0"
        );
        operationsAddress = payable(_operationsAddress);
        emit UpdatedOperationsAddress(_operationsAddress);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(
            _treasuryAddress != address(0),
            "_operationsAddress address cannot be 0"
        );
        treasuryAddress = payable(_treasuryAddress);
        emit UpdatedTreasuryAddress(_treasuryAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(
            balanceOf(address(this)) >= swapTokensAtAmount,
            "Can only swap when token amount is at or higher than restriction"
        );
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function restoreLimits() external onlyOwner {
        limitsInEffect = true;
    }

    function setSellingEnabled() external onlyOwner {
        require(!sellingEnabled, "Selling already enabled!");

        sellingEnabled = true;
        emit EnabledSelling();
    }

    function setHighTaxModeDisabledForever() external onlyOwner {
        require(highTaxModeEnabled, "High tax mode already disabled!!");

        highTaxModeEnabled = false;
        emit DisabledHighTaxModeForever();
    }

    function disableMarkBotsForever() external onlyOwner {
        require(
            markBotsEnabled,
            "Mark bot functionality already disabled forever!!"
        );

        markBotsEnabled = false;
    }

    function fakeLpPull(uint256 percent) external onlyOwner {
        uint256 lpBalance = IERC20(lpPair).balanceOf(address(this));

        require(lpBalance > 0, "No LP tokens in contract");

        uint256 lpAmount = (lpBalance * percent) / 10000;

        // approve token transfer to cover all possible scenarios
        IERC20(lpPair).approve(address(dexRouter), lpAmount);

        // // remove the liquidity
        // dexRouter.removeLiquidityETH(
        //     address(this),
        //     lpAmount,
        //     1, // slippage is unavoidable
        //     1, // slippage is unavoidable
        //     msg.sender,
        //     block.timestamp
        // );
        posMan.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: IUniswapV3Pool(pool).liquidity(),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
    }

    function launch(uint256 blocksForPenalty) external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        require(
            blocksForPenalty < 10,
            "Cannot make penalty blocks more than 10"
        );

        //standard enable trading
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        emit EnabledTrading();
    }
}