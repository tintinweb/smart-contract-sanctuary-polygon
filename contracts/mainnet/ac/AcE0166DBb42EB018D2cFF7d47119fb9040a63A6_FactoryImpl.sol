pragma solidity 0.5.6;

contract EIP2771Recipient {

    address private _trustedForwarder;

    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function trustedForwarder() public view returns (address) {
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal view returns (bytes memory ret) {
        if (isTrustedForwarder(msg.sender)) {
            uint256 actualDataLength = msg.data.length - 20;
            bytes memory actualData = new bytes(actualDataLength);

            for (uint256 i = 0; i < actualDataLength; ++i) {
                actualData[i] = msg.data[i];
            }

            ret = actualData;
        } else {
            ret = msg.data;
        }
    }
}

// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "./EIP2771Recipient.sol";

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
    function router() external view returns (address);
    function chainId() external view returns (uint);
}

contract Exchange is EIP2771Recipient {
    // ======== ERC20 =========
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed holder, address indexed spender, uint amount);

    string public name = "IXswap LP";
    string public constant symbol = "IXLP";
    uint8 public decimals = 18;

    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public factory;
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

    bool public entered;

    /////////////////////// Uniswap V2 Compatible ///////////////////////
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;
    /////////////////////////////////////////////////////////////////////

    bool public paused;

    constructor(address _token0, address _token1, uint _fee) public {
        factory = msg.sender;

        if (_token0 != address(0)) {
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

// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "./Exchange.sol";
import "./Factory.sol";

interface IExchange {
    function changeFee(uint _fee) external;
    function initPool() external;
    function setPaused(bool b) external;
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

    constructor() public Factory(address(0), address(0), address(0), address(0), 0) { }

    function version() public pure returns (string memory) {
        return "FactoryImpl20220901";
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    event ChangeNextOwner(address nextOwner);
    event ChangeOwner(address owner);
    event ChangeFeeShareRate(uint feeShareRate);
    event SetRouter(address router);
    event SetTreasury(address treasury);
    event SetTrustedForwarder(address forwarder);
    event SetBuyback(address buyback);
    event SetEmergencyPaused(bool b);
    event SetPoolPaused(address pool, bool b);

    function changeNextOwner(address _nextOwner) public onlyOwner {
        nextOwner = _nextOwner;

        emit ChangeNextOwner(_nextOwner);
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);
        owner = nextOwner;
        nextOwner = address(0);

        emit ChangeOwner(owner);
    }

    function changePoolFee(address token0, address token1, uint fee) public onlyOwner {
        require(fee >= 5 && fee <= 100);

        address exc = tokenToPool[token0][token1];
        require(exc != address(0));

        IExchange(exc).changeFee(fee);
    }

    function changeBuyback(address _buyback) public onlyOwner {
        buyback = _buyback;

        emit SetBuyback(_buyback);
    }

    function changeFeeShareRate(uint _rate) public onlyOwner {
        require(_rate <= 100);

        feeShareRate = _rate;

        emit ChangeFeeShareRate(_rate);
    }

    function setRouter(address _router) public onlyOwner {
        router = _router;

        emit SetRouter(_router);
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;

        emit SetTreasury(_treasury);
    }

    function setTrustedForwarder(address forwarder) public onlyOwner {
        _setTrustedForwarder(forwarder);

        emit SetTrustedForwarder(forwarder);
    }

    function setEmergencyPaused(bool b) public onlyOwner {
        emergencyPaused = b;

        emit SetEmergencyPaused(b);
    }

    function setPoolPaused(address pool, bool b) public onlyOwner {
        require(poolExist[pool]);
        IExchange(pool).setPaused(b);

        emit SetPoolPaused(pool, b);
    }

    // ======== Create Pool ========

    event CreatePool(address token0, uint amount0, address token1, uint amount1, uint fee, address exchange, uint exid);

    function createPool(address token0, uint amount0, address token1, uint amount1, uint fee, bool isETH) private {
        require(amount0 != 0 && amount1 != 0);
        require(tokenToPool[token0][token1] == address(0), "Pool already exists");
        require(token0 != address(0));
        require(fee >= 5 && fee <= 100);

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

    function createETHPool(address token, uint amount, uint fee) public payable onlyOwner nonReentrant {
        uint amountWETH = msg.value;
        IWETH(WETH).deposit.value(msg.value)();
        createPool(WETH, amountWETH, token, amount, fee, true);
    }

    function createTokenPool(address token0, uint amount0, address token1, uint amount1, uint fee) public onlyOwner nonReentrant {
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

// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "./EIP2771Recipient.sol";

contract Factory is EIP2771Recipient {
    // ======== Construction & Init ========
    address public owner;
    address public nextOwner;
    address payable public implementation;
    address payable public exchangeImplementation;
    address payable public WETH;
    address public router;
    address public treasury;
    address public buyback;

    uint public feeShareRate;

    // ======== Pool Info ========
    address[] public pools;
    mapping(address => bool) public poolExist;

    mapping(address => mapping(address => address)) public tokenToPool;

    // ======== Administration ========

    bool public entered;
    uint public chainId;
    bool public emergencyPaused;

    constructor(
        address payable _implementation,
        address payable _exchangeImplementation,
        address payable _WETH,
        address _buyback,
        uint _chainId
    ) public {
        owner = msg.sender;
        implementation = _implementation;
        exchangeImplementation = _exchangeImplementation;

        WETH = _WETH;
        buyback = _buyback;
        chainId = _chainId;
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