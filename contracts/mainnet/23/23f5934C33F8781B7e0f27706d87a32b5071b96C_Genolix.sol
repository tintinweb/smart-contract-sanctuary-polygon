/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory tname,
        string memory tsymbol,
        uint8 tdecimals
    ) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;
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
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function staking(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

contract Genolix is Context, Ownable, IERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) private _isExcludedWallet;
    mapping(address => bool) public _isBot;

    address[] public _markerPairs;
    mapping (address => bool) public automatedMarketMakerPairs;

    mapping(address => uint256) private _lastBuy;
    mapping(address => uint256) private _lastSell;

    uint256 internal _totalSupply;

    uint256 private marketingFee;
    uint256 private stakingFee;
    uint256 private liquidityFee;
    uint256 private totalFee;

    uint256 public BUYmarketingFee = 3;
    uint256 public BUYstakingFee = 2;
    uint256 public BUYliquidityFee = 1;
    uint256 public BUYtotalFee =
        BUYliquidityFee.add(BUYmarketingFee).add(BUYstakingFee);

    uint256 public SELLmarketingFee = 3;
    uint256 public SELLstakingFee = 2;
    uint256 public SELLliquidityFee = 1;
    uint256 public SELLtotalFee =
        SELLliquidityFee.add(SELLmarketingFee).add(SELLstakingFee);

    address payable public marketingAddress =
        payable(0x089789Dd3b6CbE4B4F81141168552AA5dF9d06DD);

    address payable public stakingAddress =
        payable(0x089789Dd3b6CbE4B4F81141168552AA5dF9d06DD);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public numTokensSellToAddToLiquidity = 100000 * 10**18;

    uint256 public MaxTradeLimit = 40000000 * 10**18;     // 0.5%
    uint256 public maxWalletBalance = 160000000 * 10**18; // 2%

    uint256 public antiBotBuyCoolDown = 5 seconds;
    uint256 public antiBotSellCoolDown = 30 seconds;

    bool public tradingIsEnabled = false;
    bool public limitsAreEnabled = true;

    event ExcludedFromTradeLimit(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    bool private swapping;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    address public _owner;

    constructor() ERC20Detailed("Genolix DNA Innovation", "GENO", 18) {
        _owner = msg.sender;
        _totalSupply = 8_000_000_000 * (10**18);

        _balances[_owner] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        setAutomatedMarketMakerPair(uniswapV2Pair, true);

        //exclude owner and this contract from fee
        excludedFromTradeLimit(msg.sender, true);
        excludedFromTradeLimit(address(this), true);

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function enableTrading() external onlyOwner() {
        require(!tradingIsEnabled, "Trading is already enabled");
        tradingIsEnabled = true;
    }

    function enableLimits(bool value) external onlyOwner() {
        limitsAreEnabled = value;
    }

    function setMaxTradeLimit(uint256 _maxTradeLimit) external onlyOwner() {
        require(_maxTradeLimit >= 1000, "Trade limit too small");
        MaxTradeLimit = _maxTradeLimit * 10**decimals();
    }

    function setMaxWalletBalance(uint256 newMaxWalletBalance) external onlyOwner() {
        require(newMaxWalletBalance >= 1000, "Wallet balance limit too small");
        maxWalletBalance = newMaxWalletBalance * 10**decimals();
    }

    function excludedFromTradeLimit(address account, bool excluded) public onlyOwner() {
        require(_isExcludedWallet[account] != excluded, "Already excluded");
        _isExcludedWallet[account] = excluded;

        emit ExcludedFromTradeLimit(account, excluded);
    }

    function getIsExcludedFromTradeLimit(address account) public view returns (bool) {
        return _isExcludedWallet[account];
    }

    function addBotToList(address account) external onlyOwner() {
        require(!automatedMarketMakerPairs[account], "We can not blacklist routers");
        require(!_isBot[account], "Account is already blacklisted");
        _isBot[account] = true;
    }

    function removeBotFromList(address account) external onlyOwner() {
        require(_isBot[account], "Account is not blacklisted");
        _isBot[account] = false;
    }

    function setAntiBotBuyCoolDown(uint256 _antiBotBuyCoolDown) external onlyOwner() {
        require(_antiBotBuyCoolDown <= 300, "Too long of cooldown");
        antiBotBuyCoolDown = _antiBotBuyCoolDown;
    }

    function setAntiBotSellCoolDown(uint256 _antiBotSellCoolDown) external onlyOwner() {
        require(_antiBotSellCoolDown <= 300, "Too long of cooldown");
        antiBotSellCoolDown = _antiBotSellCoolDown;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address towner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[towner][spender];
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
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
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
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function setMarketingAddress(address payable wallet) external onlyOwner {
        marketingAddress = wallet;
    }

    function setStakingAddress(address payable wallet) external onlyOwner {
        stakingAddress = wallet;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function changeNumTokensSellToAddToLiquidity(
        uint256 _numTokensSellToAddToLiquidity
    ) external onlyOwner {
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }

    //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_isBot[sender] || !_isBot[recipient],"You are a bot");
        require(tradingIsEnabled || _isExcludedWallet[sender], "Trading not started");

        if (limitsAreEnabled) {
            if(automatedMarketMakerPairs[sender] && !_isExcludedWallet[recipient]){
                require(_lastBuy[recipient] + antiBotBuyCoolDown < block.timestamp, "Trying to buy too quickly");
                require(amount <= MaxTradeLimit, "Trading too much");

                _lastBuy[recipient] = block.timestamp;
            }

            if(automatedMarketMakerPairs[recipient] && !_isExcludedWallet[sender]){
                require(_lastSell[sender] + antiBotSellCoolDown < block.timestamp, "Trying to sell too quickly");
                require(amount <= MaxTradeLimit, "Trading too much");

                _lastSell[sender] = block.timestamp;
            }

            if(!automatedMarketMakerPairs[recipient] && !_isExcludedWallet[recipient]) {
                require(balanceOf(recipient) + amount <= maxWalletBalance, "Wallet balance is too high");
            }
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !swapping &&
            sender != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapping = true;

            uint256 walletTokens = contractTokenBalance
                .mul(SELLmarketingFee)
                .div(SELLtotalFee);
            uint256 contractBalance = address(this).balance;
            swapTokensForEth(walletTokens);
            uint256 newBalance = address(this).balance.sub(contractBalance);
            uint256 marketingShare = newBalance.mul(SELLmarketingFee).div(
                (SELLmarketingFee)
            );
            //uint256 rewardShare = newBalance.sub(marketingShare);
            payable(marketingAddress).transfer(marketingShare);

            uint256 swapTokens = contractTokenBalance.mul(SELLliquidityFee).div(
                SELLtotalFee
            );
            swapAndLiquify(swapTokens);

            swapping = false;
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = !swapping;

        //if any account belongs to _isExcludedWallet account then remove the fee
        if (_isExcludedWallet[sender] || _isExcludedWallet[recipient]) {
            takeFee = false;
        }

        if (sender != uniswapV2Pair && recipient != uniswapV2Pair) {
            takeFee = false;
        }
        if (takeFee) {
            if (sender == uniswapV2Pair) {
                marketingFee = BUYmarketingFee;
                liquidityFee = BUYliquidityFee;
                stakingFee = BUYstakingFee;
                totalFee = BUYtotalFee;
            }
            if (recipient == uniswapV2Pair) {
                marketingFee = SELLmarketingFee;
                liquidityFee = SELLliquidityFee;
                stakingFee = SELLstakingFee;
                totalFee = SELLtotalFee;
            }
        }

        if (takeFee) {
            uint256 taxAmount = amount.mul(totalFee).div(100);
            uint256 stakingAmount = taxAmount.mul(stakingFee).div(totalFee);
            uint256 TotalSent = amount.sub(taxAmount);
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(TotalSent);
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            _balances[stakingAddress] = _balances[stakingAddress].add(stakingAmount);
            emit Transfer(sender, recipient, TotalSent);
            emit Transfer(sender, address(this), taxAmount);
            emit Transfer(sender, stakingAddress, stakingAmount);
        } else {
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function setSellFee(
        uint256 _onSellStakingFee,
        uint256 _onSellLiquidityFee,
        uint256 _onSellMarketingFee
    ) public onlyOwner {
        SELLmarketingFee = _onSellMarketingFee;
        SELLstakingFee = _onSellStakingFee;
        SELLliquidityFee = _onSellLiquidityFee;
        uint256 onSelltotalFees;
        onSelltotalFees = SELLmarketingFee.add(SELLstakingFee).add(
            SELLliquidityFee
        );
        require(onSelltotalFees <= 20, "Sell Fee should be 20% or less");
    }

    function setBuyFee(
        uint256 _onBuyStakingFee,
        uint256 _onBuyLiquidityFee,
        uint256 _onBuyMarketingFee
    ) public onlyOwner {
        BUYmarketingFee = _onBuyMarketingFee;
        BUYstakingFee = _onBuyStakingFee;
        BUYliquidityFee = _onBuyLiquidityFee;
        uint256 onBuytotalFees;
        onBuytotalFees = BUYmarketingFee.add(BUYstakingFee).add(BUYliquidityFee);
        require(onBuytotalFees <= 15, "Buy Fee should be 15% or less");
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> GENO swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _approve(
        address towner,
        address spender,
        uint256 amount
    ) internal {
        require(towner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }

    function withdrawStuckETh() external onlyOwner {
        require(address(this).balance > 0, "Can't withdraw negative or zero");
        payable(owner()).transfer(address(this).balance);
    }

    function removeStuckToken(address _address) external onlyOwner {
        require(
            IERC20(_address).balanceOf(address(this)) > 0,
            "Can't withdraw 0"
        );

        IERC20(_address).transfer(
            owner(),
            IERC20(_address).balanceOf(address(this))
        );
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner() {
        require(automatedMarketMakerPairs[pair] != value, "Value already set");

        automatedMarketMakerPairs[pair] = value;

        if(value){
            _markerPairs.push(pair);
        }else{
            require(_markerPairs.length > 1, "Required 1 pair");
            for (uint256 i = 0; i < _markerPairs.length; i++) {
                if (_markerPairs[i] == pair) {
                    _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                    _markerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
}