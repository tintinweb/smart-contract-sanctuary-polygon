/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Multicall {
    address private _owner;
    uint public amOut;
    address public tOut;
    address[] private uniV3Factories=[0x1F98431c8aD98523631AE4a59f267346ea31F984];
    address[] private kyberV3Factories=[0x5F1dddbf348aC2fbe22a163e30F99F9ECE3DD50a];
    address[] private uniV2Factories=[0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32, 0xc35DADB65012eC5796536bD9864eD8773aBc74C4 ,0xCf083Be4164828f00cAE704EC15a36D711491284, 0x477Ce834Ae6b7aB003cCe4BC4d8697763FF456FA];

    constructor(){
        _owner = msg.sender;
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

    function multicall(address _tIn, address _tOut,uint _amIn,uint _amOut,bytes[] calldata callPath)public returns(uint){
        amOut=_amIn;
        tOut=_tIn;
        for (uint i = 0; i < callPath.length; i++)
            address(this).call(callPath[i]);
        require (tOut==_tOut,"tOut");
        require (amOut>=_amOut,"amOut");
        return amOut;
    }

    function setUniV3Factories(address[] calldata factories) public owner{
        uniV3Factories=factories;
    }

    function setKyberV3Factories(address[] calldata factories) public owner{
        kyberV3Factories=factories;
    }

    function setUniV2Factories(address[] calldata factories) public owner{
        uniV2Factories=factories;
    }

    function poolImmutables(address pool)public view returns (address t0,address t1,uint24 fee,string memory functionName){
        for(uint i=0;i<uniV3Factories.length;i++)
            if(IPool(pool).factory()== uniV3Factories[i])
                return (IUniV3Pool(pool).token0(), IUniV3Pool(pool).token1(),IUniV3Pool(pool).fee(),"uniV3Swap");
        for(uint i=0;i<kyberV3Factories.length;i++)
            if(IPool(pool).factory()== kyberV3Factories[i])
                return (IKyberV3Pool(pool).token0(), IKyberV3Pool(pool).token1(),IKyberV3Pool(pool).swapFeeUnits()*10,"kyberV3Swap");
        for(uint i=0;i<uniV2Factories.length;i++)
            if (IPool(pool).factory()== uniV2Factories[i])
                return (IUniV2Pool(pool).token0(),IUniV2Pool(pool).token1(),3000,"uniV2Swap");
    }
}

interface IPool{
    function factory() external view returns (address);
}

interface IUniV2Pool {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniV3Pool {
    function swap(address recipient,bool zeroForOne,int256 amountSpecified,uint160 sqrtPriceLimitX96,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

interface IKyberV3Pool {
    function swap(address recipient,int256 swapQty,bool isToken0,uint160 limitSqrtP,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swapFeeUnits() external view returns (uint24);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address owner,address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}