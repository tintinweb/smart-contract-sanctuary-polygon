/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: Unlicensed

// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    function RenounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function TransferOwnership(address newOwner) public virtual onlyOwner {
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


pragma solidity ^0.8.0;

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


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
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

contract Pausable is Ownable {
    event pause(bool isPause);

    bool public Paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!Paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(Paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function Pause() public onlyOwner whenNotPaused {
        Paused = true;
        emit pause(Paused);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function Unpause() public onlyOwner whenPaused {
        Paused = false;
        emit pause(Paused);
    }
}


contract FantasyDigital is Context, IERC20, Ownable, Pausable{

    //Token related variables
    uint256 public _totalSupply = 100 * 10 ** 18;
    uint256 public maxTxLimit = 10* 10 ** 18;
    string _name = 'FDtesting7';
    string _symbol = 'FD7';
    uint8 _decimals = 18;

    //ERC20 standard variables
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //Variables related to fees
    mapping (address => uint) private _isTimeLimit;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _excludeFromMaxTxLimit;
    mapping (address => bool) private _excludeFromTimeLimit;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private _FDTeamTax = 200;
    uint256 private _PromoTax= 200;
	uint256 private _BurnTax= 100;
       
    address private TeamAcc;
    address private PromoAcc;
    address private BurnAcc = 0x000000000000000000000000000000000000dEaD;
	
    struct Fees {uint TeamFee;  uint PromoFee;  uint BurnFee; }

    uint8 public timeLimit = 1;
    
    //Variables and events for swapping
  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;


    function name() public view returns (string memory) { return _name;   }

    function symbol() public view returns (string memory) { return _symbol;  }

    function decimals() public view returns (uint8) { return _decimals;   }

    function totalSupply() public view override returns (uint256) {  return _totalSupply;  }

    function balanceOf(address account) public view override returns (uint256) {  return _balances[account];   }
    
    function FDTeamtax() public view returns (uint256) { return _FDTeamTax;  }
    function Promotax() public view returns (uint256) { return _PromoTax;  }
	function Burntax() public view returns (uint256) { return _BurnTax;  }

    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
	function getPromoaddress()  public view returns(address){  return PromoAcc;  }
    function getTeamAddress()  public view returns(address){  return TeamAcc;   }
	function getBurnAddress()  public view returns(address){  return BurnAcc;   }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function setBurnPercent(uint256 newburnRate) external onlyOwner {
        require(newburnRate <= 100, "RTT: Burn rate too high");
        _BurnTax = newburnRate;
    }
       
	function SetTeamTaxPercent(uint256 teamRate) external onlyOwner() {
        _FDTeamTax = teamRate;
    }
    
    function SetPromoTaxPercent(uint256 promoRate) external onlyOwner() {
        _PromoTax = promoRate;
    }
	
    function excludeFromTimeLimit(address addr) public onlyOwner {
        _excludeFromTimeLimit[addr] = true;
    }
    
    function setTimeLimit(uint8 value) public onlyOwner {
        timeLimit = value;
    }
   
    function ExcludeFromTax(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
     function excludeFromMaxTxLimit(address addr) public onlyOwner {
        _excludeFromMaxTxLimit[addr] = true;
    }
    
    function IncludeInTax(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
	
	function calculateBurnFee(uint256 amount) public view returns (uint256) {
        return (amount * (_BurnTax)) / (10000);
    }

    function calculatePromoFee(uint256 amount) public view returns (uint256) {
        return (amount * (_PromoTax)) / (10000);
    }

    function calculateOperationsFee(uint256 amount) public view returns (uint256) {
        return (amount * (_FDTeamTax)) / (10000);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused  returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount should be greater than zero");
        if(sender!=owner() && !_excludeFromMaxTxLimit[sender]){
              require(amount <= maxTxLimit, 'Amount exceeds maximum transcation limit!');
           _excludeFromMaxTxLimit[msg.sender] = false; }
        
         if(!_excludeFromTimeLimit[sender]) {
            require(_isTimeLimit[sender] <= block.timestamp, 'Time limit error!');
        }
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
      
       
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        bool takeFee = true;

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }
		
        if(recipient == uniswapV2Pair){
            _transferTokens(sender, recipient, amount);
        }else{
            if(takeFee) {
                _transferStandard(sender, recipient, amount);
            } else {
                _transferTokens(sender, recipient, amount);
            
            }
        }
            _isTimeLimit[sender] = block.timestamp + (timeLimit * 10);
   
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
            block.timestamp+60
        );
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
            owner(),//LP token receiving address
            block.timestamp
        );
    }

    function _transferTokens(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance - (amount);
        }
            _balances[recipient] = _balances[recipient] + (amount);

        emit Transfer(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        uint256 BurnFee;
        uint256 PromoFee;
        uint256 TeamFee;
		uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance - (amount);
        }
        
            BurnFee = calculateBurnFee(amount);
            PromoFee = calculatePromoFee(amount);
            TeamFee = calculateOperationsFee(amount);     
       
        //_balances[recipient] = _balances[recipient] + (amount);
		
		emit Transfer(sender, TeamAcc, TeamFee);
		emit Transfer(sender, PromoAcc, PromoFee);
		emit Transfer(sender, BurnAcc, BurnFee);
        emit Transfer(sender, recipient, amount - (TeamFee + BurnFee + PromoFee));

    }

   function TransferOwnership(address newOwner) public override virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    constructor(address _PromoAcc, address _TeamAcc) {
    _balances[msg.sender] = _totalSupply;
        
     IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
       
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        TeamAcc = _TeamAcc;
        PromoAcc = _PromoAcc;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _excludeFromMaxTxLimit[msg.sender] = true;
        _excludeFromMaxTxLimit[msg.sender] = true;
        _excludeFromTimeLimit[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
       _excludeFromTimeLimit[address(this)] = true;
    }
    function SetPromoAddress( address NewPromoAcc) external onlyOwner{
        PromoAcc=NewPromoAcc;
    }
   function SetTeamAddress (address NewTeamAcc) external onlyOwner{
       TeamAcc=NewTeamAcc;
   }
}