/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Multicall {
    address private _owner;
    uint private am;
    address[] private uniV3Factories = [0x1F98431c8aD98523631AE4a59f267346ea31F984];
    address[] private kyberV3Factories = [0x5F1dddbf348aC2fbe22a163e30F99F9ECE3DD50a];
    address[] private uniV2Factories = [0xc35DADB65012eC5796536bD9864eD8773aBc74C4 ,0xCf083Be4164828f00cAE704EC15a36D711491284, 0x477Ce834Ae6b7aB003cCe4BC4d8697763FF456FA];


    constructor() {
        _owner = msg.sender;
    }

    struct Route {
        uint amIn;
        uint amOut;
        address tOut;
        bytes[] callPath;
    }

    modifier owner() {
        require(tx.origin == _owner);
        _;
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

    function uniswapV3SwapCallback(int256 am0, int256 am1, bytes calldata) external {
        if(am0>am1){
            am=uint(-am1);
            transfer(IUniV3Pool(msg.sender).token0(), msg.sender, uint(am0));
        }else{
            am=uint(-am0);
            transfer(IUniV3Pool(msg.sender).token1(), msg.sender, uint(am1));
        }
    }

    function swapCallback(int256 am0, int256 am1, bytes calldata) external {
        if(am0>am1){
            am=uint(-am1);
            transfer(IUniV3Pool(msg.sender).token0(), msg.sender, uint(am0));
        }else{
            am=uint(-am0);
            transfer(IUniV3Pool(msg.sender).token1(), msg.sender, uint(am1));
        }
    }

    function uniV2Swap(address pool, bool direc) public {
        (uint112 reserve0, uint112 reserve1, ) = IUniV2Pool(pool).getReserves();
        uint amIn = (am * 997) / 1000;
        am = direc ? (amIn * reserve1) / (reserve0 + amIn) : (amIn * reserve0) / (reserve1 + amIn);
        transfer(direc ? IUniV2Pool(pool).token0() : IUniV2Pool(pool).token1(), pool, (amIn*1000)/997);
        IUniV2Pool(pool).swap(direc ? 0 : am,direc ? am : 0,address(this),"");
    }

    function uniV3Swap(address pool, bool direc) public {
        IUniV3Pool(pool).swap(address(this),direc,int(am),direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function kyberV3Swap(address pool, bool direc) public {
        IKyberV3Pool(pool).swap(address(this),int(am),direc,direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function transfer(address token,address recipient,uint amount) public owner {
        IERC20(token).transfer(recipient, amount);
    }

    function quoteRoute(Route calldata _route) public returns(uint _amOut,uint _gas){
        _gas=gasleft();
        route(_route);
        return (am,_gas-gasleft());
    }

    function route(Route calldata _route) public{
        am=_route.amIn;
        multicall(_route.callPath);
        require(IERC20(_route.tOut).balanceOf(address(this))>=_route.amOut);
        delete am;
    }

    function multicall(bytes[] calldata callPath) public {
        for (uint8 i = 0; i < callPath.length; i++)
            address(this).call(callPath[i]);
    }

    function computeAddress(address factory, address t0,address t1,uint24 fee) internal pure returns (address pool) {
        pool= address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encode(t0, t1, fee)),
            bytes32(0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54)
        )))));
    }

    function poolImmutables(address pool)public view returns (address t0,address t1,uint24 fee,bytes4 selector){
        for(uint8 i=0;i<uniV3Factories.length;i++)
            if(IPool(pool).factory()== uniV3Factories[i])
                return (IUniV3Pool(pool).token0(), IUniV3Pool(pool).token1(),IUniV3Pool(pool).fee(),bytes4(keccak256(bytes("uniV3Swap(address,bool)"))));
        for(uint8 i=0;i<kyberV3Factories.length;i++)
            if(IPool(pool).factory()== kyberV3Factories[i])
                return (IKyberV3Pool(pool).token0(), IKyberV3Pool(pool).token1(),IKyberV3Pool(pool).swapFeeUnits()*10,bytes4(keccak256(bytes("kyberV3Swap(address,bool)"))));
        for(uint8 i=0;i<uniV2Factories.length;i++)
            if (IPool(pool).factory()== uniV2Factories[i])
                return (IUniV2Pool(pool).token0(),IUniV2Pool(pool).token1(),3000,bytes4(keccak256(bytes("uniV2Swap(address,bool)"))));
    }

}

interface IPool{
    function factory() external view returns (address);
}

interface IUniV2Pool {
    function swap(uint amount0Out,uint amount1Out,address to,bytes calldata data) external;
    function getReserves()external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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