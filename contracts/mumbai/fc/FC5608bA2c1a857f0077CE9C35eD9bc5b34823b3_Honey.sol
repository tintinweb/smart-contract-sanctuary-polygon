/**
 *Submitted for verification at polygonscan.com on 2022-02-19
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: Unlicensed

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



    /// @notice Deterministically computes the pool address given the factory and 
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


contract Honey is Context, IERC20, Ownable,Pausable{


    //Token related variables
    uint256 public _totalSupply = 1000000 * 10 ** 18;
    uint256 public maxTxLimit = 10000* 10 ** 18;
    string _name = 'HONEY';
    string _symbol = 'HVE';
    uint8 _decimals = 18;

    //ERC20 standard variables
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    //Variables and events for swapping
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    //Variables related to fees
   // mapping (address => uint) private _isTimeLimit;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _excludeFromMaxTxLimit;
  //  mapping (address => bool) private _excludeFromTimeLimit;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private _HoneyTeamTax = 10;
    uint256 private _TreasuryTax= 5;
    uint256 private _r101;
   
    address private HiveAcc;
    address private Treasury;
    
    struct Fees {
 
        uint HiveFee;
        uint TreasuryFee;
   
    }
    
    constructor(address _Treasury, address _HoneyTeam) {
        _balances[msg.sender] = _totalSupply;
        
     IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
       
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        Treasury = _Treasury;
        HiveAcc = _HoneyTeam;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _excludeFromMaxTxLimit[msg.sender] = true;
         _excludeFromMaxTxLimit[msg.sender] = true;
      //  _excludeFromTimeLimit[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
       //_excludeFromTimeLimit[address(this)] = true;
    }
     // uint8 public timeLimit = 1;
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
    
    function HoneyTeamtax() public view returns (uint256) {
        return _HoneyTeamTax;
    }
      function Treasurytax() public view returns (uint256) {
        return _TreasuryTax;
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
     function getTreasuryaddress()  public view returns(address){
        return Treasury;

    }
     function getTeamAddress()  public view returns(address){
        return HiveAcc;

    }

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
       function ChangeHoneyTeamTaxPercent(uint256 TeamTax) external onlyOwner() {
        _HoneyTeamTax =TeamTax;
    }
    
    function ChangeTreasuryTaxPercent(uint256 changeTreasurytax) external onlyOwner() {
        _TreasuryTax = changeTreasurytax;
    }
    // function excludeFromTimeLimit(address addr) public onlyOwner {
    //     _excludeFromTimeLimit[addr] = true;
    // }
    
    // function  ChangeTimeLimit(uint8 value) public onlyOwner {
    //     timeLimit = value;
    // }
   
    function ExcludeFromTax(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
     function excludeFromMaxTxLimit(address addr) public onlyOwner {
        _excludeFromMaxTxLimit[addr] = true;
    }
    function ChangeTreasuryAddress(address SetTreasury) external onlyOwner{
        Treasury = SetTreasury;
    }
    function ChangeTeamAddress (address TeamAcc) external onlyOwner{
       HiveAcc=TeamAcc;
   }
    function IncludeInTax(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount should be greater than zero");
        if(sender!=owner() && !_excludeFromMaxTxLimit[sender]){
              require(amount <= maxTxLimit, 'Amount exceeds maximum transcation limit!');
           _excludeFromMaxTxLimit[msg.sender] = false; }
        
        //  if(!_excludeFromTimeLimit[sender] && !_excludeFromLimit[receipient]) {
        //     require(_isTimeLimit[sender] <= block.timestamp, 'Time limit error!');
        // }
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        bool takeFee = true;

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }

        _tokenTransfer(sender, recipient, amount, takeFee);
            

    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(recipient == uniswapV2Pair){
        if(!takeFee) {
            _transferTokens(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        }else{
             _transferTokens(sender, recipient, amount);
        }
           // _isTimeLimit[sender] = block.timestamp + (timeLimit * 10);
    }

    function _transferTokens(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance  - (amount);
        }
        _balances[recipient] = _balances[recipient] + (amount);

        emit Transfer(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        
        uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance - (amount);
        }
        
        (uint256 tAmount, uint256 HiveFee, uint256 TreasuryFee) = _getCalculatedFees(amount);

      
        _HiveTransfer(sender, HiveFee);
        _treasuryTransfer(sender, TreasuryFee);
        _balances[recipient] = _balances[recipient] + (tAmount);
        emit Transfer(sender, recipient, tAmount);

    }

    function _getCalculatedFees(uint256 amount) internal view returns(  uint256, uint256, uint256) {
        Fees memory fee;
     
        fee.HiveFee = amount * (_HoneyTeamTax)/100;
        fee.TreasuryFee = amount * (_TreasuryTax)/100;

        uint256 deductedAmount = amount - ((fee.HiveFee)+(fee.TreasuryFee));

        return (deductedAmount, fee.HiveFee, fee.TreasuryFee);
    }
    function _HiveTransfer(address sender, uint256 HiveFee) internal {
        if(HiveFee != 0) {
            _balances[HiveAcc] = _balances[HiveAcc] + (HiveFee);
            emit Transfer(sender, HiveAcc, HiveFee);
        }
    }

    function _treasuryTransfer(address sender, uint256 TreasuryFee) internal {
        if(TreasuryFee != 0) {
            _balances[Treasury] = _balances[Treasury] + (TreasuryFee);
            emit Transfer(sender, Treasury, TreasuryFee);
        }
    }
}