/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// File: Millionaire.sol


pragma solidity ^0.8.8;

// IERC20 interface taken from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// Context abstract contract taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SafeMath library taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
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

// Address library taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// Ownable abstract contract taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
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

// IUniswapV2Pair interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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

// IUniswapV2Router01 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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

// IUniswapV2Router02 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol 
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
contract Millionaire is Context, IERC20, Ownable {
   
    
    using SafeMath for uint256;
    using Address for address;
    
    string private _name     = "Millionaire";
    string private _symbol   = "wrappedMillionaire";
    uint8  private _decimals = 18;
    
    IUniswapV2Router02 public uniswapV2Router; 
    address public uniswapV2Pair;     
    bool currentlySwapping;

    modifier lockSwapping {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    address payable public _marketingAddress = payable(0x81723063eaD5c32C64ED419a95dc916D6B71AaDA); 
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalReflections;                      
    
    uint256 public  _taxFee           = 5;        
    uint256 public  _sellTaxFee       = 8; 
    uint256 public  _whaleSellTaxFee  = 25;  
    uint256 private _previousTaxFee;
    uint256 public  _goldPortionMultiply = 3;     
    uint256 public vSwap = 1;
    uint256 public vWhale = 100;
    uint256 public vGold = 20;
    
    
    uint256 public _tokenSwapThreshold = vSwap * 10**18;       
    uint256 public _whaleSellThreshold = vWhale * 10**18;

    uint private constant DAY = 86400;                        
 
    uint    public _whaleSellTimer     = DAY;                 
    mapping (address => uint256) private _amountSold;
    mapping (address => uint) private _timeSinceFirstSell;
    
    bool    public _enableBuyback        = false;            
    uint256 public _buybackMaticThreshold  = 1 * 10**9 * 10**9;      
    uint256 public _buybackUpperLimit    = 5 * 10**9 * 10**9; 
    uint256 public _buybackMaticPercentage = 100;               
    bool public _enableLiquidity = false;                     
    bool    public  _enableGold       = false;              
    uint256 private _goldPool         = 0;                  
    uint    public  _goldChance       = 100;                 // moi
    uint256 public  _goldThreshold    = 200 * 10**18;
    uint256 public  _goldMinimumSpend = vGold * 10**18;
    address public  _previousWinner;
    uint256 public  _previousWonAmount;
    uint    public  _previousWinTime;
    uint    public  _luckyGold;
    uint256 private _nonce;
    uint256 public  _totalGoldWon;  
    
    event GoldAward(
        address winner,
        uint256 amount,
        uint time
    );
   
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);  

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
  
        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    /**
     * @notice Required to recieve Matic from PancakeSwap V2 Router when swaping
     */
    receive() external payable {}
    

    function withdrawMatic(uint256 amount) public onlyOwner() {
        if(amount == 0) payable(owner()).transfer(address(this).balance);
        else payable(owner()).transfer(amount);
    }
    
    
    function removeDust(address token) public onlyOwner() {
        require(address(this) != address(token), "Cannot withdraw native token");
        IERC20(address(token)).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    function transferMaticToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getTotalReflections() external view returns (uint256) {
        return _totalReflections;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function isExcludedFromReflection(address account) external view returns(bool) {
        return _isExcluded[account];
    }
    
    function getGoldTokens() public view returns (uint256) {
        return tokenFromReflection(_goldPool);
    }
    
    function buybackUpperLimitAmount() external view returns (uint256) {
        return _buybackUpperLimit;
    }
    
    function amountSold(address account) external view returns (uint256) {
        return _amountSold[account];
    }
    
    function getTimeSinceFirstSell(address account) external view returns (uint) {
        return _timeSinceFirstSell[account];
    }
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setSellTaxFeePerecent(uint256 taxFee) external onlyOwner() {
        _sellTaxFee = taxFee;
    }
    
    function setWhaleSellTaxFeePerecent(uint256 taxFee) external onlyOwner() {
        _whaleSellTaxFee = taxFee;
    }
    
    function setSwapNum(uint256 vSwapN) external onlyOwner() {
       vSwap = vSwapN;
       _tokenSwapThreshold = vSwap * 10**18;
   }
    
    function setMarketingAddress(address marketingAddress) external onlyOwner() {
        _marketingAddress = payable(marketingAddress);
    }
    
    function setBuyback(bool b) external onlyOwner() {
        _enableBuyback = b;
    }
    
    function setBuybackMaticThreshold(uint256 maticAmount) external onlyOwner() {
        _buybackMaticThreshold = maticAmount;
    }
    
    function setBuybackUpperLimit(uint256 buybackLimit) external onlyOwner() {
        _buybackUpperLimit = buybackLimit;
    }
    
    function setBuybackMaticPercentage(uint256 percentage) external onlyOwner() {
        _buybackMaticPercentage = percentage;
    }

    function setLiquidity(bool b) external onlyOwner() {
        _enableLiquidity = b;
    }

    function setWhaleNum(uint256 vWhaleN) external onlyOwner() {
       vWhale = vWhaleN;
       _whaleSellThreshold = vWhale * 10**18;
   }
    
    function setWhaleSellTimer(uint time) external onlyOwner() {
        _whaleSellTimer = time;
    }
    
    function setGold(bool b) external onlyOwner() {
        _enableGold = b;
    }
    
    function setGoldChance(uint chance) external onlyOwner() {
        _goldChance = chance;
    }
    
    function setGoldThreshold(uint256 threshold) external onlyOwner() {
        _goldThreshold = threshold;
    }
    
    function setGoldNum(uint256 vGoldN) external onlyOwner() {
       vGold = vGoldN;
       _goldMinimumSpend = vGold * 10**18;
   }
    
    function setGoldPortionMultiply(uint256 goldPortionMultiply) external onlyOwner() {
        _goldPortionMultiply = goldPortionMultiply;
    }
  
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function random() private returns (uint) {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % 1000);
        r = r.add(1);
        _nonce++;
        return r;
    }
    
    function removeAllFees() private {
        if(_taxFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }
    
    function restoreAllFees() private {
        _taxFee = _previousTaxFee;
    }
    
    function calculategoldReward() private returns (uint256) {
        uint256 reward = 0;
        uint256 goldTokens = getGoldTokens();
        if (goldTokens >= _goldThreshold) {
            // Generates a random number between 1 and 1000
            _luckyGold = random(); 
            if(_luckyGold <= _goldChance) {
                reward = goldTokens;
            }
        } 
        return reward;
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
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
    
    function _goldTransfer(address winner, uint256 tAmount) private {
		if (_isExcluded[winner]) {
            _tOwned[winner] = _tOwned[winner].add(tAmount);
		}
		_rOwned[winner] = _rOwned[winner].add(_goldPool); 
        _goldPool = 0;
        _previousWinner = winner;
        _previousWonAmount = tAmount;
        _totalGoldWon = _totalGoldWon.add(_previousWonAmount);
        _previousWinTime = block.timestamp;
        emit GoldAward(winner, tAmount, block.timestamp);
        emit Transfer(address(this), winner, tAmount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(_enableGold && amount >= _goldMinimumSpend && from == uniswapV2Pair) {
            uint256 goldReward = calculategoldReward();
            if (goldReward > 0) {
                _goldTransfer(to, goldReward);
            }
        }
         
        uint256 tokenBalance = balanceOf(address(this));
    
        if (_enableLiquidity && tokenBalance >= _tokenSwapThreshold && !currentlySwapping && from != uniswapV2Pair) {
            tokenBalance = _tokenSwapThreshold;
            swapAndLiquify(tokenBalance);
        }
                
        if (_enableBuyback && !currentlySwapping && to == uniswapV2Pair) {
	        uint256 balance = address(this).balance;
	       
            if (balance > _buybackMaticThreshold) {
                if (balance >= _buybackUpperLimit) {
                    balance = _buybackUpperLimit;
                }
                
                buyBackTokens(balance.mul(_buybackMaticPercentage).div(100));
            }
        }
        
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);

        if (takeFee && to == uniswapV2Pair) {
            
            uint256 fee = _sellTaxFee;
            
            uint delta = block.timestamp.sub(_timeSinceFirstSell[from]);
            
            uint256 newTotal = _amountSold[from].add(amount);
           
            if (delta > 0 && delta < _whaleSellTimer && _timeSinceFirstSell[from] != 0) {
                if (newTotal > _whaleSellThreshold) {
                    fee = _whaleSellTaxFee; 
                }
                _amountSold[from] = newTotal;
            } else if (_timeSinceFirstSell[from] == 0 && newTotal > _whaleSellThreshold) {
                fee = _whaleSellTaxFee;
                _amountSold[from] = newTotal;
            } else {

                _timeSinceFirstSell[from] = block.timestamp;
                _amountSold[from] = amount;
            }
                
            _previousTaxFee = _taxFee;
            _taxFee = fee;
        }
        
        if (!takeFee) {
            removeAllFees();
        }
        
        _tokenTransfer(from, to, amount);
        
        if (!takeFee) {
            restoreAllFees();
        }
        
        if (takeFee && to == uniswapV2Pair) {
            _taxFee = _previousTaxFee;
        }
        
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, _getRate());
       
		if (_isExcluded[sender]) {
		    _tOwned[sender] = _tOwned[sender].sub(tAmount);
		}
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		
		if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		}
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

		if (tFee > 0) {
	    	uint256 tPortion = tFee.div(_taxFee);

            _magicTokens(tPortion);
            
    		_reflectTokens(tPortion);
    	
    		uint256 tGoldPortion = tPortion.mul(_goldPortionMultiply);
            
            _takeTokens(tFee.sub(tPortion).sub(tPortion).sub(tGoldPortion), tGoldPortion);
		}
            
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _magicTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].add(rFee);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tFee);
        }
    }

    function _reflectTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _totalReflections = _totalReflections.add(tFee);
    }
    
    function _takeTokens(uint256 tTakeAmount, uint256 tGolders) private {
        uint256 currentRate = _getRate();
        uint256 rTakeAmount = tTakeAmount.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTakeAmount);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tTakeAmount);
        }
        
        uint256 rGold = tGolders.mul(currentRate);
        _goldPool = _goldPool.add(rGold);
    }
    
    function buyBackTokens(uint256 amount) private lockSwapping {
    	if (amount > 0) {
    	    swapMaticForTokens(amount);
	    }
    }
    
    function swapAndLiquify(uint256 tokenAmount) private lockSwapping {
        // Split the contract balance into the swap portion and the liquidity portion
        uint256 eigth      = tokenAmount.div(8);     // 1/8 of the tokens, used for liquidity
        uint256 swapAmount = tokenAmount.sub(eigth); // 7/8 of the tokens, used to swap for Matic

        uint256 initialBalance = address(this).balance;

        swapTokensForMatic(swapAmount); 

        uint256 receivedMatic = address(this).balance.sub(initialBalance);
        
        uint256 liquidityMatic = receivedMatic.div(7);
        
        addLiquidity(eigth, liquidityMatic);
        
        uint256 marketingMatic = receivedMatic.div(7).mul(4);
        
        transferMaticToAddress(_marketingAddress, marketingMatic);
        
        emit SwapAndLiquify(swapAmount, liquidityMatic, eigth);
    }
    
    function swapTokensForMatic(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH(); // WETH = WBNB on BSC

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp.add(300)
        );
    }
    
    function swapMaticForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // 
            path,
            _marketingAddress, 
            block.timestamp.add(300)
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 maticAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: maticAmount}(
            address(this),
            tokenAmount,
            0, // Take any amount of tokens (ratio varies)
            0, // Take any amount of BNB (ratio varies)
            address(this),
            block.timestamp.add(300)
        );
    }
    
  function reflect(uint256 tAmount) public {
        require(!_isExcluded[_msgSender()], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _totalReflections = _totalReflections.add(tAmount);
    }
}