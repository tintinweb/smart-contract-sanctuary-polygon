/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

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

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function burn(uint amount) external;
}

interface IFactoryImpl {
    function getExchangeImplementation() external view returns (address);
    function WETH() external view returns (address payable);
    function mesh() external view returns (address);
    function router() external view returns (address);
}

contract Exchange {
    // ======== ERC20 =========
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed holder, address indexed spender, uint amount);

    string public name = "Meshswap LP";
    string public constant symbol = "MSLP";
    uint8 public decimals = 18;

    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public factory;
    address public mesh;
    address public router;
    address payable public WETH;
    address public token0;
    address public token1;

    uint112 public reserve0;
    uint112 public reserve1;
    uint32 public blockTimestampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; 
    uint balance0;
    uint balance1;

    uint public fee;

    uint public mining;

    uint public lastMined;
    uint public miningIndex;

    mapping(address => uint) public userLastIndex;
    mapping(address => uint) public userRewardSum;
    
    bool public entered;    

    // ======== Uniswap V2 Compatible ========
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    // ======== Construction & Init ========
    constructor(address _token0, address _token1, uint _fee) public {
        factory = msg.sender;
        
        if (_token0 != address(0)) {
            mesh = IFactoryImpl(msg.sender).mesh();
            router = IFactoryImpl(msg.sender).router();
        }
        
        require(_token0 != _token1);

        token0 = _token0;
        token1 = _token1;

        require(_fee <= 100);
        fee = _fee;
    }

    function () payable external {
        address impl = IFactoryImpl(factory).getExchangeImplementation();
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract Factory {
    // ======== Construction & Init ========
    address public owner;
    address public nextOwner;
    address payable public implementation;
    address payable public exchangeImplementation;
    address payable public WETH;
    address public mesh;
    address public router;

    // ======== Pool Info ========
    address[] public pools;
    mapping(address => bool) public poolExist;

    mapping(address => mapping(address => address)) public tokenToPool;

    // ======== Administration ========

    uint public createFee;
    bool public entered;

    constructor(
        address payable _implementation, 
        address payable _exchangeImplementation, 
        address payable _mesh, 
        address payable _WETH
    ) public {
        owner = msg.sender;
        implementation = _implementation;
        mesh = _mesh;
        exchangeImplementation = _exchangeImplementation;

        WETH = _WETH;
    }
    
    function _setImplementation(address payable _newImp) public {
        require(msg.sender == owner);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function _setExchangeImplementation(address payable _newExImp) public {
        require(msg.sender == owner);
        require(exchangeImplementation != _newExImp);
        exchangeImplementation = _newExImp;
    }

    function getExchangeImplementation() public view returns (address) {
        return exchangeImplementation;
    }

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}


// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

interface IExchange {
    function changeFee(uint _fee) external;
    function initPool() external;
    function exchangePos(address token, uint amount) external returns (uint);
    function exchangeNeg(address token, uint amount) external returns (uint);
    function estimatePos(address token, uint amount) external view returns (uint);
    function estimateNeg(address token, uint amount) external view returns (uint);
    function addTokenLiquidityWithLimit(uint amount0, uint amount1, uint minAmount0, uint minAmount1, address user) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IRouter {
    function approvePair(address pair, address token0, address token1) external;
}

contract FactoryImpl is Factory {
    using SafeMath for uint256;

    constructor() public Factory(address(0), address(0), address(0), address(0)) { }

    function version() public pure returns (string memory) {
        return "FactoryImpl20220322";
    }

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    event ChangeCreateFee(uint _createFee);

    event ChangeNextOwner(address nextOwner);
    event ChangeOwner(address owner);
    event SetRouter(address router);

    function changeNextOwner(address _nextOwner) public {
        require(msg.sender == owner);
        nextOwner = _nextOwner;

        emit ChangeNextOwner(_nextOwner);
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);
        owner = nextOwner;
        nextOwner = address(0);

        emit ChangeOwner(owner);
    }

    function changeCreateFee(uint _createFee) public {
        require(msg.sender == owner);
        createFee = _createFee;

        emit ChangeCreateFee(_createFee);
    }

    function changePoolFee(address token0, address token1, uint fee) public {
        require(msg.sender == owner);

        require(fee >= 5 && fee <= 100);

        address exc = tokenToPool[token0][token1];
        require(exc != address(0));

        IExchange(exc).changeFee(fee);
    }

    function setRouter(address _router) public {
        require(msg.sender == owner);
        router = _router;

        emit SetRouter(_router);
    }
    // ======== Create Pool ========

    event CreatePool(address token0, uint amount0, address token1, uint amount1, uint fee, address exchange, uint exid);

    function createPool(address token0, uint amount0, address token1, uint amount1, uint fee, bool isETH) private {
        require(amount0 != 0 && amount1 != 0);
        require(tokenToPool[token0][token1] == address(0), "Pool already exists");
        require(token0 != address(0));
        require(fee >= 5 && fee <= 100);

        if (createFee != 0) {
            require(IERC20(mesh).transferFrom(msg.sender, address(this), createFee));
            IERC20(mesh).burn(createFee);
        }

        Exchange exc = new Exchange(token0, token1, fee);

        poolExist[address(exc)] = true;
        IExchange(address(exc)).initPool();
        pools.push(address(exc));

        tokenToPool[token0][token1] = address(exc);
        tokenToPool[token1][token0] = address(exc);

        if (!isETH) {
            IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        }
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        IERC20(token0).approve(address(exc), amount0);
        IERC20(token1).approve(address(exc), amount1);

        IExchange(address(exc)).addTokenLiquidityWithLimit(amount0, amount1, 1, 1, msg.sender);
        IRouter(router).approvePair(address(exc), token0, token1);

        emit CreatePool(token0, amount0, token1, amount1, fee, address(exc), pools.length - 1);
    }

    function createETHPool(address token, uint amount, uint fee) public payable nonReentrant {
        uint amountWETH = msg.value;
        IWETH(WETH).deposit.value(msg.value)();
        createPool(WETH, amountWETH, token, amount, fee, true);
    }

    function createTokenPool(address token0, uint amount0, address token1, uint amount1, uint fee) public nonReentrant {
        require(token0 != token1);
        require(token1 != WETH);

        createPool(token0, amount0, token1, amount1, fee, false);
    }

    // ======== API ========

    function getPoolCount() public view returns (uint) {
        return pools.length;
    }

    function getPoolAddress(uint idx) public view returns (address) {
        require(idx < pools.length);
        return pools[idx];
    }

    // ======== For Uniswap Compatible ========

    function getPair(address tokenA, address tokenB) public view returns (address pair) {
        return tokenToPool[tokenA][tokenB];
    }

    function allPairsLength() external view returns (uint) {
        return getPoolCount();
    }

    function allPairs(uint idx) external view returns (address pair) {
        pair = getPoolAddress(idx);
    }

    
    function() payable external { revert(); }
}