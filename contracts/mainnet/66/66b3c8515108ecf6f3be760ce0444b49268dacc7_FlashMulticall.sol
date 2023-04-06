/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FlashMulticall {
    address private _owner;
    uint private amOut;
    address private tOut;
    constructor(){
        _owner = msg.sender;
    }

    modifier owner(){
        require (msg.sender==_owner);_;
    }

    function uniswapV3SwapCallback(int256,int256,bytes calldata ) external {
        IERC20(tOut).transfer(msg.sender, amOut);
    }

    function swapCallback(int256,int256,bytes calldata ) external {
        IERC20(tOut).transfer(msg.sender, amOut);
    }

    function uniV2Swap(address pool,address _tOut)public{
        bool direc=tOut<_tOut;
        (uint reserve0,uint reserve1,) = IUniV2Pool(pool).getReserves();
        (uint reserveOut,uint reserveIn)=(direc ? (reserve1,reserve0) : (reserve0,reserve1));
        uint amInWithFee = amOut*997;
        IERC20(tOut).transfer(pool, amOut);
        amOut = (amInWithFee*reserveOut) / (reserveIn*1000+amInWithFee);
        IUniV2Pool(pool).swap(direc ? 0: amOut, direc ? amOut: 0, address(this),"");
        tOut=_tOut;
    }

    function uniV3Swap(address pool,address _tOut)public{
        bool direc=tOut<_tOut;
        (int am0,int am1)=IUniV3Pool(pool).swap(address(this),direc,int(amOut),direc ? 4295128740 : 1461446703485210103287273052203988822378723970341, "");
        amOut=uint(-(direc ? am1 : am0));
        tOut=_tOut;
    }

    function kyberV3Swap(address pool,address _tOut)public{
        bool direc=tOut<_tOut;
        (int am0,int am1)=IKyberV3Pool(pool).swap(address(this),int(amOut),direc,direc ? 4295128740 : 1461446703485210103287273052203988822378723970341, "");
        amOut=uint(-(direc ? am1 : am0));
        tOut=_tOut;
    }

    function approve(address token ,address spender,uint amount)public owner{
        IERC20(token).approve(spender,amount);
    }

    function multicall(address _tIn, address _tOut,uint _amIn,uint _amOut,bytes[] calldata callPath)public returns(uint){
        amOut=_amIn;
        tOut=_tIn;
        for (uint i = 0; i < callPath.length; i++)
            address(this).call(callPath[i]);
        require (amOut>=_amOut && tOut==_tOut,"amOut");
        return amOut;
    }

    function poolImmutables(address pool)public view returns (address t0,address t1,uint24 fee,string memory functionName){
        if(IPool(pool).factory()==0x1F98431c8aD98523631AE4a59f267346ea31F984){
            t0=IUniV3Pool(pool).token0();
            t1=IUniV3Pool(pool).token1();
            fee=IUniV3Pool(pool).fee();
            functionName="uniV3Swap";
        }
        else if(IPool(pool).factory()==0x5F1dddbf348aC2fbe22a163e30F99F9ECE3DD50a){
            t0=IKyberV3Pool(pool).token0();
            t1=IKyberV3Pool(pool).token1();
            fee=IKyberV3Pool(pool).swapFeeUnits()*10;
            functionName="kyberV3Swap";
        }
        else{
            t0=IUniV2Pool(pool).token0();
            t1=IUniV2Pool(pool).token1();
            fee=3000;
            functionName="uniV2Swap";
        }
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