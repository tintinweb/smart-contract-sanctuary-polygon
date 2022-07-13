/**
 *Submitted for verification at polygonscan.com on 2022-07-12
*/

pragma solidity >=0.7.0 <0.9.0;


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


interface IUniswapV2ERC20 {
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
}
 

contract PairReader {

    function getPairs(address factory, uint[] memory _indexes) public view returns (address[] memory, address[] memory) {
        // get addresses
        uint len = _indexes.length;
        address[] memory t0s = new address[](len);
        address[] memory t1s = new address[](len);
        uint totLen = IUniswapV2Factory(factory).allPairsLength();
        for(uint i=0; i<_indexes.length; i++) {
            uint idx = _indexes[i];
            if (idx < totLen) {
                address pair = IUniswapV2Factory(factory).allPairs(i);
                t0s[i] = IUniswapV2Pair(pair).token0();
                t1s[i] = IUniswapV2Pair(pair).token1();
            } else {
                t0s[i] = address(0);
                t1s[i] = address(0);
            }
        }
        return (t0s, t1s);
    }

    function getLiqs(address factory, uint[] memory _indexes) public view returns (uint[] memory, uint[] memory) {
        // get addresses
        uint len = _indexes.length;
        uint[] memory t0s = new uint[](len);
        uint[] memory t1s = new uint[](len);
        uint totLen = IUniswapV2Factory(factory).allPairsLength();
        for(uint i=0; i<_indexes.length; i++) {
            uint idx = _indexes[i];
            if (idx < totLen) {
                uint32 blockTimestampLast;
                address pair = IUniswapV2Factory(factory).allPairs(i);
                (t0s[i], t1s[i], blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
            } else {
                t0s[i] = 0;
                t1s[i] = 0;
            }
        }
        return (t0s, t1s);
    }
}