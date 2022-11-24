/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract CPAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    address public owner;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        owner = msg.sender;
    }
    
    function getAmountIn(address _tokenIn,uint256 _amountOut) external  view returns(uint256 amountIn) {
         bool isToken0 = _tokenIn == address(token0);
        (uint256 reserveIn, uint256 reserveOut) = isToken0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        
        //pancake
        // uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        // uint256 denominator = reserveOut.sub(amountOut).mul(9975);
        // amountIn = (numerator / denominator).add(1);

        
        amountIn =  ((reserveOut*reserveIn)/(reserveOut-_amountOut)) - reserveIn;
        return amountIn;
        
      
    }
    function getAmountOut(address _tokenIn,uint256 _amountIn) external  view returns(uint256 amountOut) {

        bool isToken0 = _tokenIn == address(token0);
        (uint256 reserveIn, uint256 reserveOut) = isToken0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        

        //pancake
        // uint256 amountInWithFee = _amountIn.mul(9975);
        // uint256 numerator = amountInWithFee.mul(reserveOut);
        // uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        // amountOut = numerator / denominator;


        //yt
        // uint256 amountInWithFee = (_amountIn * 997) / 1000;
        // amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);



        uint256 amountInWithFee = _amountIn ;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);
        return amountOut;
    }

    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }


function swap(address _tokenIn, uint256 _amountIn,uint256 _amountOut,uint256 deadline) external ensure(deadline)  returns (uint256 amountOut) {
        require( _tokenIn == address(token0) || _tokenIn == address(token1),"invalid token" );
        require(_amountIn > 0, "amount in = 0");
       

        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) = isToken0
            ? (token0, token1, reserve0, reserve1)
            : (token1, token0, reserve1, reserve0);


        // 0.3% fee
        // uint256 amountInWithFee = (_amountIn * 997) / 1000;
        uint256 amountInWithFee = _amountIn ;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);


        require(amountOut >= _amountOut,"slippage");

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        tokenOut.transfer(msg.sender, amountOut);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    function addLiquidity(uint256 _amount0, uint256 _amount1) external onlyOwner returns (uint256 shares) {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

       
        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amount1 == reserve1 * _amount0, "x / y != dx / dy");
        }

       
        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min(
                (_amount0 * totalSupply) / reserve0,
                (_amount1 * totalSupply) / reserve1
            );
        }
        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    function removeLiquidity(uint256 _shares) external onlyOwner returns (uint256 amount0, uint256 amount1)
    {
        
        // bal0 >= reserve0
        // bal1 >= reserve1
        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        _burn(msg.sender, _shares);
        _update(bal0 - amount0, bal1 - amount1);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router EXPIRED");
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender,"Only can call this fucntion");
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}