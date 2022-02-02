// SPDX-License-Identifier: MIT 
pragma solidity =0.8.11;

import './interfaces/ITakaFactory.sol';
import './TakaPair.sol';
import './interfaces/ITakaPair.sol';

contract TakaFactory is ITakaFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter){
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Taka: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Taka: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Taka: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(TakaPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ITakaPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Taka: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Taka: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: MIT 
pragma solidity =0.8.11;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

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

// SPDX-License-Identifier: MIT 
pragma solidity =0.8.11;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT 
pragma solidity =0.8.11;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT 
pragma solidity >=0.5.0;

interface ITakaPair {

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

// SPDX-License-Identifier: MIT 
pragma solidity >=0.5.0;

interface ITakaLP {
    
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
}

// SPDX-License-Identifier: MIT 
pragma solidity >=0.5.0;

interface ITakaFactory {

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT 
pragma solidity >=0.5.0;

interface ITakaCallee {
    function TakaCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT 
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT 
pragma solidity =0.8.11;

import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/ITakaCallee.sol';
import './interfaces/IERC20.sol';
import './interfaces/ITakaFactory.sol';
import './TakaLP.sol';

contract TakaPair is TakaLP {
    using SafeMath  for uint;
    using UQ112x112 for uint224; //for fractions and decimals

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public tokenA;
    address public tokenB;

    uint112 private reserveA;
    uint112 private reserveB;
    uint32  private blockTimestampLast; 

    uint public priceA_CumulativeLast;
    uint public priceB_CumulativeLast;
    uint public kLast; // reserveA * reserveB, as of immediately after the most recent liquidity event

    //to avoind re-entrancy exploits
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Taka: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserveA, uint112 _reserveB, uint32 _blockTimestampLast) {
        _reserveA = reserveA;
        _reserveB = reserveB;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Taka: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amountA, uint amountB);
    event Burn(address indexed sender, uint amountA, uint amountB, address indexed to);
    event Swap(
        address indexed sender,
        uint amountA_In,
        uint amountB_IN,
        uint amountA_Out,
        uint amountB_Out,
        address indexed to
    );
    event Sync(uint112 reserveA, uint112 reserveB);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _tokenA, address _tokenB) external {
        require(msg.sender == factory, 'Taka: FORBIDDEN'); // sufficient check
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balanceA, uint balanceB, uint112 _reserveA, uint112 _reserveB) private {
        require(balanceA <= type(uint112).max && balanceB <= type(uint112).max, 'Taka: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserveA != 0 && _reserveB != 0) {
            // * never overflows, and + overflow is desired
            priceA_CumulativeLast += uint(UQ112x112.encode(_reserveB).uqdiv(_reserveA)) * timeElapsed;
            priceB_CumulativeLast += uint(UQ112x112.encode(_reserveA).uqdiv(_reserveB)) * timeElapsed;
        }
        reserveA = uint112(balanceA);
        reserveB = uint112(balanceB);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserveA, reserveB);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserveA, uint112 _reserveB) private returns (bool feeOn) {
        address feeTo = ITakaFactory(factory).feeTo();
        uint _kLast = kLast; // gas savings
        if (feeTo != address(0)) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserveA).mul(_reserveB));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserveA, uint112 _reserveB,) = getReserves(); // gas savings
        uint balanceA = IERC20(tokenA).balanceOf(address(this));
        uint balanceB = IERC20(tokenB).balanceOf(address(this));
        uint amountA = balanceA.sub(_reserveA);
        uint amountB = balanceB.sub(_reserveB);

        bool feeOn = _mintFee(_reserveA, _reserveB);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountA.mul(amountB)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amountA.mul(_totalSupply) / _reserveA, amountB.mul(_totalSupply) / _reserveB);
        }
        require(liquidity > 0, 'Taka: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balanceA, balanceB, _reserveA, _reserveB);
        if (feeOn) kLast = uint(reserveA).mul(reserveB); // reserveA and reserveB are up-to-date
        emit Mint(msg.sender, amountA, amountB);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amountA, uint amountB) {
        (uint112 _reserveA, uint112 _reserveB,) = getReserves(); // gas savings
        address _tokenA = tokenA;                                // gas savings
        address _tokenB = tokenB;                                // gas savings
        uint balanceA = IERC20(_tokenA).balanceOf(address(this));
        uint balanceB = IERC20(_tokenB).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserveA, _reserveB);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amountA = liquidity.mul(balanceA) / _totalSupply; // using balances ensures pro-rata distribution
        amountB = liquidity.mul(balanceB) / _totalSupply; // using balances ensures pro-rata distribution
        require(amountA > 0 && amountB > 0, 'Taka: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_tokenA, to, amountA);
        _safeTransfer(_tokenB, to, amountB);
        balanceA = IERC20(_tokenA).balanceOf(address(this));
        balanceB = IERC20(_tokenB).balanceOf(address(this));

        _update(balanceA, balanceB, _reserveA, _reserveB);
        if (feeOn) kLast = uint(reserveA).mul(reserveB); // reserveA and reserveB are up-to-date
        emit Burn(msg.sender, amountA, amountB, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amountA_Out, uint amountB_Out, address to, bytes calldata data) external lock {
        require(amountA_Out > 0 || amountB_Out > 0, 'Taka: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserveA, uint112 _reserveB,) = getReserves(); // gas savings
        require(amountA_Out < _reserveA && amountB_Out < _reserveB, 'Taka: INSUFFICIENT_LIQUIDITY');

        uint balanceA;
        uint balanceB;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _tokenA = tokenA;
        address _tokenB = tokenB;
        require(to != _tokenA && to != _tokenB, 'Taka: INVALID_TO');
        if (amountA_Out > 0) _safeTransfer(_tokenA, to, amountA_Out); // optimistically transfer tokens
        if (amountB_Out > 0) _safeTransfer(_tokenB, to, amountB_Out); // optimistically transfer tokens
        if (data.length > 0) ITakaCallee(to).TakaCall(msg.sender, amountA_Out, amountB_Out, data);
        balanceA = IERC20(_tokenA).balanceOf(address(this));
        balanceB = IERC20(_tokenB).balanceOf(address(this));
        }
        uint amountA_In = balanceA > _reserveA - amountA_Out ? balanceA - (_reserveA - amountA_Out) : 0;
        uint amountB_IN = balanceB > _reserveB - amountB_Out ? balanceB - (_reserveB - amountB_Out) : 0;
        require(amountA_In > 0 || amountB_IN > 0, 'Taka: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balanceAAdjusted = balanceA.mul(1000).sub(amountA_In.mul(3));
        uint balanceBAdjusted = balanceB.mul(1000).sub(amountB_IN.mul(3));
        require(balanceAAdjusted.mul(balanceBAdjusted) >= uint(_reserveA).mul(_reserveB).mul(1000**2), 'Taka: K');
        }

        _update(balanceA, balanceB, _reserveA, _reserveB);
        emit Swap(msg.sender, amountA_In, amountB_IN, amountA_Out, amountB_Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _tokenA = tokenA; // gas savings
        address _tokenB = tokenB; // gas savings
        _safeTransfer(_tokenA, to, IERC20(_tokenA).balanceOf(address(this)).sub(reserveA));
        _safeTransfer(_tokenB, to, IERC20(_tokenB).balanceOf(address(this)).sub(reserveB));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(tokenA).balanceOf(address(this)), IERC20(tokenB).balanceOf(address(this)), reserveA, reserveB);
    }

    //overrides
    
}

// SPDX-License-Identifier: MIT 
pragma solidity =0.8.11;

import './interfaces/ITakaLP.sol';
import './libraries/SafeMath.sol';

contract TakaLP is ITakaLP {
    using SafeMath for uint;

    string public constant name = 'Taka ';
    string public constant symbol = 'UNI-';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public  DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Taka: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Taka: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}