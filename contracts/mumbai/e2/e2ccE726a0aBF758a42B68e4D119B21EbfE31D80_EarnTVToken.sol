/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * ERC20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract EarnTVToken is IBEP20, Ownable {
    event AllocatedMarketingFunds(address to, uint256 amount);
    event ExcludedFromFeesAsRecipientSet(address indexed account, bool whitelisted);
    event ExcludedFromFeesAsSenderSet(address indexed account, bool whitelisted);
    event LiquidityThresholdSet(uint256 amount);
    event SwapRouterSet(address indexed router);
    event LiquidityTokenDestinationSet(address indexed destination);
    event SwappedAndAddedLiquidity(uint256 tokenUsed, uint256 ethUsed, uint256 liquidityAmountAdded, address indexed liquidityTokenDestination);
    event DividendsClaimed(address indexed account, address indexed destination, uint256 amount);
    event FeesTaken(uint256 burned, uint256 dividendFee, uint256 liquidityFee, uint256 marketingFee);

    // Basic ERC20/BEP20 variables
    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;
    uint256 public maxSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;
    
    // Unique variables
    uint256 public immutable dividendFeeRate = 200;  // In basis points (i.e. 1% = 100, 0.01% = 1)
    uint256 public immutable liquidityFeeRate = 200;
    uint256 public immutable burnFeeRate = 100;
    uint256 public immutable marketingFeeRate = 100;

    uint256 public marketingFeeBalance;
    uint256 public liquidityThreshold;
    uint256 public thresholdDividend = 1000;

    address public swapRouter;
    address public liquidityTokenDestination;

    

    mapping(address => bool) public isExcludedFromFeesAsRecipient;
    mapping(address => bool) public isExcludedFromFeesAsSender;

    mapping(address => uint256) public dividendsClaimedBy;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint256 _maxSupply,
        uint256 _liquidityThreshold,
        address router
    ) Ownable() {
        name     = _name;
        symbol   = _symbol;
        decimals = _decimals;

        _mint(owner(), _totalSupply * 10 ** _decimals); // Mint the total supply to the owner

        setLiquidityThreshold(_liquidityThreshold);  // Set the liquidity threshold to 100k tokens

        setSwapRouter(router);

        maxSupply = _maxSupply * 10 ** _decimals;

        setLiquidityTokenDestination(owner());
    }

    function allocateMarketingFunds(address to, uint256 amount) external onlyOwner {
        marketingFeeBalance -= amount;
        balanceOf[to] += amount;
        emit AllocatedMarketingFunds(to, amount);
    }

    function setExcludedFromFeesAsRecipient(address account, bool whitelisted) external onlyOwner {
        emit ExcludedFromFeesAsRecipientSet(account, isExcludedFromFeesAsRecipient[account] = whitelisted);
    }

    function setThresholdDividend(uint256 amount) external onlyOwner {
        thresholdDividend = amount;
    }

    function setExcludedFromFeesAsSender(address account, bool whitelisted) external onlyOwner {
        emit ExcludedFromFeesAsSenderSet(account, isExcludedFromFeesAsSender[account] = whitelisted);
    }

    function setLiquidityThreshold(uint256 threshold) public onlyOwner {
        emit LiquidityThresholdSet(liquidityThreshold = threshold);
    }

    function setSwapRouter(address router) public onlyOwner {
        emit SwapRouterSet(swapRouter = router);
    }

    function setLiquidityTokenDestination(address destination) public onlyOwner {
        require(destination != address(this), "CANNOT HANDLE LIQUIDITY TOKENS");
        emit LiquidityTokenDestinationSet(liquidityTokenDestination = destination);
    }

    function claimDividends(address destination) external {
        require(dividendsClaimedBy[destination] > 0, "There isn't any token to be claimed");
        require(totalSupply + dividendsClaimedBy[destination] <= maxSupply, "There isn't enough balance of token. Please ask service");

        _mint(destination, dividendsClaimedBy[destination]);

        emit DividendsClaimed(msg.sender, destination, dividendsClaimedBy[destination]);
        dividendsClaimedBy[destination] = 0;
    }

    function addDividends(address destination, uint256 amount) external onlyOwner {
        require(amount < thresholdDividend, "Scam is detected");
        dividendsClaimedBy[destination] += amount;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address owner, address recipient, uint256 amount) external override returns (bool) {
        _approve(owner, msg.sender, allowance[owner][msg.sender] - amount);
        _transfer(owner, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        emit Approval(owner, spender, allowance[owner][spender] = amount);
    }

    function _transfer(address owner, address recipient, uint256 amount) internal {
        emit Transfer(owner, recipient, amount);

        if (isExcludedFromFeesAsRecipient[recipient] || isExcludedFromFeesAsSender[owner]) {
            balanceOf[owner]     -= amount;
            balanceOf[recipient] += amount;
            return;
        }

        uint256 burnAmount = amount * burnFeeRate / uint256(10_000);
        _burn(owner, burnAmount);

        uint256 dividendFee = amount * dividendFeeRate / uint256(10_000);
        uint256 liquidityFee = amount * liquidityFeeRate / uint256(10_000);
        uint256 marketingFee = amount * marketingFeeRate / uint256(10_000);

        uint256 decrementAmount = amount - burnAmount;  // burnAmount already removed from sender in _burn
        uint256 incrementAmount = decrementAmount - dividendFee - liquidityFee - marketingFee;

        balanceOf[address(this)] += liquidityFee;  // any of this contract's own token that it owns will be used for adding liquidity
        marketingFeeBalance += marketingFee;

        emit FeesTaken(burnAmount, dividendFee, liquidityFee, marketingFee);

        balanceOf[owner]     -= decrementAmount;
        balanceOf[recipient] += incrementAmount;

        if (balanceOf[address(this)] < liquidityThreshold) return;

        if (swapRouter == address(0)) return;

        _swapAndAddLiquidity();
    }

    function _mint(address recipient, uint256 amount) internal {
        totalSupply          += amount;
        balanceOf[recipient] += amount;

        emit Transfer(address(0), recipient, amount);
    }

    function _burn(address owner, uint256 amount) internal {
        balanceOf[owner] -= amount;
        totalSupply      -= amount;

        emit Transfer(owner, address(0), amount);
    }

    function _swapAndAddLiquidity() internal {
        // Track the starting amount of token and eth owned by this contract itself
        uint256 startingTokenBalance = balanceOf[address(this)];
        uint256 startingEthBalance = address(this).balance;

        // Swap half this contract's tokens owned, into ETH
        _swapTokensForEth(startingTokenBalance / 2);

        // Add as much of this contract's tokens and ETH owned as liquidity
        uint256 liquidityAdded = _addLiquidity(balanceOf[address(this)], address(this).balance);
        
        // Report how many of the originally owner tokens and ETH were used in the adding of liquidity,
        // as well as how much liquidity was added, and which account received the liquidity tokens
        emit SwappedAndAddedLiquidity(
            startingTokenBalance - balanceOf[address(this)],
            startingEthBalance > address(this).balance ? startingEthBalance - address(this).balance : 0,
            liquidityAdded,
            liquidityTokenDestination
        );
    }

    function _swapTokensForEth(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02(swapRouter).WETH();

        _approve(address(this), swapRouter, amount);

        IUniswapV2Router02(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,  // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal returns (uint256 liquidityAdded) {
        _approve(address(this), swapRouter, tokenAmount);

        ( , , liquidityAdded ) = IUniswapV2Router02(swapRouter).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,  // slippage is unavoidable
            0,  // slippage is unavoidable
            liquidityTokenDestination,
            block.timestamp
        );
    }

    receive() external payable {}
}