// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./interfaces/ISuperstateFactory.sol";
import "./interfaces/ISuperstatePair.sol";
import "./libraries/CloneLibrary.sol";

contract SuperstateFactory2 {
    using CloneLibrary for address;
    address public feeTo;
    address public feeToSetter;
    address public Implementation;
    address[] public allPairs;
    address public controller;
    event SuperstatePairCreated(
        address,
        address,
        address,
        address,
        address,
        address,
        uint256
    );

    //ist
    constructor(
        address _feeToSetter,
        address _controller,
        address _Implementation
    ) public {
        require(
            _Implementation != address(0),
            "No zero address for _oofImplementation"
        );
        feeToSetter = _feeToSetter;
        controller = _controller;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    mapping(address => mapping(address => mapping(uint256 => address)))
        public getLikePair;
    mapping(address => mapping(address => uint256)) public getLikePairs;
    mapping(address => mapping(address => mapping(address => mapping(address => address))))
        public getPair;

    function newImplementation(address Implementation_) external {
        require(msg.sender == controller, "Only factory owner");
        require(
            Implementation_ != address(0),
            "No zero address for Implementation_"
        );
        Implementation = Implementation_;
    }

    function createPair(
        address tokenA,
        address tokenB,
        address s0,
        address s1
    ) external returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(
            getPair[token0][token1][s0][s1] == address(0),
            "UniswapV2: PAIR_EXISTS"
        ); // single check is sufficient
        pair = Implementation.createClone();
        ISuperstatePair(pair).initialize(token0, token1, s0, s1, controller);
        getPair[token0][token1][s0][s1] = pair;
        getPair[token1][token0][s1][s0] = pair;
        getLikePairs[token0][token1] += 1;
        getLikePair[token0][token1][getLikePairs[token0][token1]] = pair;
        getLikePair[token1][token0][getLikePairs[token1][token0]] = pair;
        allPairs.push(pair);
        emit SuperstatePairCreated(
            token0,
            token1,
            pair,
            s0,
            s1,
            controller,
            allPairs.length
        );
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    //function getPair(address tokenA, address tokenB, address s0, address s1,address controller) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB,address s0,address s1,address controller) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;
import "./IUniswapV2ERC20.sol";


interface ISuperstatePair is IUniswapV2ERC20 {
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
    function s0() external view returns (address);
    function s1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address,address,address,address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly


/**
 * EIP 1167 Proxy Deployment
 * Originally from https://github.com/optionality/clone-factory/
 */
library CloneLibrary {

    function createClone(address target) internal returns (address result) {
        // Reserve 55 bytes for the deploy code + 17 bytes as a buffer to prevent overwriting
        // other memory in the final mstore
        bytes memory cloneBuffer = new bytes(72);
        assembly {
            let clone := add(cloneBuffer, 32)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), shl(96, target))
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }


    function isClone(address target, address query) internal view returns (bool result) {
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), shl(96, target))
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

pragma solidity >=0.5.0;
import "./IERC20.sol";


interface IUniswapV2ERC20 is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

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