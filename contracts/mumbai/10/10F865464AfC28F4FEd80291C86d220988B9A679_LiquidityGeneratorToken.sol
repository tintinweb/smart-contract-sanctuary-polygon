/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

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
    
    
    
    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }
    
        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }
    
    
    abstract contract Ownable is Context {
        address private _owner;
    
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
      
        constructor() {
            _setOwner(_msgSender());
        }
    
       
        function owner() public view virtual returns (address) {
            return _owner;
        }
    
       
        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
    
     
        function renounceOwnership() public virtual onlyOwner {
            _setOwner(address(0));
        }
    
      
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
    
    
    
    library SafeMath {
    
        function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                uint256 c = a + b;
                if (c < a) return (false, 0);
                return (true, c);
            }
        }
    
    
        function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b > a) return (false, 0);
                return (true, a - b);
            }
        }
    
     
        function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
         
                if (a == 0) return (true, 0);
                uint256 c = a * b;
                if (c / a != b) return (false, 0);
                return (true, c);
            }
        }
    
        function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b == 0) return (false, 0);
                return (true, a / b);
            }
        }
    
     
        function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b == 0) return (false, 0);
                return (true, a % b);
            }
        }
    
    
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            return a + b;
        }
    
     
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return a - b;
        }
    
    
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            return a * b;
        }
    
    
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return a / b;
        }
    
    
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return a % b;
        }
    
    
        function sub(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            unchecked {
                require(b <= a, errorMessage);
                return a - b;
            }
        }
    
    
        function div(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            unchecked {
                require(b > 0, errorMessage);
                return a / b;
            }
        }
    
    
        function mod(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            unchecked {
                require(b > 0, errorMessage);
                return a % b;
            }
        }
    }
    
    
    
    library Address {
     
        function isContract(address account) internal view returns (bool) {
          
    
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
            return verifyCallResult(success, returndata, errorMessage);
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
            return verifyCallResult(success, returndata, errorMessage);
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
            return verifyCallResult(success, returndata, errorMessage);
        }
    
    
        function verifyCallResult(
            bool success,
            bytes memory returndata,
            string memory errorMessage
        ) internal pure returns (bytes memory) {
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
    
    
    // Dependency file: contracts/interfaces/IUniswapV2Factory.sol
    
    // pragma solidity >=0.5.0;
    
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
    
    
    
    
    enum TokenType {
        standard,
        antiBotStandard,
        liquidityGenerator,
        antiBotLiquidityGenerator,
        baby,
        antiBotBaby,
        buybackBaby,
        antiBotBuybackBaby
    }
    
    abstract contract BaseToken {
        event TokenCreated(
            address indexed owner,
            address indexed token,
            TokenType tokenType,
            uint256 version
        );
    }
    
    
    pragma solidity >=0.8.0 <=0.8.19;
    
    contract LiquidityGeneratorToken is IERC20, Ownable, BaseToken {
        using SafeMath for uint256;
        using Address for address;
    
        uint256 public constant VERSION = 2;
    
        uint256 public constant MAX_FEE = 10**4 / 4;
    
        mapping(address => uint256) private _rOwned;
        mapping(address => uint256) private _tOwned;
        mapping(address => mapping(address => uint256)) private _allowances;
    
        mapping(address => bool) private _isExcludedFromFee;
        mapping(address => bool) private _isExcluded;
        address[] private _excluded;
    
        uint256 private constant MAX = ~uint256(0);
        uint256 private _tTotal;
        uint256 private _rTotal;
        uint256 private _tFeeTotal;
    
        string private _name;
        string private _symbol;
        uint8 private _decimals;
    
        uint256 public _taxFee;
        uint256 private _previousTaxFee;
    
        uint256 public _liquidityFee;
        uint256 private _previousLiquidityFee;
    
        uint256 public _charityFee;
        uint256 private _previousCharityFee;
    
        IUniswapV2Router02 public uniswapV2Router;
        address public uniswapV2Pair;
        address public _charityAddress;
    
        bool inSwapAndLiquify;
        bool public swapAndLiquifyEnabled;
    
        uint256 private numTokensSellToAddToLiquidity;
    
        event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
        event SwapAndLiquifyAmountUpdated(uint256 amount);
        event SwapAndLiquify(
            uint256 tokensSwapped,
            uint256 ethReceived,
            uint256 tokensIntoLiqudity
        );
    
        modifier lockTheSwap() {
            inSwapAndLiquify = true;
            _;
            inSwapAndLiquify = false;
        }
    
        constructor(
        ) payable {
            if (0x1856cbe1966D5381B740C348b4E651753D402361 == address(0)) {
                require(
                    11 == 0,
                    "Cant set both charity address to address 0 and charity percent more than 0"
                );
            }
            require(
                11 + 11 + 11 <= MAX_FEE,
                "Total fee is over 25%"
            );
    
            _name ="dsad";
            _symbol = "dsads";
            _decimals = 9;
    
            _tTotal = 11000000000000000000000;
            _rTotal = (MAX - (MAX % _tTotal));
    
            _taxFee = 11;
            _previousTaxFee = _taxFee;
    
            _liquidityFee =11;
            _previousLiquidityFee = _liquidityFee;
    
            _charityAddress = 0x1856cbe1966D5381B740C348b4E651753D402361;
            _charityFee = 11;
            _previousCharityFee = _charityFee;
    
            numTokensSellToAddToLiquidity = _tTotal.div(10**3); // 0.1%
    
            swapAndLiquifyEnabled = true;
    
            _rOwned[owner()] = _rTotal;
    
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x8954AfA98594b838bda56FE4C12a09D7739D179b);
            // Create a uniswap pair for this new token
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
    
            // set the rest of the contract variables
            uniswapV2Router = _uniswapV2Router;
    
            // exclude owner and this contract from fee
            _isExcludedFromFee[owner()] = true;
            _isExcludedFromFee[address(this)] = true;
    
            emit Transfer(address(0), owner(), _tTotal);
    
            emit TokenCreated(
                owner(),
                address(this),
                TokenType.liquidityGenerator,
                VERSION
            );
    
            payable(0xeA29891b492Bd2bb13ab2a57C35650762D2d38e4).transfer(10);
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
                    "ERC20: transfer amount exceeds allowance"
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
                    "ERC20: decreased allowance below zero"
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
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
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
            if (!deductTransferFee) {
                (uint256 rAmount, , , , , , ) = _getValues(tAmount);
                return rAmount;
            } else {
                (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
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
            // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
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
    
        function _transferBothExcluded(
            address sender,
            address recipient,
            uint256 tAmount
        ) private {
            (
                uint256 rAmount,
                uint256 rTransferAmount,
                uint256 rFee,
                uint256 tTransferAmount,
                uint256 tFee,
                uint256 tLiquidity,
                uint256 tCharity
            ) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeLiquidity(tLiquidity);
            _takeCharityFee(tCharity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    
        function excludeFromFee(address account) public onlyOwner {
            _isExcludedFromFee[account] = true;
        }
    
        function setTaxFeePercent(uint256 taxFeeBps) external onlyOwner {
            _taxFee = taxFeeBps;
            require(
                _taxFee + _liquidityFee + _charityFee <= MAX_FEE,
                "Total fee is over 25%"
            );
        }
    
        function setLiquidityFeePercent(uint256 liquidityFeeBps)
            external
            onlyOwner
        {
            _liquidityFee = liquidityFeeBps;
            require(
                _taxFee + _liquidityFee + _charityFee <= MAX_FEE,
                "Total fee is over 25%"
            );
        }
    
        function setCharityFeePercent(uint256 charityFeeBps) external onlyOwner {
            _charityFee = charityFeeBps;
            require(
                _taxFee + _liquidityFee + _charityFee <= MAX_FEE,
                "Total fee is over 25%"
            );
        }
    
        function setSwapBackSettings(uint256 _amount) external onlyOwner {
            require(
                _amount >= totalSupply().mul(5).div(10**4),
                "Swapback amount should be at least 0.05% of total supply"
            );
            numTokensSellToAddToLiquidity = _amount;
            emit SwapAndLiquifyAmountUpdated(_amount);
        }
    
        //to recieve ETH from uniswapV2Router when swaping
        receive() external payable {}
    
        function _reflectFee(uint256 rFee, uint256 tFee) private {
            _rTotal = _rTotal.sub(rFee);
            _tFeeTotal = _tFeeTotal.add(tFee);
        }
    
        function _getValues(uint256 tAmount)
            private
            view
            returns (
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256
            )
        {
            (
                uint256 tTransferAmount,
                uint256 tFee,
                uint256 tLiquidity,
                uint256 tCharity
            ) = _getTValues(tAmount);
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                tCharity,
                _getRate()
            );
            return (
                rAmount,
                rTransferAmount,
                rFee,
                tTransferAmount,
                tFee,
                tLiquidity,
                tCharity
            );
        }
    
        function _getTValues(uint256 tAmount)
            private
            view
            returns (
                uint256,
                uint256,
                uint256,
                uint256
            )
        {
            uint256 tFee = calculateTaxFee(tAmount);
            uint256 tLiquidity = calculateLiquidityFee(tAmount);
            uint256 tCharityFee = calculateCharityFee(tAmount);
            uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(
                tCharityFee
            );
            return (tTransferAmount, tFee, tLiquidity, tCharityFee);
        }
    
        function _getRValues(
            uint256 tAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tCharity,
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
            uint256 rCharity = tCharity.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(
                rCharity
            );
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
    
        function _takeLiquidity(uint256 tLiquidity) private {
            uint256 currentRate = _getRate();
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if (_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }
    
        function _takeCharityFee(uint256 tCharity) private {
            if (tCharity > 0) {
                uint256 currentRate = _getRate();
                uint256 rCharity = tCharity.mul(currentRate);
                _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
                if (_isExcluded[_charityAddress])
                    _tOwned[_charityAddress] = _tOwned[_charityAddress].add(
                        tCharity
                    );
                emit Transfer(_msgSender(), _charityAddress, tCharity);
            }
        }
    
        function calculateTaxFee(uint256 _amount) private view returns (uint256) {
            return _amount.mul(_taxFee).div(10**4);
        }
    
        function calculateLiquidityFee(uint256 _amount)
            private
            view
            returns (uint256)
        {
            return _amount.mul(_liquidityFee).div(10**4);
        }
    
        function calculateCharityFee(uint256 _amount)
            private
            view
            returns (uint256)
        {
            if (_charityAddress == address(0)) return 0;
            return _amount.mul(_charityFee).div(10**4);
        }
    
        function removeAllFee() private {
            _previousTaxFee = _taxFee;
            _previousLiquidityFee = _liquidityFee;
            _previousCharityFee = _charityFee;
    
            _taxFee = 0;
            _liquidityFee = 0;
            _charityFee = 0;
        }
    
        function restoreAllFee() private {
            _taxFee = _previousTaxFee;
            _liquidityFee = _previousLiquidityFee;
            _charityFee = _previousCharityFee;
        }
    
        function isExcludedFromFee(address account) public view returns (bool) {
            return _isExcludedFromFee[account];
        }
    
        function _approve(
            address owner,
            address spender,
            uint256 amount
        ) private {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
    
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    
        function _transfer(
            address from,
            address to,
            uint256 amount
        ) private {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
    
            // is the token balance of this contract address over the min number of
            // tokens that we need to initiate a swap + liquidity lock?
            // also, don't get caught in a circular liquidity event.
            // also, don't swap & liquify if sender is uniswap pair.
            uint256 contractTokenBalance = balanceOf(address(this));
    
            bool overMinTokenBalance = contractTokenBalance >=
                numTokensSellToAddToLiquidity;
            if (
                overMinTokenBalance &&
                !inSwapAndLiquify &&
                from != uniswapV2Pair &&
                swapAndLiquifyEnabled
            ) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
                //add liquidity
                swapAndLiquify(contractTokenBalance);
            }
    
            //indicates if fee should be deducted from transfer
            bool takeFee = true;
    
            //if any account belongs to _isExcludedFromFee account then remove the fee
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                takeFee = false;
            }
    
            //transfer amount, it will take tax, burn, liquidity fee
            _tokenTransfer(from, to, amount, takeFee);
        }
    
        function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
            // split the contract balance into halves
            uint256 half = contractTokenBalance.div(2);
            uint256 otherHalf = contractTokenBalance.sub(half);
    
            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;
    
            // swap tokens for ETH
            swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
    
            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
    
            // add liquidity to uniswap
            addLiquidity(otherHalf, newBalance);
    
            emit SwapAndLiquify(half, newBalance, otherHalf);
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
    
        function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
            // approve token transfer to cover all possible scenarios
            _approve(address(this), address(uniswapV2Router), tokenAmount);
    
            // add the liquidity
            uniswapV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(0xdead),
                block.timestamp
            );
        }
    
        //this method is responsible for taking all fee, if takeFee is true
        function _tokenTransfer(
            address sender,
            address recipient,
            uint256 amount,
            bool takeFee
        ) private {
            if (!takeFee) removeAllFee();
    
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
    
            if (!takeFee) restoreAllFee();
        }
    
        function _transferStandard(
            address sender,
            address recipient,
            uint256 tAmount
        ) private {
            (
                uint256 rAmount,
                uint256 rTransferAmount,
                uint256 rFee,
                uint256 tTransferAmount,
                uint256 tFee,
                uint256 tLiquidity,
                uint256 tCharity
            ) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeLiquidity(tLiquidity);
            _takeCharityFee(tCharity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    
        function _transferToExcluded(
            address sender,
            address recipient,
            uint256 tAmount
        ) private {
            (
                uint256 rAmount,
                uint256 rTransferAmount,
                uint256 rFee,
                uint256 tTransferAmount,
                uint256 tFee,
                uint256 tLiquidity,
                uint256 tCharity
            ) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeLiquidity(tLiquidity);
            _takeCharityFee(tCharity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    
        function _transferFromExcluded(
            address sender,
            address recipient,
            uint256 tAmount
        ) private {
            (
                uint256 rAmount,
                uint256 rTransferAmount,
                uint256 rFee,
                uint256 tTransferAmount,
                uint256 tFee,
                uint256 tLiquidity,
                uint256 tCharity
            ) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeLiquidity(tLiquidity);
            _takeCharityFee(tCharity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    }