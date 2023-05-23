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

import "./Exchange.sol";

interface IFactory {
    function owner() external view returns (address);
    function treasury() external view returns (address);
    function buyback() external view returns (address);
    function feeShareRate() external view returns (uint);
}

interface ITreasury {
    function claim(address, address) external;
    function updateDistributionIndex(address) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IRouter {
     function sendTokenToExchange(address token, uint amount) external;
}

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

contract ExchangeImpl is Exchange {

    using SafeMath for uint256;
    using UQ112x112 for uint224;

    event Sync(uint112 reserveA, uint112 reserveB);

    function version() external pure returns (string memory) {
        return "ExchangeImpl20220913";
    }

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    constructor() public Exchange(address(0), address(1), 0) {}

    function transfer(address _to, uint _value) public nonReentrant returns (bool) {
        decreaseBalance(_msgSender(), _value);
        increaseBalance(_to, _value);

        emit Transfer(_msgSender(), _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public nonReentrant returns (bool) {
        decreaseBalance(_from, _value);
        increaseBalance(_to, _value);

        allowance[_from][_msgSender()] = allowance[_from][_msgSender()].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address _spender, uint _value) public returns (bool) {
        require(_spender != address(0));
        _approve(_msgSender(), _spender, _value);

        return true;
    }

    function _update() private {
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'OVERFLOW');

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;

        emit Sync(reserve0, reserve1);
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // ======== Change supply & balance ========
    function increaseTotalSupply(uint amount) private {
        ITreasury(getTreasury()).updateDistributionIndex(address(this));
        totalSupply = totalSupply.add(amount);
    }

    function decreaseTotalSupply(uint amount) private {
        ITreasury(getTreasury()).updateDistributionIndex(address(this));
        totalSupply = totalSupply.sub(amount);
    }

    function increaseBalance(address user, uint amount) private {
        giveReward(user);
        balanceOf[user] = balanceOf[user].add(amount);
    }

    function decreaseBalance(address user, uint amount) private {
        giveReward(user);
        balanceOf[user] = balanceOf[user].sub(amount);
    }

    function getTreasury() public view returns (address) {
        return IFactory(factory).treasury();
    }

    function getTokenSymbol(address token) private view returns (string memory) {
        return IERC20(token).symbol();
    }

    function initPool() public {
        require(msg.sender == factory);

        string memory symbolA = getTokenSymbol(token0);
        string memory symbolB = getTokenSymbol(token1);

        name = string(abi.encodePacked(name, " ", symbolA, "-", symbolB));

        decimals = IERC20(token0).decimals();
        WETH = IFactoryImpl(factory).WETH();

        uint chainId = IFactoryImpl(factory).chainId();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

        _update();
    }

    // ======== Administration ========

    event ChangeFee(uint _fee);

    function changeFee(uint _fee) external {
        require(msg.sender == factory);
        require(_fee >= 5 && _fee <= 100);

        fee = _fee;

        emit ChangeFee(_fee);
    }

    event SetPaused(bool b);

    function setPaused(bool b) external {
        require(msg.sender == factory);

        paused = b;

        emit SetPaused(b);
    }

    // ======== Reward ========

    function giveReward(address user) private {
        require(!paused, "IXLP is paused");
        ITreasury(getTreasury()).claim(user, address(this));
    }

    function claimReward() public nonReentrant {
        giveReward(_msgSender());
    }

    function claimReward(address user) public nonReentrant {
        giveReward(user);
    }

    // ======== Exchange ========

    event ExchangePos(address token0, uint amount0, address token1, uint amount1);
    event ExchangeNeg(address token0, uint amount0, address token1, uint amount1);


    function calcPos(uint poolIn, uint poolOut, uint input) private view returns (uint) {
        if (totalSupply == 0) return 0;

        uint num = poolOut.mul(input).mul(uint(10000).sub(fee));
        uint den = poolIn.mul(10000).add(input.mul(uint(10000).sub(fee)));

        return num.div(den);
    }

    function calcNeg(uint poolIn, uint poolOut, uint output) private view returns (uint) {
        if (output >= poolOut) return uint(-1);

        uint num = poolIn.mul(output).mul(10000);
        uint den = poolOut.sub(output).mul(uint(10000).sub(fee));

        return num.ceilDiv(den);
    }

    function getCurrentPool() public view returns (uint, uint) {
        (uint pool0, uint pool1, ) = getReserves();

        return (pool0, pool1);
    }

    function estimatePos(address token, uint amount) public view returns (uint) {
        require(token == token0 || token == token1);

        (uint pool0, uint pool1) = getCurrentPool();

        if (token == token0) {
            return calcPos(pool0, pool1, amount);
        }

        return calcPos(pool1, pool0, amount);
    }

    function estimateNeg(address token, uint amount) public view returns (uint) {
        require(token == token0 || token == token1);

        (uint pool0, uint pool1) = getCurrentPool();

        if (token == token0) {
            return calcNeg(pool1, pool0, amount);
        }

        return calcNeg(pool0, pool1, amount);
    }

    function grabToken(address token, uint amount) private {
        uint userBefore = IERC20(token).balanceOf(_msgSender());
        uint thisBefore = IERC20(token).balanceOf(address(this));

        require(IERC20(token).transferFrom(_msgSender(), address(this), amount), "Exchange: grabToken failed");

        uint userAfter = IERC20(token).balanceOf(_msgSender());
        uint thisAfter = IERC20(token).balanceOf(address(this));

        require(userAfter.add(amount) == userBefore);
        require(thisAfter == thisBefore.add(amount));
    }

    function sendToken(address token, uint amount, address user) private {
        uint userBefore = IERC20(token).balanceOf(user);
        uint thisBefore = IERC20(token).balanceOf(address(this));

        require(IERC20(token).transfer(user, amount), "Exchange: sendToken failed");

        uint userAfter = IERC20(token).balanceOf(user);
        uint thisAfter = IERC20(token).balanceOf(address(this));

        require(userAfter == userBefore.add(amount), "Exchange: user balance not equal");
        require(thisAfter.add(amount) == thisBefore, "Exchange: this balance not equal");
    }

    function exchangePos(address token, uint amount) public nonReentrant returns (uint) {
        require(_msgSender() == router);
        require(!paused, "IXLP is paused");

        require(token == token0 || token == token1);
        require(amount != 0);

        uint output = 0;
        (uint pool0, uint pool1) = getCurrentPool();

        if (token == token0) {
            output = calcPos(pool0, pool1, amount);
            require(output != 0);

            IRouter(router).sendTokenToExchange(token0, amount);
            sendToken(token1, output, router);

            emit ExchangePos(token0, amount, token1, output);

            uint feeShareRate = IFactory(factory).feeShareRate();
            uint exchangeFee = amount.mul(fee).div(10000);
            uint buybackFee = exchangeFee.mul(feeShareRate).div(100);
            address buyback = IFactory(factory).buyback();

            if (buybackFee != 0) {
                sendToken(token0, buybackFee, buyback);
            }
        }
        else {
            output = calcPos(pool1, pool0, amount);
            require(output != 0);

            IRouter(router).sendTokenToExchange(token1, amount);
            sendToken(token0, output, router);

            emit ExchangePos(token1, amount, token0, output);

            uint feeShareRate = IFactory(factory).feeShareRate();
            uint exchangeFee = amount.mul(fee).div(10000);
            uint buybackFee = exchangeFee.mul(feeShareRate).div(100);
            address buyback = IFactory(factory).buyback();

            if (buybackFee != 0) {
                sendToken(token1, buybackFee, buyback);
            }
        }

        _update();

        return output;
    }

    function exchangeNeg(address token, uint amount) public nonReentrant returns (uint) {
        require(_msgSender() == router);
        require(!paused, "IXLP is paused");

        require(token == token0 || token == token1);
        require(amount != 0);

        uint input = 0;
        (uint pool0, uint pool1) = getCurrentPool();

        if (token == token0) {
            input = calcNeg(pool1, pool0, amount);
            require(input != 0);

            IRouter(router).sendTokenToExchange(token1, input);
            sendToken(token0, amount, router);

            emit ExchangeNeg(token1, input, token0, amount);

            uint feeShareRate = IFactory(factory).feeShareRate();
            uint exchangeFee = input.mul(fee).div(10000);
            uint buybackFee = exchangeFee.mul(feeShareRate).div(100);
            address buyback = IFactory(factory).buyback();

            if (buybackFee != 0) {
                sendToken(token1, buybackFee, buyback);
            }
        }
        else {
            input = calcNeg(pool0, pool1, amount);
            require(input != 0);

            IRouter(router).sendTokenToExchange(token0, input);
            sendToken(token1, amount, router);

            emit ExchangeNeg(token0, input, token1, amount);

            uint feeShareRate = IFactory(factory).feeShareRate();
            uint exchangeFee = input.mul(fee).div(10000);
            uint buybackFee = exchangeFee.mul(feeShareRate).div(100);
            address buyback = IFactory(factory).buyback();

            if (buybackFee != 0) {
                sendToken(token0, buybackFee, buyback);
            }
        }

        _update();

        return input;
    }

    // ======== Add/remove Liquidity ========

    event AddLiquidity(address user, address token0, uint amount0, address token1, uint amount1, uint liquidity);
    event RemoveLiquidity(address user, address token0, uint amount0, address token1, uint amount1, uint liquidity);

    function addLiquidity(uint amount0, uint amount1, address user) private returns (uint real0, uint real1, uint amountLP) {
        require(amount0 != 0 && amount1 != 0);
        real0 = amount0;
        real1 = amount1;

        (uint pool0, uint pool1) = getCurrentPool();

        if (totalSupply == 0) {
            grabToken(token0, amount0);
            grabToken(token1, amount1);

            increaseTotalSupply(amount0);
            increaseBalance(user, amount0);

            amountLP = amount0;

            emit AddLiquidity(user, token0, amount0, token1, amount1, amount0);

            emit Transfer(address(0), user, amount0);
        }
        else {
            uint with0 = totalSupply.mul(amount0).div(pool0);
            uint with1 = totalSupply.mul(amount1).div(pool1);

            if (with0 < with1) {
                require(with0 > 0);

                grabToken(token0, amount0);

                real1 = with0.mul(pool1).ceilDiv(totalSupply);
                require(real1 <= amount1);

                grabToken(token1, real1);

                increaseTotalSupply(with0);
                increaseBalance(user, with0);

                amountLP = with0;

                emit AddLiquidity(user, token0, amount0, token1, real1, with0);

                emit Transfer(address(0), user, with0);
            }
            else {
                require(with1 > 0);

                grabToken(token1, amount1);

                real0 = with1.mul(pool0).ceilDiv(totalSupply);
                require(real0 <= amount0);

                grabToken(token0, real0);

                increaseTotalSupply(with1);
                increaseBalance(user, with1);

                amountLP = with1;

                emit AddLiquidity(user, token0, real0, token1, amount1, with1);

                emit Transfer(address(0), user, with1);
            }
        }

        _update();

        return (real0, real1, amountLP);
    }

    // Only support add|RemoveLiquidityWithLimit
    function addTokenLiquidityWithLimit(uint amount0, uint amount1, uint minAmount0, uint minAmount1, address user) public nonReentrant returns (uint real0, uint real1, uint amountLP) {
        (real0, real1, amountLP) = addLiquidity(amount0, amount1, user);
        require(real0 >= minAmount0, "minAmount0 is not satisfied");
        require(real1 >= minAmount1, "minAmount1 is not satisfied");
    }

    function removeLiquidityWithLimit(uint amount, uint minAmount0, uint minAmount1, address user) public nonReentrant returns (uint, uint) {
        require(amount != 0);

        (uint pool0, uint pool1) = getCurrentPool();

        uint amount0 = pool0.mul(amount).div(totalSupply);
        uint amount1 = pool1.mul(amount).div(totalSupply);

        require(amount0 >= minAmount0, "minAmount0 is not satisfied");
        require(amount1 >= minAmount1, "minAmount1 is not satisfied");

        decreaseTotalSupply(amount);
        decreaseBalance(_msgSender(), amount);

        emit Transfer(_msgSender(), address(0), amount);

        if (amount0 > 0) sendToken(token0, amount0, user);
        if (amount1 > 0) sendToken(token1, amount1, user);

        _update();

        emit RemoveLiquidity(_msgSender(), token0, amount0, token1, amount1, amount);

        return (amount0, amount1);
    }


    ////////////////////// Uniswap V2 //////////////////////

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    // force balances to match reserves
    function skim(address to) external nonReentrant {

    }

    function sync() external nonReentrant {
        _update();
    }

    function() payable external {
        require(_msgSender() == WETH);
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