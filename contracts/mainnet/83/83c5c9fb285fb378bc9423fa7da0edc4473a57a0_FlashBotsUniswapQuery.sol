/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

pragma experimental ABIEncoderV2;

 struct Token {
        string name;
        string symbol;
        uint8 decimals;
}


interface ERC20Token {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

abstract contract UniswapV2Factory  {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    function allPairsLength() external view virtual returns (uint);
}

contract FlashBotsUniswapQuery {

    function getBalanceByTokens(ERC20Token[] calldata _tokens, address account) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_tokens.length);
        for(uint i = 0; i< _tokens.length; i++) {
            result[i] = _tokens[i].balanceOf(account);
        }
        return result;
    }

   
    function getTokensByAddresses(ERC20Token[] calldata _tokens) external view returns (Token[] memory) {
        Token[] memory result = new Token[](_tokens.length);
        for(uint i = 0; i < _tokens.length; i++) {
            result[i].name = _tokens[i].name();
            result[i].symbol = _tokens[i].symbol();
            result[i].decimals = _tokens[i].decimals();
        }
        return result;
    }

    function getReservesByPairs(IUniswapV2Pair[] calldata _pairs) external view returns (uint256[3][] memory) {
        uint256[3][] memory result = new uint256[3][](_pairs.length);
        for (uint i = 0; i < _pairs.length; i++) {
            (result[i][0], result[i][1], result[i][2]) = _pairs[i].getReserves();
        }
        return result;
    }

    function getPairsByIndexRange(UniswapV2Factory _uniswapFactory, uint256 _start, uint256 _stop) external view returns (address[3][] memory)  {
        uint256 _allPairsLength = _uniswapFactory.allPairsLength();
        if (_stop > _allPairsLength) {
            _stop = _allPairsLength;
        }
        require(_stop >= _start, "start cannot be higher than stop");
        uint256 _qty = _stop - _start;
        address[3][] memory result = new address[3][](_qty);
        for (uint i = 0; i < _qty; i++) {
            IUniswapV2Pair _uniswapPair = IUniswapV2Pair(_uniswapFactory.allPairs(_start + i));
            result[i][0] = _uniswapPair.token0();
            result[i][1] = _uniswapPair.token1();
            result[i][2] = address(_uniswapPair);
        }
        return result;
    }
}