// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./DividendTracker.sol";

interface ITokenStorage {
  function swapTokensForDai(uint256 tokens) external;
  function transferDai(address to, uint256 amount) external;
  function addLiquidity(uint256 tokens, uint256 dais) external;
  function distributeDividends(uint256 swapTokensDividends, uint256 daiDividends) external;
  function setLiquidityWallet(address _liquidityWallet) external;
}

contract Digits is Ownable, IERC20 {
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string private constant _name = "Digits";
    string private constant _symbol = "DIGITS";

    address public constant uniswapRouter = address(0x5C6EC38fb0e2609672BDf628B1fD605A523E5923);   // sushi router
    address public constant dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);  // DAI.e address

    uint256 public treasuryFeeBPS = 700;
    uint256 public liquidityFeeBPS = 200;
    uint256 public dividendFeeBPS = 300;
    uint256 public totalFeeBPS = 1200;

    uint256 public swapTokensAtAmount = 100000 * (10**18);
    uint256 public lastSwapTime;
    bool swapAllToken = true;

    bool public swapEnabled = true;
    bool public taxEnabled = true;
    bool public compoundingEnabled = true;

    uint256 private _totalSupply;
    bool private swapping;

    address marketingWallet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _whiteList;

    event SwapAndAddLiquidity(uint256 tokensSwapped, uint256 daiReceived, uint256 tokensIntoLiquidity);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SetFee(uint256 _treasuryFee, uint256 _liquidityFee, uint256 _dividendFee);
    event SwapEnabled(bool enabled);
    event TaxEnabled(bool enabled);
    event CompoundingEnabled(bool enabled);
    event SetTokenStorage(address _tokenStorage);
    event UpdateDividendSettings(bool _swapEnabled, uint256 _swapTokensAtAmount, bool _swapAllToken);
    event SetMaxTxBPS(uint256 bps);
    event ExcludeFromMaxTx(address account, bool excluded);
    event SetMaxWalletBPS(uint256 bps);
    event ExcludeFromMaxWallet(address account, bool excluded);


    DividendTracker public immutable dividendTracker;
    ITokenStorage public tokenStorage;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    uint256 public maxTxBPS = 49;
    uint256 public maxWalletBPS = 200;

    bool isOpen = false;

    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    constructor(
        address _marketingWallet,
        address[] memory whitelistAddress
    ) {
        marketingWallet = _marketingWallet;
        includeToWhiteList(whitelistAddress);

        uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), dai);

        dividendTracker = new DividendTracker(address(this), uniswapRouter);

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(uniswapV2Router), true);
        dividendTracker.excludeFromDividends(address(DEAD), true);        

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(dividendTracker), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(dividendTracker), true);

        _mint(owner(), 1000000000 * (10**18));
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
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

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
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
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "Digits: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "Digits: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            isOpen ||
            sender == owner() ||
            recipient == owner() ||
            _whiteList[sender] ||
            _whiteList[recipient],
            "Not Open"
        );

        require(sender != address(0), "Digits: transfer from the zero address");
        require(recipient != address(0), "Digits: transfer to the zero address");

        uint256 _maxTxAmount = (totalSupply() * maxTxBPS) / 10000;
        uint256 _maxWallet = (totalSupply() * maxWalletBPS) / 10000;
        require(
            amount <= _maxTxAmount || _isExcludedFromMaxTx[sender],
            "TX Limit Exceeded"
        );

        if (
            sender != owner() &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != uniswapV2Pair
        ) {
            uint256 currentBalance = balanceOf(recipient);
            require(
                _isExcludedFromMaxWallet[recipient] ||
                    (currentBalance + amount <= _maxWallet)
            );
        }

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "Digits: transfer amount exceeds balance"
        );

        uint256 contractTokenBalance = IERC20(this).balanceOf(address(tokenStorage));
        uint256 contractDaiBalance = IERC20(dai).balanceOf(address(tokenStorage));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            swapEnabled && // True
            canSwap && // true
            !swapping && // swapping=false !false true
            !automatedMarketMakerPairs[sender] && // no swap on remove liquidity step 1 or DEX buy
            sender != address(uniswapV2Router) && // no swap on remove liquidity step 2
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            if (!swapAllToken) {
                contractTokenBalance = swapTokensAtAmount;
            }
            _executeSwap(contractTokenBalance, contractDaiBalance);

            lastSwapTime = block.timestamp;
            swapping = false;
        }

        bool takeFee;

        if (
            sender == address(uniswapV2Pair) ||
            recipient == address(uniswapV2Pair)
        ) {
            takeFee = true;
        }

        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (swapping || !taxEnabled) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = (amount * totalFeeBPS) / 10000;
            amount -= fees;
            _executeTransfer(sender, address(tokenStorage), fees);
        }

        _executeTransfer(sender, recipient, amount);

        dividendTracker.setBalance(sender, balanceOf(sender));
        dividendTracker.setBalance(recipient, balanceOf(recipient));
    }

    function _executeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "Digits: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Digits: approve from the zero address");
        require(spender != address(0), "Digits: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "Digits: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function includeToWhiteList(address[] memory _users) private {
        for (uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }

    function _executeSwap(uint256 tokens, uint256 dais) private {
        if (tokens <= 0) {
            return;
        }

        uint256 swapTokensMarketing;
        if (address(marketingWallet) != address(0)) {
            swapTokensMarketing = (tokens * treasuryFeeBPS) / totalFeeBPS;
        }

        uint256 swapTokensDividends;
        if (dividendTracker.totalSupply() > 0) {
            swapTokensDividends = (tokens * dividendFeeBPS) / totalFeeBPS;
        }

        uint256 tokensForLiquidity = tokens -
            swapTokensMarketing -
            swapTokensDividends;
        uint256 swapTokensLiquidity = tokensForLiquidity / 2;
        uint256 addTokensLiquidity = tokensForLiquidity - swapTokensLiquidity;
        uint256 swapTokensTotal = swapTokensMarketing +
            swapTokensDividends +
            swapTokensLiquidity;

        uint256 initDaiBal = IERC20(dai).balanceOf(address(tokenStorage));
        tokenStorage.swapTokensForDai(swapTokensTotal);
        uint256 daiSwapped = (IERC20(dai).balanceOf(address(tokenStorage)) - initDaiBal) +
            dais;

        uint256 daiMarketing = (daiSwapped * swapTokensMarketing) /
            swapTokensTotal;
        uint256 daiDividends = (daiSwapped * swapTokensDividends) /
            swapTokensTotal;
        uint256 daiLiquidity = daiSwapped -
            daiMarketing -
            daiDividends;

        if (daiMarketing > 0) {
            tokenStorage.transferDai(marketingWallet, daiMarketing);
        }

        tokenStorage.addLiquidity(addTokensLiquidity, daiLiquidity);
        emit SwapAndAddLiquidity(
            swapTokensLiquidity,
            daiLiquidity,
            addTokensLiquidity
        );

        if (daiDividends > 0) {
            tokenStorage.distributeDividends(swapTokensDividends, daiDividends);
        }
    }

    function openTrading() external onlyOwner {
        isOpen = true;
    }

    function setTokenStorage(address _tokenStorage) external onlyOwner {
        require(address(tokenStorage) == address(0), "Digits: tokenStorage already set.");

        tokenStorage = ITokenStorage(_tokenStorage);
        dividendTracker.excludeFromDividends(address(tokenStorage), true);
        excludeFromFees(address(tokenStorage), true);
        excludeFromMaxTx(address(tokenStorage), true);
        excludeFromMaxWallet(address(tokenStorage), true);
        emit SetTokenStorage(_tokenStorage);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Digits: account is already set to requested state"
        );
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function excludeFromDividends(address account, bool excluded)
        external
        onlyOwner
    {
        dividendTracker.excludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account)
        external
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function setWallet(
        address _marketingWallet,
        address _liquidityWallet
    ) external onlyOwner {
        require(_marketingWallet != address(0), "Digits: zero!");
       require(_liquidityWallet != address(0), "Digits: zero!");

        marketingWallet = _marketingWallet;
        tokenStorage.setLiquidityWallet(_liquidityWallet);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(pair != uniswapV2Pair, "Digits: DEX pair can not be removed");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setFee(
        uint256 _treasuryFee,
        uint256 _liquidityFee,
        uint256 _dividendFee
    ) external onlyOwner {
        require(_treasuryFee <= 800 && _liquidityFee <= 800 && _dividendFee <= 800, "Each fee must be below 8%.");

        treasuryFeeBPS = _treasuryFee;
        liquidityFeeBPS = _liquidityFee;
        dividendFeeBPS = _dividendFee;
        totalFeeBPS = _treasuryFee + _liquidityFee + _dividendFee;

        emit SetFee(_treasuryFee, _liquidityFee, _dividendFee);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Digits: automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            dividendTracker.excludeFromDividends(pair, true);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function claim() external {
        bool result = dividendTracker.processAccount(_msgSender());

        require(result == true, "Digits: claim failed.");
    }

    function compound() external {
        require(compoundingEnabled, "Digits: compounding is not enabled");
        bool result = dividendTracker.compoundAccount(_msgSender());

        require(result == true, "Digits: compounding failed.");
    }

    function withdrawableDividendOf(address account)
        external
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function withdrawnDividendOf(address account)
        external
        view
        returns (uint256)
    {
        return dividendTracker.withdrawnDividendOf(account);
    }

    function accumulativeDividendOf(address account)
        external
        view
        returns (uint256)
    {
        return dividendTracker.accumulativeDividendOf(account);
    }

    function getAccountInfo(address account)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountInfo(account);
    }

    function getLastClaimTime(address account) external view returns (uint256) {
        return dividendTracker.getLastClaimTime(account);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    function setTaxEnabled(bool _enabled) external onlyOwner {
        taxEnabled = _enabled;
        emit TaxEnabled(_enabled);
    }

    function setCompoundingEnabled(bool _enabled) external onlyOwner {
        compoundingEnabled = _enabled;

        emit CompoundingEnabled(_enabled);
    }

    function updateDividendSettings(
        bool _swapEnabled,
        uint256 _swapTokensAtAmount,
        bool _swapAllToken
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapTokensAtAmount = _swapTokensAtAmount;
        swapAllToken = _swapAllToken;

        emit UpdateDividendSettings(_swapEnabled, _swapTokensAtAmount, _swapAllToken);
    }

    function setMaxTxBPS(uint256 bps) external onlyOwner {
        require(bps >= 49 && bps <= 10000, "BPS must be between 49 and 10000");
        maxTxBPS = bps;

        emit SetMaxTxBPS(bps);
    }

    function excludeFromMaxTx(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxTx[account] = excluded;

        emit ExcludeFromMaxTx(account, excluded);
    }

    function isExcludedFromMaxTx(address account) external view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setMaxWalletBPS(uint256 bps) external onlyOwner {
        require(
            bps >= 100 && bps <= 10000,
            "BPS must be between 100 and 10000"
        );
        maxWalletBPS = bps;

        emit SetMaxWalletBPS(bps);
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;

        emit ExcludeFromMaxWallet(account, excluded);
    }

    function isExcludedFromMaxWallet(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromMaxWallet[account];
    }

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DividendTracker is Ownable, IERC20 {
    address public constant dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);  // DAI.e address

    string private constant _name = "Digits_DividendTracker";
    string private constant _symbol = "Digits_DividendTracker";

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 private constant magnitude = 2**128;
    uint256 public immutable minTokenBalanceForDividends;
    uint256 private magnifiedDividendPerShare;
    uint256 public totalDividendsDistributed;
    uint256 public totalDividendsWithdrawn;

    address public immutable tokenAddress;
    IUniswapV2Router02 public uniswapV2Router;

    mapping(address => bool) public excludedFromDividends;
    mapping(address => int256) private magnifiedDividendCorrections;
    mapping(address => uint256) private withdrawnDividends;
    mapping(address => uint256) private lastClaimTimes;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event ExcludeFromDividends(address indexed account, bool excluded);
    event Claim(address indexed account, uint256 amount);
    event Compound(address indexed account, uint256 amount, uint256 tokens);

    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    constructor(address _tokenAddress, address _uniswapRouter) {
        minTokenBalanceForDividends = 10000 * (10**18);
        tokenAddress = _tokenAddress;
        uniswapV2Router = IUniswapV2Router02(_uniswapRouter);
    }

    function distributeDividends(uint256 daiDividends) external {
        require(_totalSupply > 0, "dividends unavailable yet");
        if (daiDividends > 0) {
            IERC20(dai).transferFrom(msg.sender, address(this), daiDividends);
            magnifiedDividendPerShare =
                magnifiedDividendPerShare +
                ((daiDividends * magnitude) / _totalSupply);
            emit DividendsDistributed(msg.sender, daiDividends);
            totalDividendsDistributed += daiDividends;
        }
    }

    function setBalance(address account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }
        if (newBalance >= minTokenBalanceForDividends) {
            _setBalance(account, newBalance);
        } else {
            _setBalance(account, 0);
        }
    }

    function excludeFromDividends(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            excludedFromDividends[account] != excluded,
            "Digits_DividendTracker: account already set to requested state"
        );
        excludedFromDividends[account] = excluded;
        if (excluded) {
            _setBalance(account, 0);
        } else {
            uint256 newBalance = IERC20(tokenAddress).balanceOf(account);
            if (newBalance >= minTokenBalanceForDividends) {
                _setBalance(account, newBalance);
            } else {
                _setBalance(account, 0);
            }
        }
        emit ExcludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account)
        external
        view
        returns (bool)
    {
        return excludedFromDividends[account];
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _balances[account];
        if (newBalance > currentBalance) {
            uint256 addAmount = newBalance - currentBalance;
            _mint(account, addAmount);
        } else if (newBalance < currentBalance) {
            uint256 subAmount = currentBalance - newBalance;
            _burn(account, subAmount);
        }
    }

    function _mint(address account, uint256 amount) private {
        require(
            account != address(0),
            "Digits_DividendTracker: mint to the zero address"
        );
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        magnifiedDividendCorrections[account] =
            magnifiedDividendCorrections[account] -
            int256(magnifiedDividendPerShare * amount);
    }

    function _burn(address account, uint256 amount) private {
        require(
            account != address(0),
            "Digits_DividendTracker: burn from the zero address"
        );
        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "Digits_DividendTracker: burn amount exceeds balance"
        );
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        magnifiedDividendCorrections[account] =
            magnifiedDividendCorrections[account] +
            int256(magnifiedDividendPerShare * amount);
    }

    function processAccount(address account)
        external
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }

    function _withdrawDividendOfUser(address account)
        private
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[account] += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            emit DividendWithdrawn(account, _withdrawableDividend);

            IERC20(dai).transfer(account, _withdrawableDividend);
               
            return _withdrawableDividend;
        }
        return 0;
    }

    function compoundAccount(address account)
        external
        onlyOwner
        returns (bool)
    {
        (uint256 amount, uint256 tokens) = _compoundDividendOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Compound(account, amount, tokens);
            return true;
        }
        return false;
    }

    function _compoundDividendOfUser(address account)
        private
        returns (uint256, uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[account] += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            emit DividendWithdrawn(account, _withdrawableDividend);

            address[] memory path = new address[](2);
            path[0] = dai;
            path[1] = address(tokenAddress);

            bool success;
            uint256 tokens;

            uint256 initTokenBal = IERC20(tokenAddress).balanceOf(account);
            IERC20(dai).approve(address(uniswapV2Router), _withdrawableDividend);
            try
                uniswapV2Router
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens
                    (_withdrawableDividend, 0, path, address(account), block.timestamp)
            {
                success = true;
                tokens = IERC20(tokenAddress).balanceOf(account) - initTokenBal;
            } catch Error(
                string memory /*err*/
            ) {
                success = false;
            }

            if (!success) {
                withdrawnDividends[account] -= _withdrawableDividend;
                totalDividendsWithdrawn -= _withdrawableDividend;
                return (0, 0);
            }

            return (_withdrawableDividend, tokens);
        }
        return (0, 0);
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return accumulativeDividendOf(account) - withdrawnDividends[account];
    }

    function withdrawnDividendOf(address account)
        external
        view
        returns (uint256)
    {
        return withdrawnDividends[account];
    }

    function accumulativeDividendOf(address account)
        public
        view
        returns (uint256)
    {
        int256 a = int256(magnifiedDividendPerShare * balanceOf(account));
        int256 b = magnifiedDividendCorrections[account]; // this is an explicit int256 (signed)
        return uint256(a + b) / magnitude;
    }

    function getAccountInfo(address account)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
    }

    function getLastClaimTime(address account) external view returns (uint256) {
        return lastClaimTimes[account];
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("Digits_DividendTracker: method not implemented");
    }

    function allowance(address, address)
        public
        pure
        override
        returns (uint256)
    {
        revert("Digits_DividendTracker: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("Digits_DividendTracker: method not implemented");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("Digits_DividendTracker: method not implemented");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}