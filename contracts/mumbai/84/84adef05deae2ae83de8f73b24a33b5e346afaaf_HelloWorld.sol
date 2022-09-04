/**
 *Submitted for verification at polygonscan.com on 2022-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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

contract HelloWorld {
    struct TokenInfo {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint256 balance;
    }

    function getTokens(uint256 start, uint256 count) public view returns (address[] memory) {
        address[] memory a = new address[](count*2);
        for (uint i = start; i < start+count; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32).allPairs(i));
            a[i*2] = pair.token0();
            a[i*2+1] = pair.token1();
        }
        return a;
    }

    function getBalancesForTokens(address[] memory tokens, address holder) public view returns (TokenInfo[] memory) {
        TokenInfo[] memory a = new TokenInfo[](tokens.length);
        for(uint256 i=0;i<tokens.length;i++) {
            IUniswapV2ERC20 erc20 = IUniswapV2ERC20(tokens[i]);
            try erc20.balanceOf(holder) returns (uint256 balance) {
                if(balance > 0) {
                    a[i] = TokenInfo(tokens[i], erc20.name(), erc20.symbol(), erc20.decimals(), balance);
                }
            } catch {}
        }
        return a;
    }

    
    function getBalancesForTokenRange(address holder, uint256 start, uint256 count) external view returns (TokenInfo[] memory) {
        return getBalancesForTokens(getTokens(start, count), holder);
    }
}