/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

//SPDX-License-Identifier: Unlicensed

/*Interface Declaration*/

pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {  
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        //solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract Ownable is Context {

    address private _owner;
    address private _previousOwner;
    address private _newOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    bool private _newOwnerConfirmation;

    constructor () internal {
        address msgSender = _msgSender();
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function previousowner() public view returns (address) {
        return _previousOwner;
    }

    function newowner() public view returns (address) {
        return _newOwner;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _newOwnerConfirmation = false;
        _newOwner = newOwner;
    }

    function confirmOwnership() public {
        require(!_newOwnerConfirmation, "Ownership alreday accepted by new owner.");
        _previousOwner=_owner;
        _owner = _newOwner;
        _newOwnerConfirmation = true;
        _newOwner=address(0);
        emit OwnershipTransferred(_previousOwner, _owner);
    }  
}

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

contract DLICOM is Context, IERC20, Ownable {  

    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 private _tTotal = 700000000 * 10**18;
    uint256 private _tFeeTotal;
    string private _name = "DLICOM";
    string private _symbol = "DLI";
    uint8 private _decimals = 18;
    uint256 public _maxBuycap;
    uint256 public _minBuycap;
    uint256 public _maxSellcap;
    uint256 public _minSellcap;
    uint256 public TotalBurnToken;
    uint256 public TotalMintToken;
    uint256 public _sellTimeInterval;
    uint256 public _BuyTimeInterval;
    mapping (address => uint) public UserLastSellTimeStamp;
    mapping (address => uint) public UserLastBuyTimeStamp;  
    mapping (address => bool) public checkUserBlocked;

    uint256 private _totalMarketingCollected;
    uint256 public  _marketingPer = 2;

    address payable public  marketingwallet;

    IPancakeRouter02 public uniswapRouter;
    address public uinswapPair;

    bool inSwapAndLiquify;
    bool private paused = false;
    bool public  swapAndLiquifyEnabled =false;
    uint256 private constant minTokensBeforeSwap = 100;
    event Pause();
    event Unpause();
    event UpdateTransactionLimits();
    event UpdateMarketingfee();
    event BlockWalletAddress();
    event UnblockWalletAddress();
    event SetSellTimeInterval();
    event SetBuyTimeInterval();
    event UpdateMarketingWalletAddress();
    event UpdateExcludedFromFee();
    event UpdateIncludeForFee();
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoMarketing     
    );
    modifier lockTheSwap {
        inSwapAndLiquify = true;
         _;
        inSwapAndLiquify = false;
    }

    constructor () public {
        _rOwned[_msgSender()] = _tTotal;
        marketingwallet = 0x687e9a4f5962986F30c3FB526C0c6FC3eAD435EA;
         IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        //CREATE A PANCAKE PAIR FOR THIS NEW TOKEN
        uinswapPair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        //SET THE REST OF THE CONTRACT VARIABLES
        uniswapRouter = _pancakeRouter;      
        //EXCLUDE OWNER AND THIS CONTRACT FROM FEE
        _isExcludedFromFee[marketingwallet] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;  
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /* Smart Contract Owner Can Pause The Token Transaction if And Only If canPause is true */
    function pauseTransaction() onlyOwner public {
        paused = true;
        emit Pause();
    }

    /* Smart Contract Owner Can Unpause The Token Transaction if token previously paused */
    function unpauseTransaction() onlyOwner public {
        paused = false;
        emit Unpause();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(paused != true, "ERC20: Transaction Is Paused now"); 
        require(checkUserBlocked[from] != true , "ERC20: Sender Is Blocked");
        require(checkUserBlocked[to] != true , "ERC20: Receiver Is Blocked");    
        // IS THE TOKEN BALANCE OF THIS CONTRACT ADDRESS OVER THE MIN NUMBER OF
        // TOKENS THAT WE NEED TO INITIATE A SWAP + LIQUIDITY LOCK?
        // ALSO, DON'T GET CAUGHT IN A CIRCULAR LIQUIDITY EVENT.
        // ALSO, DON'T SWAP & LIQUIFY IF SENDER IS PANCAKE PAIR.
        if(from == uinswapPair && to!=address(this)) {
            require(amount <= _maxBuycap, "ERC20: Buy Qty Exceed !");
            require(amount >= _minBuycap, "ERC20: Buy Qty Does Not Match !"); 
            require(checkBuyEligibility(to), "ERC20: Try After Buy Time Interval !"); 
        }
        if(to == uinswapPair && from!=address(this)) {
            require(amount <= _maxSellcap, "ERC20: Sell Qty Exceed !");
            require(amount >= _minSellcap, "ERC20: Sell Qty Does Not Match !"); 
            require(checkSellEligibility(from), "ERC20: Try After Sell Time Interval !"); 
        }
        bool takeFee = true;
        uint TaxType=0;

         if(from == uinswapPair){
            takeFee = true;
            TaxType=1;
        }  
        else if(to == uinswapPair){
           takeFee = true;
            TaxType=2;
        } 
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
            TaxType=0;
        } 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance > minTokensBeforeSwap;
        if 
        (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uinswapPair &&
            swapAndLiquifyEnabled &&
            TaxType != 0 &&
            takeFee
        ) 
        {
            //LIQUIFY TOKEN TO GET BNB 
            swapAndLiquify(contractTokenBalance);
        }
        //TRANSFER AMOUNT, IT WILL TAKE TAX, BURN, LIQUIDITY FEE
        _tokenTransfer(from,to,amount,takeFee,TaxType);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 FullExp = contractTokenBalance;
        uint256 initialBalance = address(this).balance;
        //SWAP TOKENS FOR ETH
        swapTokensForEth(contractTokenBalance); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        //HOW MUCH ETH DID WE JUST SWAP INTO?
        uint256 Marketing = address(this).balance.sub(initialBalance);
        uint256 Balance = address(this).balance;
        marketingwallet.transfer(Balance);
        _totalMarketingCollected=0;
        emit SwapAndLiquify(FullExp, Balance, Marketing);
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        //GENERATE THE PANCAKE PAIR PATH OF TOKEN -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        //MAKE THE SWAP
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, //ACCEPT ANY AMOUNT OF ETH
            path,
            address(this),
            block.timestamp
        );
    }

   
    //THIS METHOD IS RESPONSIBLE FOR TAKING ALL FEE, IF TAKEFEE IS TRUE
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee,uint TaxType) private {
        if(takeFee)
        {
          _transferStandard(sender, recipient, amount);
        }
        else {
          _transferWithoutFee(sender, recipient, amount);
        }
        if(TaxType==1 && sender == uinswapPair) {
            UserLastBuyTimeStamp[recipient]=block.timestamp;
        }
        if(TaxType==2 && recipient == uinswapPair) {
            UserLastSellTimeStamp[sender]=block.timestamp;
        }
    }


    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tTransferAmount);
        if(tFee>0){
          _takeFee(tFee,tAmount);
          _reflectFee(tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);
        if(tFee>0){
            emit Transfer(sender,address(this),tFee);
        }
    }

    function _transferWithoutFee(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _reflectFee(uint256 tFee) private {
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        return (tTransferAmount,tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }
    
    function _takeMarketingFee(uint256 tFee) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(tFee);
        _totalMarketingCollected=_totalMarketingCollected.add(tFee);
    }

    function _takeFee(uint256 tFee,uint256 tAmount) private {
        uint256 MarketingShare=tFee;
        MarketingShare=tAmount.mul(_marketingPer).div(10**2); 
        uint256 contractTransferBalance = MarketingShare;
        _rOwned[address(this)] = _rOwned[address(this)].add(contractTransferBalance);
        _totalMarketingCollected=_totalMarketingCollected.add(MarketingShare);

    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
       return _amount.mul(_marketingPer).div(10**2);
    }
 
    function updateMarketingfee(uint256 marketingPer) public onlyOwner {
         _marketingPer=marketingPer;
         emit UpdateMarketingfee();
    }

    function updateUniswapRouter(address _uniswapRouter) public onlyOwner {
        require(_uniswapRouter != address(uniswapRouter), "YourContract: The router already has that address");
        require(_uniswapRouter != address(0), "YourContract: new address is the zero address");   
        uniswapRouter = IPancakeRouter02(_uniswapRouter);
    }

    function updateUniswapPair(address _uinswapPair) public onlyOwner {
        require(_uinswapPair != address(uinswapPair), "YourContract: The pair already has that address");
        require(_uinswapPair != address(0), "YourContract: new Pair is the zero address"); 
        uinswapPair = _uinswapPair;
    }

    function blockWalletAddress(address WalletAddress) onlyOwner public {
        checkUserBlocked[WalletAddress] = true;
        emit BlockWalletAddress();
    }

    function unblockWalletAddress(address WalletAddress) onlyOwner public {
        checkUserBlocked[WalletAddress] = false;
        emit UnblockWalletAddress();
    }


    /* Contarct Owner Can Update The Minimum & Maximum Transaction Limits */
    function updateCapLimits(uint256 maxBuycap,uint256 minBuycap,uint256 maxSellcap,uint256 minSellcap) public onlyOwner {
       _maxBuycap=maxBuycap;
       _minBuycap=minBuycap;
       _maxSellcap=maxSellcap;
       _minSellcap=minSellcap;
       emit UpdateTransactionLimits();
    }

    function checkSellEligibility(address user) public view returns(bool){
       if(UserLastSellTimeStamp[user]==0) {
           return true;
       }
       else{
           uint noofHour=getHour(UserLastSellTimeStamp[user],getCurrentTimeStamp());
           if(noofHour>=_sellTimeInterval){
               return true;
           }
           else{
               return false;
           }
       }
    }

    function checkBuyEligibility(address user) public view returns(bool){
       if(UserLastBuyTimeStamp[user]==0) {
           return true;
       }
       else{
           uint noofHour=getHour(UserLastBuyTimeStamp[user],getCurrentTimeStamp());
           if(noofHour>=_BuyTimeInterval){
               return true;
           }
           else{
               return false;
           }
       }
    }

    /* Contract Owner Can Set Sell Time Interval */
    function set_sellTimeInterval(uint256 sellTimeInterval) onlyOwner public {
        _sellTimeInterval=sellTimeInterval;
        emit SetSellTimeInterval();
    }

    /* Contract Owner Can Set BUY Time Interval */
    function set_BuyTimeInterval(uint256 BuyTimeInterval) onlyOwner public {
        _BuyTimeInterval=BuyTimeInterval;
        emit SetBuyTimeInterval();
    }

    /* Smart Contract Owner Can Execlude Any Wallet From Fee */
    function excludedFromFee(address walletaddress) onlyOwner public {
       _isExcludedFromFee[walletaddress] = true;
        emit UpdateExcludedFromFee();
    }

    /* Smart Contract Owner Can Include Any Wallet For Fee */
    function includeForFee(address walletaddress) onlyOwner public {
        _isExcludedFromFee[walletaddress] = false;
        emit UpdateIncludeForFee();
    }

    function getCurrentTimeStamp() public view returns(uint _timestamp){
       return (block.timestamp);
    }

    function getHour(uint _startDate,uint _endDate) internal pure returns(uint256){
        return ((_endDate - _startDate) / 60 / 60);
    }
    /**
    * @dev Burn `amount` tokens and decreasing the total supply.
    */
    function burn(uint256 amount) public onlyOwner returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _rOwned[account] = _rOwned[account].sub(amount, "ERC20: burn amount exceeds balance");
        _tTotal -=amount;
        TotalBurnToken+=amount;
        emit Transfer(account, address(0), amount);
    }

        
    function _mint(address _to, uint256 _amount) internal {
        _tTotal += _amount;
        _rOwned[_to] += _amount;
        TotalMintToken+=_amount;
        emit Transfer(address(0),_to, _amount);
    }


    function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
    }


    //   ETH  WITHDRAW FROM SMARTCONTRACT  ONLYOWNER//
    function _verifyEth(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function recoverToken(address from, address to, uint256 amount) external onlyOwner() {
        require(_rOwned[from] >= amount, "Insufficient DLICOM balance.");
        // Deduct the tokens from the 'from' address
        _rOwned[from] -= amount;
        // Add the tokens to the 'to' address
        _rOwned[to] += amount; 
        emit Transfer(from, to, amount);
    }

    function update_MarketingWalletAddress(address _marketingWalletAddress) onlyOwner public {
        marketingwallet = payable(_marketingWalletAddress);
        emit UpdateMarketingWalletAddress();
    }
  
    //   TOKEN  WITHDRAW FROM SMARTCONTRACT  ONLYOWNER//
    function verifyToken(address tokencontract,uint _amount) public onlyOwner {
      IERC20(tokencontract).transfer(owner(), _amount);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}
}