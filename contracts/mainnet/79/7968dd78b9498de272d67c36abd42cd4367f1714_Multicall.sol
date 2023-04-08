/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Multicall {
    address private _owner;
    uint public amOut;
    address public tOut;

    constructor(){
        _owner = msg.sender;
    }

    struct Route{
        uint amIn;
        uint amOut;
        address tIn;
        address tOut;
        bytes[] callPath;
    }

    modifier owner(){
        require (tx.origin==_owner);_;
    }

    function uniswapV3SwapCallback(int256,int256,bytes calldata ) external{
        transfer(tOut,msg.sender, amOut);
    }

    function swapCallback(int256,int256,bytes calldata ) external{
        transfer(tOut,msg.sender, amOut);
    }

    function uniV2Swap(address pool,address _tOut) public{
        bool direc=tOut<_tOut;
        (uint112 reserve0,uint112 reserve1,) = IUniV2Pool(pool).getReserves();
        transfer(tOut, pool, amOut);
        uint amInWithFee = amOut*997;
        amOut = (direc ? ((amInWithFee*reserve1) / (reserve0*1000+amInWithFee)) : ((amInWithFee*reserve0) / (reserve1*1000+amInWithFee)))+1;
        IUniV2Pool(pool).swap(direc ? 0: amOut, direc ? amOut: 0, address(this),"");
        tOut=_tOut;
    }

    function uniV3Swap(address pool,address _tOut) public{
        bool direc=tOut<_tOut;
        (int am0,int am1)=IUniV3Pool(pool).swap(address(this),direc,int(amOut),direc ? 4295128740 : 1461446703485210103287273052203988822378723970341, "");
        amOut=uint(-(direc ? am1 : am0));
        tOut=_tOut;
    }

    function kyberV3Swap(address pool,address _tOut) public{
        bool direc=tOut<_tOut;
        (int am0,int am1)=IKyberV3Pool(pool).swap(address(this),int(amOut),direc,direc ? 4295128740 : 1461446703485210103287273052203988822378723970341, "");
        amOut=uint(-(direc ? am1 : am0));
        tOut=_tOut;
    }

    function transfer(address token ,address recipient,uint amount) public owner{
        IERC20(token).transfer(recipient, amount);
    }

    function multicall(Route calldata route)public returns(uint){
        amOut=route.amIn;
        tOut=route.tIn;
        for (uint i = 0; i < route.callPath.length; i++)
            address(this).call(route.callPath[i]);
        require (tOut==route.tOut,"tOut");
        require (amOut>=route.amOut,"amOut");
        return amOut;
    }
}

interface IUniV2Pool {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniV3Pool {
    function swap(address recipient,bool zeroForOne,int256 amountSpecified,uint160 sqrtPriceLimitX96,bytes calldata data) external returns (int256 amount0, int256 amount1);
}

interface IKyberV3Pool {
    function swap(address recipient,int256 swapQty,bool isToken0,uint160 limitSqrtP,bytes calldata data) external returns (int256 amount0, int256 amount1);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address owner,address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}