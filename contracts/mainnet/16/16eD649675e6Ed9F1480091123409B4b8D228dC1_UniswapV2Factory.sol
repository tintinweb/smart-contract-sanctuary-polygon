// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

//address constant DELEGATE_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac; // SushiSwap (Ethereum mainnet)
address constant DELEGATE_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // SushiSwap (most but Ethereum mainnet)
bytes constant DELEGATE_INIT_CODE_HASH = hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303";
uint256 constant DELEGATE_NET_FEE = 9970;

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IERC721 {
    event Approval(address indexed owner, address indexed spender, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed spender, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approve(address spender, uint256 tokenId) external;
    function setApprovalForAll(address spender, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "./IERC20.sol";

interface IUniswapV2ERC20 is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event WrapperCreated(address indexed collection, address wrapper, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function getCollection(address wrapper) external view returns (address collection);
    function getWrapper(address collection) external view returns (address wrapper);
    function allWrappers(uint) external view returns (address wrapper);
    function allWrappersLength() external view returns (uint);

    function delegates(address token0, address token1) external view returns (bool);

    function router(address router) external view returns (bool);
    function routerSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function createWrapper(address collection) external returns (address wrapper);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function setRouter(address, bool) external;
    function setRouterSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2ERC20 } from "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
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

    function initialize(address, address, bool, bool) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "./IERC20.sol";

interface IWERC721 is IERC20 {
    event Mint(address indexed from, address indexed to, uint[] tokenIds);
    event Burn(address indexed from, address indexed to, uint[] tokenIds);

    function factory() external view returns (address);
    function collection() external view returns (address);

    function mint(address to, uint[] memory tokenIds) external;
    function burn(address to, uint[] memory tokenIds) external;

    function initialize(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        unchecked {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        unchecked {
        z = uint224(y) * Q112; // never overflows
        }
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        unchecked {
        z = x / uint224(y);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2ERC20 } from "./interfaces/IUniswapV2ERC20.sol";

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    string public constant name = "SweepnFlip LPs";
    string public constant symbol = "SNF-LP";
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
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
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "SweepnFlip: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "SweepnFlip: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "./interfaces/IUniswapV2Pair.sol";
import { IWERC721 } from "./interfaces/IWERC721.sol";
import { UniswapV2Pair } from "./UniswapV2Pair.sol";
import { WERC721 } from "./WERC721.sol";
import { DELEGATE_FACTORY } from "./Delegation.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    mapping(address => address) public getCollection;
    mapping(address => address) public getWrapper;
    address[] public allWrappers;

    mapping(address => mapping(address => bool)) public delegates;

    mapping(address => bool) public router;
    address public routerSetter;

    constructor(address _feeToSetter, address _routerSetter) {
        feeToSetter = _feeToSetter;
        routerSetter = _routerSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function allWrappersLength() external view returns (uint) {
        return allWrappers.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "SweepnFlip: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SweepnFlip: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "SweepnFlip: PAIR_EXISTS"); // single check is sufficient
        bool discrete0 = getCollection[token0] != address(0);
        bool discrete1 = getCollection[token1] != address(0);
        require(!(discrete0 && discrete1), "SweepnFlip: DISCRETE_CLASH");
        if (discrete0 || discrete1) {
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            pair = address(new UniswapV2Pair{salt: salt}());
            IUniswapV2Pair(pair).initialize(token0, token1, discrete0, discrete1);
        } else {
            pair = IUniswapV2Factory(DELEGATE_FACTORY).getPair(tokenA, tokenB);
            if (pair == address(0)) {
                IUniswapV2Factory(DELEGATE_FACTORY).createPair(tokenA, tokenB);
            }
            delegates[token0][token1] = true;
        }
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function createWrapper(address collection) external returns (address wrapper) {
        require(collection != address(0), "SweepnFlip: ZERO_ADDRESS");
        require(getWrapper[collection] == address(0), "SweepnFlip: WRAPPER_EXISTS");
        bytes32 salt = keccak256(abi.encodePacked(collection));
        wrapper = address(new WERC721{salt: salt}());
        IWERC721(wrapper).initialize(collection);
        getCollection[wrapper] = collection;
        getWrapper[collection] = wrapper;
        allWrappers.push(wrapper);
        emit WrapperCreated(collection, wrapper, allWrappers.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "SweepnFlip: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "SweepnFlip: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function setRouter(address _router, bool _enabled) external {
        require(msg.sender == routerSetter, "SweepnFlip: FORBIDDEN");
        router[_router] = _enabled;
    }

    function setRouterSetter(address _routerSetter) external {
        require(msg.sender == routerSetter, "SweepnFlip: FORBIDDEN");
        routerSetter = _routerSetter;
    }

    function _initCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Pair } from "./interfaces/IUniswapV2Pair.sol";
import { UniswapV2ERC20 } from "./UniswapV2ERC20.sol";
import { Math } from "./libraries/Math.sol";
import { UQ112x112 } from "./libraries/UQ112x112.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Callee } from "./interfaces/IUniswapV2Callee.sol";

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    bool public discrete0;
    bool public discrete1;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "SweepnFlip: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SweepnFlip: TRANSFER_FAILED");
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, bool _discrete0, bool _discrete1) external {
        require(msg.sender == factory, "SweepnFlip: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        discrete0 = _discrete0;
        discrete1 = _discrete1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        unchecked {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "SweepnFlip: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
        }
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * uint(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = (rootK * 5) + rootKLast;
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
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0, "SweepnFlip: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * uint(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        if (discrete0) {
                uint residual0 = amount0 % 1e18;
                if (residual0 > 0) {
                        amount0 -= residual0;
                        amount1 += residual0 * (balance1 - amount1) / (balance0 - amount0);
                }
        }
        else
        if (discrete1) {
                uint residual1 = amount1 % 1e18;
                if (residual1 > 0) {
                        amount1 -= residual1;
                        amount0 += residual1 * (balance0 - amount0) / (balance1 - amount1);
                }
        }
        require(amount0 > 0 && amount1 > 0, "SweepnFlip: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * uint(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "SweepnFlip: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "SweepnFlip: INSUFFICIENT_LIQUIDITY");

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, "SweepnFlip: INVALID_TO");
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "SweepnFlip: INSUFFICIENT_INPUT_AMOUNT");
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0 * 100 - amount0In * 1;
        uint balance1Adjusted = balance1 * 100 - amount1In * 1;
        require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * uint(_reserve1) * 100**2, "SweepnFlip: K");
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IWERC721 } from "./interfaces/IWERC721.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";

contract WERC721 is IWERC721 {
    string public constant name = "Wrapped NFT";
    string public constant symbol = "WNFT";
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public factory;
    address public collection;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "SweepnFlip: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyRouter() {
        require(IUniswapV2Factory(factory).router(msg.sender), "SweepnFlip: FORBIDDEN");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _collection) external {
        require(msg.sender == factory, "SweepnFlip: FORBIDDEN"); // sufficient check
        collection = _collection;
    }

    function _mint(address from, address to, uint[] memory tokenIds) private {
        uint count = tokenIds.length;
        uint value = count * 1e18;
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
        for (uint i = 0; i < count; i++) {
            IERC721(collection).transferFrom(from, address(this), tokenIds[i]);
        }
        emit Mint(from, to, tokenIds);
    }

    function _burn(address from, address to, uint[] memory tokenIds) private {
        uint count = tokenIds.length;
        uint value = count * 1e18;
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
        for (uint i = 0; i < count; i++) {
            IERC721(collection).transferFrom(address(this), to, tokenIds[i]);
        }
        emit Burn(from, to, tokenIds);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(value % 1e18 == 0, "SweepnFlip: PARTIAL_AMOUNT");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function mint(address to, uint[] memory tokenIds) external onlyRouter lock {
        _mint(msg.sender, to, tokenIds);
    }

    function burn(address to, uint[] memory tokenIds) external onlyRouter lock {
        _burn(msg.sender, to, tokenIds);
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }
}