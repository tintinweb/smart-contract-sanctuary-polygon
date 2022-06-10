//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * ██╗███╗   ██╗████████╗███████╗██████╗  ██████╗██╗  ██╗ █████╗ ██╗███╗   ██╗███████╗██████╗ 
 * ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██║  ██║██╔══██╗██║████╗  ██║██╔════╝██╔══██╗
 * ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██║     ███████║███████║██║██╔██╗ ██║█████╗  ██║  ██║
 * ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║     ██╔══██║██╔══██║██║██║╚██╗██║██╔══╝  ██║  ██║
 * ██║██║ ╚████║   ██║   ███████╗██║  ██║╚██████╗██║  ██║██║  ██║██║██║ ╚████║███████╗██████╔╝
 * ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═════╝ 
 */

/**
 * SAFEMATH LIBRARY
 */
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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IWETH {
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address dst, uint256 wad) external returns (bool success);
    function transferFrom(address src, address destination, uint256 wad) external returns (bool success);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

/**
 * Uniswap Factory Interface
 */
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
/**
 * Uniswap Pair Interface
 */
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
/**
 * Uniswap Router Interface
 */
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
/**
 * Uniswap Router Interface
 */
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

/**
 * IREFLECT Reflections Interface
 */
interface IREFLECT {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setReflection(address reflectionHolder, uint256 amount) external;
    function process(uint256 gas) external;
    function setBlockMode() external returns(string memory blockTypes);
}

/**
 * Interchained Token Contract
 */
contract Interchained is IREFLECT, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    uint256 public constant MASK = type(uint128).max;

    struct Reflection {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IWETH public WETH_WRAPPER;
    address public WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address[] reflectionHolders;

    string constant _name = "Interchained";
    string constant _symbol = "INT";
    // precision
    uint8 constant _decimals = 9;
    // supply 
    uint256 constant _totalSupply = 1_000_000_000_000 * (10 ** 9);
    uint256 public _maxTxAmount = _totalSupply.div(400); // 0.25%
    uint256 public totalHoldings;
    uint256 public totalReflections;
    uint256 public totalDistributed;
    uint256 public reflectionsPerShare;
    uint256 public reflectionsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 15);
    uint256 currentIndex;
    // mappings
    mapping (address => uint256) reflectionHolderIndexes;
    mapping (address => uint256) reflectionHolderClaims;
    mapping (address => Reflection) public reflections;
    mapping (address => string) public _blockMode;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => bool) public isDonorExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isReflectionExempt;
    mapping (address => bool) public amm;

    address public _owner;
    address public _token;
    mapping (address => bool) public _authorized;
    // operator override block judge phase for x blocks + now
    uint overrideLength = 0;
    // donations 
    uint256 liquidityDonations = 400;
    uint256 buybackDonations = 100;
    uint256 reflectionDonations = 200;
    uint256 teamDonations = 400;
    uint256 totalDonations = 1100;
    uint256 feeDenominator = 10000;
    // liquidity 
    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;
    // buyback
    uint256 buybackNumerator = 200;
    uint256 buybackDenominator = 100;
    uint256 buybackTriggeredAt;
    uint256 buybackLength = 30 minutes;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint autoBuybackBlockPeriod;
    uint autoBuybackBlockLast;
    // gas for processing
    uint256 reflectorGas = 500000;   
    // launch
    uint256 public launchedAt;
    uint256 public launchedAtTimestamp; 
    uint256 public liquifyThreshold = _totalSupply / 2000; // 0.005%
    // uniswap
    IUniswapV2Router02 public router;
    // reflector
    IREFLECT public reflector;
    // addresses
    address public reflectorAddress;
    address public pair;
    address payable public autoLiquidityReceiver;
    address payable public teamDonationsReceiver;
    // bools
    bool public autoBuybackEnabled = false;
    bool public liquifyEnabled = false;
    bool initialized;
    bool inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    event SetAutomatedMarketMakerPair(address pair);
    event RemoveAutomatedMarketMakerPair(address pair);
    event Liquify(uint256 amountETH, uint256 amountLiquidity);
    event AddLiquidity(uint256 amountETH, uint256 amountLiquidity);
    event BuyBack(uint256 amountBuy);
    event BlockPhase(string mode);
    event PhaseOverride(string blockMode, uint256 duration);

    constructor () payable {
        // contract operations
        _token = address(this);
        _owner = msg.sender;
        _authorized[_owner] = true;
        // exchange operations (pair/router/WETH)
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        );
        // Create a uniswap pair for this new token
        pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        router = _uniswapV2Router;
        WETH = address(router.WETH());
        // automated market makers operations
        amm[address(pair)] = true;
        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;
        // reflections operations
        reflector = IREFLECT(address(this));
        reflectorAddress = address(reflector);
        // donations operations
        liquidityDonations = 400;
        buybackDonations = 100;
        reflectionDonations = 200;
        teamDonations = 300;
        totalDonations = 1000; // add up the donations
        feeDenominator = 10000;
        liquifyEnabled = false; // enable post deployment
        autoBuybackEnabled = false;
        // liquidity and team donations operations 
        autoLiquidityReceiver = payable(msg.sender);
        teamDonationsReceiver = payable(msg.sender);
        // transaction / reflections / donations operations 
        isDonorExempt[address(msg.sender)] = true;
        isDonorExempt[address(_token)] = true;
        isDonorExempt[address(teamDonationsReceiver)] = true;
        isDonorExempt[address(autoLiquidityReceiver)] = true;
        isTxLimitExempt[address(msg.sender)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[address(pair)] = true;
        isTxLimitExempt[address(_token)] = true;
        isTxLimitExempt[address(autoLiquidityReceiver)] = true;
        isTxLimitExempt[address(teamDonationsReceiver)] = true;
        isReflectionExempt[address(pair)] = true;
        isReflectionExempt[address(pair)] = true;
        isReflectionExempt[address(router)] = true;
        isReflectionExempt[address(this)] = true;
        isReflectionExempt[address(DEAD)] = true;
        isReflectionExempt[address(_token)] = true;
        isReflectionExempt[address(autoLiquidityReceiver)] = true;
        isReflectionExempt[address(teamDonationsReceiver)] = true;
        initialized = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyToken() {
        require(isToken(msg.sender), "!TOKEN"); _;
    }
    
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function getBlockMode() public view returns(string memory) {
        uint o = block.timestamp;       
        if(o%2==0) {
            return string("heads"); // heads we're even
        } else {
            return string("tails"); // tails, it's odd
        }
    }
    
    function checkBlockType() public view returns(string memory) {
        return _blockMode[address(this)];
    }
    
    function approveWETH() public authorized {
        IERC20(address(this)).approve(address(router), _totalSupply);
        IERC20(address(this)).approve(address(pair), _totalSupply);
        IWETH(WETH).approve(address(this), type(uint).max);
    }
    
    function approveWETHtoClaim(uint amount) public authorized {
        IWETH(router.WETH()).approve(address(this), amount);
    }
    
    function approveERC20Token(address _tok) public authorized {
        IERC20(_tok).approve(address(this), type(uint).max);
    }

    function setBlockMode() external virtual override authorized returns(string memory blockTypes) {
        if(block.number >= overrideLength || overrideLength == 0) {
            if(keccak256(abi.encodePacked(getBlockMode())) == keccak256(abi.encodePacked(string("heads")))) {
                if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Standard")))){
                    blockTypes = string("Reflect");
                    _blockMode[address(this)] = blockTypes;
                } else if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Grow")))){
                    blockTypes = string("Give");
                    _blockMode[address(this)] = blockTypes;
                } else {
                    blockTypes = string("Standard");
                    _blockMode[address(this)] = blockTypes;
                }
            } else if(keccak256(abi.encodePacked(getBlockMode())) == keccak256(abi.encodePacked(string("tails")))) {
                if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Standard")))){
                    blockTypes = string("Give");
                    _blockMode[address(this)] = blockTypes;
                } else if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Reflect")))){
                    blockTypes = string("Grow");
                    _blockMode[address(this)] = blockTypes;
                } else {
                    blockTypes = string("Standard");
                    _blockMode[address(this)] = blockTypes;
                }
            } else {
              blockTypes = string("Standard");
              _blockMode[address(this)] = blockTypes;
            }
            emit BlockPhase(_blockMode[address(this)]);
            return blockTypes;
        }
    }

    function overrideBlockMode(string calldata _mode, uint blocks) public onlyOwner {
        require(blocks < 5400,"blocks TOO LONG, why admin...");
        require(blocks > 0,"blocks NOT ENOUGH, why admin...");
        overrideLength = block.number + blocks;
        if(keccak256(abi.encodePacked(string(_mode))) == keccak256(abi.encodePacked(string("Standard")))){
            _blockMode[address(this)] = string("Standard");
        } else if(keccak256(abi.encodePacked(string(_mode))) == keccak256(abi.encodePacked(string("Reflect")))){
            _blockMode[address(this)] = string("Reflect");
        } else if(keccak256(abi.encodePacked(string(_mode))) == keccak256(abi.encodePacked(string("Give")))){
            _blockMode[address(this)] = string("Give");
        } else if(keccak256(abi.encodePacked(string(_mode))) == keccak256(abi.encodePacked(string("Grow")))){
            _blockMode[address(this)] = string("Grow");
        } else {
            revert();
        }
        emit PhaseOverride(_blockMode[address(this)], blocks); 
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount);
        if(shouldLiquify()){ autoLiquify(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldDonate(sender) ? takeDonations(payable(sender), payable(recipient), amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);
        try reflector.setBlockMode() returns(string memory) {} catch {}
        if(!isReflectionExempt[sender]){ try reflector.setReflection(payable(sender), _balances[sender]) {} catch {} }
        if(!isReflectionExempt[recipient]){ try reflector.setReflection(payable(recipient), _balances[recipient]) {} catch {} }

        try reflector.process(reflectorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function setAMMPair(address marketPair) public onlyOwner {
         amm[address(marketPair)] = true;

         emit SetAutomatedMarketMakerPair(marketPair);
    }
    
    function removeAMMPair(address removeMarketPair) public onlyOwner {
        amm[address(removeMarketPair)] = false;
        
        emit RemoveAutomatedMarketMakerPair(removeMarketPair);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldDonate(address sender) internal view returns (bool) {
        bool donorExempt = isDonorExempt[sender];
        if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Give")))){
            return false;
        } else if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Standard")))){
            if(donorExempt == true) {
                return false;
            } else {
                return true;
            }
        } else if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Reflect")))){
            if(donorExempt == true) {
                return false;
            } else {
                return true;
            }
        } else if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Grow")))){
            if(donorExempt == true) {
                return false;
            } else {
                return true;
            }
        } else {
            return true;
        }
    }

    function getTotalDonations(bool selling) public view returns (uint256) {
        if(selling){
            if (launchedAtTimestamp + 1 days > block.timestamp) {
                return totalDonations.mul(15000).div(feeDenominator);
            } else {
                return totalDonations;
            } 
        }
        return totalDonations;
    }

    function rescueStuckTokens(address _tok, address payable recipient, uint256 amount) public payable onlyOwner {
        uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(this));
        require(amount <= contractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        IERC20(_tok).transfer(recipient, amount);
    }

    function rescueStuckNative(address payable recipient) public payable onlyOwner {
        // get the amount of Ether stored in this contract
        uint contractETHBalance = address(this).balance;
        // rescue Ether to recipient
        (bool success, ) = recipient.call{value: contractETHBalance}("");
        require(success, "Failed to rescue Ether");
    }

    function takeDonations(address payable sender, address payable receiver, uint256 amount) internal returns (uint256) {
        uint256 donationAmount = amount.mul(getTotalDonations(receiver == pair)).div(feeDenominator);
        
        _balances[address(this)] = _balances[address(this)].add(donationAmount);
        emit Transfer(sender, address(this), donationAmount);

        return amount.sub(donationAmount);
    }

    function shouldLiquify() internal view returns (bool) {
        //address from, address to could be added back to detect pair, I do not want conflict 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= liquifyThreshold;
        if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Give")))){
            return false;
        } else if (!inSwap && overMinTokenBalance == true && liquifyEnabled == true) {
            return true;
        } else {
            return false;
        }
    }

    function autoLiquify() public swapping onlyToken payable {
        uint256 amountToLiquify = liquifyThreshold.mul(liquidityDonations).div(totalDonations).div(2);
        uint256 amountToSwap = liquifyThreshold.sub(amountToLiquify);
        uint256 amountToShare = 0;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;
        address swapBeneficiary = address(this);
        if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Reflect")))){
            amountToShare = amountToSwap / 2;
            amountToSwap = amountToSwap - amountToShare;
            swapBeneficiary = address(_msgSender());
        } else if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Give")))){
            amountToShare = amountToSwap / 2;
            amountToSwap = amountToSwap - amountToShare;
            swapBeneficiary = address(_msgSender());
        } else {
            swapBeneficiary = address(this);
        }

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(swapBeneficiary),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHDonation = 0;
        uint256 amountETHLiquidity = 0;
        uint256 amountETHReflection = 0;
        uint256 amountETHTeam = 0;
        if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Standard")))){
            totalETHDonation = totalDonations.sub(liquidityDonations.div(2));
            amountETHLiquidity = amountETH.mul(liquidityDonations).div(totalETHDonation).div(2);
            amountETHReflection = amountETH.mul(reflectionDonations).div(totalETHDonation);
            amountETHTeam = amountETH.mul(teamDonations).div(totalETHDonation);
        } else if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Reflect")))){
            totalETHDonation = totalDonations.sub(liquidityDonations.div(2));
            amountETHLiquidity = amountETH.mul(liquidityDonations).div(totalETHDonation).div(2);
            amountETHTeam = 0;
            amountETHReflection = amountETH * ((reflectionDonations + teamDonations) / totalETHDonation);
        } else if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Grow")))){
            amountETHLiquidity = amountETH;
            totalETHDonation = 0;
            amountETHReflection = 0;
            amountETHTeam = 0;
        } else {
            totalETHDonation = totalDonations.sub(liquidityDonations.div(2));
            amountETHLiquidity = amountETH.mul(liquidityDonations).div(totalETHDonation).div(2);
            amountETHReflection = amountETH.mul(reflectionDonations).div(totalETHDonation);
            amountETHTeam = amountETH.mul(teamDonations).div(totalETHDonation);
        }
        
        IWETH(WETH).deposit{value: amountETHReflection}();
        totalReflections = totalReflections.add(amountETHReflection);
        reflectionsPerShare = reflectionsPerShare.add(reflectionsPerShareAccuracyFactor.mul(amountETHReflection).div(totalHoldings));
        
        if(amountETHTeam > 0){
            payable(teamDonationsReceiver).transfer(amountETHTeam);
        }
        
        if(amountToShare > 0){
            if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Reflect")))){
                IERC20(_token).transfer(payable(swapBeneficiary), amountToShare);
            } else {
                IERC20(_token).transfer(payable(swapBeneficiary), amountToShare);
            }
        }

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AddLiquidity(amountETHLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        uint autoBuyDuration = autoBuybackBlockLast + autoBuybackBlockPeriod;
        bool switchBuyOn = false;
        if(!inSwap && autoBuybackEnabled == true && autoBuybackAmount <= 0){
            switchBuyOn = false;
        } else if(!inSwap && autoBuybackEnabled == true && autoBuyDuration <= block.number && address(this).balance >= autoBuybackAmount) {
            if(keccak256(abi.encodePacked(_blockMode[address(this)])) == keccak256(abi.encodePacked(string("Reflect")))){
              switchBuyOn = true;
            }
        } else {
              switchBuyOn = false;
        }
        return switchBuyOn;
    }

    function triggerManualBuyback(uint256 amount) external authorized {
        buyTokens(amount, address(DEAD));
        autoBuybackBlockLast = block.number;
        buybackTriggeredAt = block.timestamp;
        emit BuyBack(amount);
    }

    function clearBuybackMultiplier() external authorized {
        buybackTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, address(DEAD));
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setupAutoBuyback(bool _enabled, uint256 _cap, uint256 _amount, uint _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setupBuybackMultiplier(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackNumerator = numerator;
        buybackDenominator = denominator;
        buybackLength = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyOwner {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsReflectionExempt(address payable holder, bool status) external authorized {
        require(holder != address(this));
        isReflectionExempt[holder] = status;
        if(status){
            IREFLECT(address(_token)).setReflection(payable(holder), 0);
        }else{
            IREFLECT(address(_token)).setReflection(payable(holder), _balances[holder]);
        }
    }

    function setDonorExempt(address holder, bool status) external authorized {
        isDonorExempt[holder] = status;
    }

    function setIsTxLimitExempt(address holder, bool status) external authorized {
        isTxLimitExempt[holder] = status;
    }

    function setFees(uint256 _liquidityDonations, uint256 _buybackDonations, uint256 _reflectionDonations, uint256 _teamDonations, uint256 _feeDenominator) external authorized {
        liquidityDonations = _liquidityDonations;
        buybackDonations = _buybackDonations;
        reflectionDonations = _reflectionDonations;
        teamDonations = _teamDonations;
        totalDonations = _liquidityDonations.add(_buybackDonations).add(_reflectionDonations).add(_teamDonations);
        feeDenominator = _feeDenominator;
        require(totalDonations < feeDenominator/4);
    }

    function setDonationReceivers(address payable _autoLiquidityReceiver, address payable _teamDonationsReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        teamDonationsReceiver = _teamDonationsReceiver;
    }

    function setLiquifySettings(bool _enabled, uint256 _amount) external authorized {
        liquifyEnabled = _enabled;
        liquifyThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function adjustDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        return IREFLECT(address(_token)).setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setReflectorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        reflectorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(IERC20(address(this)).balanceOf(address(DEAD)));
    }

    function calculateLiquidity(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isLiquid(uint256 target, uint256 accuracy) public view returns (bool) {
        return calculateLiquidity(accuracy) > target;
    }
    
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setReflection(address reflectionHolder, uint256 amount) external override onlyToken {
        if(reflections[reflectionHolder].amount > 0){
            remitReflections(reflectionHolder);
        }

        if(amount > 0 && reflections[reflectionHolder].amount == 0){
            addReflectionHolder(reflectionHolder);
        }else if(amount == 0 && reflections[reflectionHolder].amount > 0){
            removeReflectionHolder(reflectionHolder);
        }

        totalHoldings = totalHoldings.sub(reflections[reflectionHolder].amount).add(amount);
        reflections[reflectionHolder].amount = amount;
        reflections[reflectionHolder].totalExcluded = getCumulativeReflections(reflections[reflectionHolder].amount);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 reflectionHolderCount = reflectionHolders.length;

        if(reflectionHolderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < reflectionHolderCount) {
            if(currentIndex >= reflectionHolderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(reflectionHolders[currentIndex])){
                remitReflections(reflectionHolders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address reflectionHolder) internal view returns (bool) {
        return reflectionHolderClaims[reflectionHolder] + minPeriod < block.timestamp
        && getUndeliveredReflections(reflectionHolder) > minDistribution;
    }

    function remitReflections(address reflectionHolder) internal {
        if(reflections[reflectionHolder].amount == 0){ revert(); }
        require(reflections[reflectionHolder].amount > 0, "Reflections owed: nil; Try again later.");
        uint256 amount = getUndeliveredReflections(reflectionHolder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            IWETH(WETH).approve(reflectionHolder, amount);
            IWETH(WETH).transfer(reflectionHolder, amount);
            reflectionHolderClaims[reflectionHolder] = block.timestamp;
            reflections[reflectionHolder].totalRealised = reflections[reflectionHolder].totalRealised.add(amount);
            reflections[reflectionHolder].totalExcluded = getCumulativeReflections(reflections[reflectionHolder].amount);
        }
    }

    function claimReflections() external {
        remitReflections(msg.sender);
    }

    function getUndeliveredReflections(address reflectionHolder) public view returns (uint256) {
        if(reflections[reflectionHolder].amount == 0){ return 0; }

        uint256 reflectionHolderTotalReflections = getCumulativeReflections(reflections[reflectionHolder].amount);
        uint256 reflectionHolderTotalExcluded = reflections[reflectionHolder].totalExcluded;

        if(reflectionHolderTotalReflections <= reflectionHolderTotalExcluded){ return 0; }

        return reflectionHolderTotalReflections.sub(reflectionHolderTotalExcluded);
    }

    function getCumulativeReflections(uint256 share) internal view returns (uint256) {
        return share.mul(reflectionsPerShare).div(reflectionsPerShareAccuracyFactor);
    }

    function addReflectionHolder(address reflectionHolder) internal {
        reflectionHolderIndexes[reflectionHolder] = reflectionHolders.length;
        reflectionHolders.push(reflectionHolder);
    }

    function removeReflectionHolder(address reflectionHolder) internal {
        reflectionHolders[reflectionHolderIndexes[reflectionHolder]] = reflectionHolders[reflectionHolders.length-1];
        reflectionHolderIndexes[reflectionHolders[reflectionHolders.length-1]] = reflectionHolderIndexes[reflectionHolder];
        reflectionHolders.pop();
    }

    function isToken(address account) public view returns (bool) {
        return account == _token;
    }

    function isAuthorized(address account) public view returns (bool) {
        if(_authorized[account] == true) {
            return true;
        } else {
            return false;
        }
    }

    function authorizeWallet(address wallet) public virtual returns(bool) {
        _authorized[address(wallet)] = true;
        return _authorized[address(wallet)];
    }

    function deAuthorizeWallet(address wallet) public virtual returns(bool) {
        _authorized[address(wallet)] = false;
        return _authorized[address(wallet)];
    }

    function transferOwnership(address newOwner) public virtual onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _authorized[address(_owner)] = false;
        _owner = newOwner;
        _authorized[address(newOwner)] = true;
        autoLiquidityReceiver = payable(newOwner);
        teamDonationsReceiver = payable(newOwner);
        autoBuybackEnabled = false;
        liquifyEnabled = false;
        liquifyThreshold = 0;
        return true;
    }
}