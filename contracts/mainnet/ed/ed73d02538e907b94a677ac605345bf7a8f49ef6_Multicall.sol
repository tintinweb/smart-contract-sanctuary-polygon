/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
    uint private am;
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier owner() {
        require(tx.origin == _owner);
        _;
    }

    struct Immutables{
        address t0;
        address t1;
        uint24 fee;
        bytes4 selector;
    }

    struct Factories{
        address[] uniV2;
        address[] uniV3;
        address[] kyberV3;
    }

    struct Route {
        uint amIn;
        uint amOut;
        bytes[] callPath;
    }

    function uniswapV3FlashCallback(uint256 fee0,uint256 fee1,bytes calldata data) external{
        multicall(abi.decode(data,(bytes[])));
        if(fee0>0) IERC20(IUniV3Pool(msg.sender).token0()).transfer(msg.sender, fee0);
        if(fee1>0) IERC20(IUniV3Pool(msg.sender).token1()).transfer(msg.sender, fee1);
        am-=(fee0+fee1);
    }

    function flashCallback(uint256 fee0,uint256 fee1,bytes calldata data) external{
        multicall(abi.decode(data,(bytes[])));
        if(fee0>0) IERC20(IKyberV3Pool(msg.sender).token0()).transfer(msg.sender, fee0);
        if(fee1>0) IERC20(IKyberV3Pool(msg.sender).token1()).transfer(msg.sender, fee1);
        am-=(fee0+fee1);
    }

    function uniswapV3SwapCallback(int256 am0, int256 am1, bytes calldata) external{
        if(am0>am1){
            IERC20(IUniV3Pool(msg.sender).token0()).transfer(msg.sender, uint(am0));
            am=uint(-am1);
        }else{
            IERC20(IUniV3Pool(msg.sender).token1()).transfer(msg.sender, uint(am1));
            am=uint(-am0);
        }
    }

    function swapCallback(int256 am0, int256 am1, bytes calldata) external{
        if(am0>am1){
            IERC20(IKyberV3Pool(msg.sender).token0()).transfer(msg.sender, uint(am0));
            am=uint(-am1);
        }else{
            IERC20(IKyberV3Pool(msg.sender).token1()).transfer(msg.sender, uint(am1));
            am=uint(-am0);
        }
    }

    function uniV2(address pool, bool direc) public{
        IERC20(direc ? IUniV2Pool(pool).token0() : IUniV2Pool(pool).token1()).transfer(pool, am);
        (uint112 reserve0, uint112 reserve1, ) = IUniV2Pool(pool).getReserves();
        am = (am * 997) / 1000;  
        am = direc ? (am * reserve1) / (reserve0 + am) : (am * reserve0) / (reserve1 + am);
        IUniV2Pool(pool).swap(direc ? 0 : am , direc ? am : 0,address(this),"");
    }

    function uniV3(address pool, bool direc) public{
        IUniV3Pool(pool).swap(address(this),direc,int(am),direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function kyberV3(address pool, bool direc) public{
        IKyberV3Pool(pool).swap(address(this),int(am),direc,direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function flashRoute(address pool,bool direc,Route calldata _route) public {
        am = _route.amIn;
        IV3Pool(pool).flash(address(this),direc?am:0,direc?0:am,abi.encode(_route.callPath));
        require(am>=_route.amOut,"amOut");
        delete am;
    }

    function multicall(bytes[] memory callPath) public{
        for (uint8 i = 0; i < callPath.length; i++){
            (bool success,)=address(this).call(callPath[i]);
            require(success,"err");
        }
    }

    function poolImmutables(address pool,Factories calldata factories)public view returns (Immutables memory immutables){
        for(uint8 i=0;i<factories.uniV3.length;i++)
            if(IPool(pool).factory()== factories.uniV3[i])
                immutables=Immutables(IUniV3Pool(pool).token0(), IUniV3Pool(pool).token1(),IUniV3Pool(pool).fee(),bytes4(keccak256(bytes("uniV3(address,bool)"))));
        for(uint8 i=0;i<factories.kyberV3.length;i++)
            if(IPool(pool).factory()== factories.kyberV3[i])
                immutables=Immutables(IKyberV3Pool(pool).token0(), IKyberV3Pool(pool).token1(),IKyberV3Pool(pool).swapFeeUnits()*10,bytes4(keccak256(bytes("kyberV3(address,bool)"))));
        for(uint8 i=0;i<factories.uniV2.length;i++)
            if (IPool(pool).factory()== factories.uniV2[i])
                immutables=Immutables(IUniV2Pool(pool).token0(),IUniV2Pool(pool).token1(),3000,bytes4(keccak256(bytes("uniV2(address,bool)"))));
    }
}

interface IPool{
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IV3Pool is IPool{
    function flash(address recipient,uint256 amount0,uint256 amount1,bytes calldata data) external;
}

interface IUniV2Pool is IPool{
    function swap(uint amount0Out,uint amount1Out,address to,bytes calldata data) external;
    function getReserves()external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniV3Pool is IV3Pool {
    function swap(address recipient,bool zeroForOne,int256 amountSpecified,uint160 sqrtPriceLimitX96,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function fee() external view returns (uint24);
}

interface IKyberV3Pool is IV3Pool {
    function swap(address recipient,int256 swapQty,bool isToken0,uint160 limitSqrtP,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function swapFeeUnits() external view returns (uint24);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address owner,address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}