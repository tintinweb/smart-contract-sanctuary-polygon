/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

//SPDX-License-Identifier: UNLICENSED
// --   --  --  --  --  --  --  --
// --   GoldenNaim was here     --
// https://twitter.com/BrutalTrade
// --   --  --  --  --  --  --  --
pragma solidity ^0.8.4;


interface IUniswapV2Router02 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)         external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)                           external payable returns (uint[] memory amounts);
}

interface manageToken {
    function balanceOf(address account)                                         external view returns (uint256);
    function allowance(address owner, address spender)                          external view returns (uint256);
    function approve(address spender, uint256 amount)                           external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)    external returns (bool);
    function transfer(address recipient, uint256 amount)                        external returns (bool);
}

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

interface IStargateRouter {
    struct lzTxObj {
        uint256     dstGasForCall;
        uint256     dstNativeAmount;
        bytes       dstNativeAddr;
    }

    function swap(
        uint16              _dstChainId,
        uint256             _srcPoolId,
        uint256             _dstPoolId,
        address payable     _refundAddress,
        uint256             _amountLD,
        uint256             _minAmountLD,
        lzTxObj memory      _lzTxParams,
        bytes calldata      _to,
        bytes calldata      _payload
    ) external payable;
}

contract sushiLayerZero is IStargateReceiver{

    struct stgSwapParams {
        uint256 value;
        uint16 dstChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        address payable refundAddress;
        uint256 amountLD;
        uint256 minAmountLD;
        IStargateRouter.lzTxObj lzTxParams;
        bytes  to;
        bytes payload;
    }

    receive() payable external {}

    IUniswapV2Router02  internal    sushiswapRouter;
    IStargateRouter     internal    stargateRouter;


    uint256 INFINITY_AMOUNT                             =   115792089237316195423570985008687907853269984665640564039457584007913129639935;
    address internal constant SUSHI_ROUTER_ADDRESS      =   0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address internal constant SUSHI_ETH_ROUTER_ADDRESS  =   0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    //address internal constant UNIV2_ROUTER_ADDRESS      = 0x0;
    //address internal constant UNIV2_ETH_ROUTER_ADDRESS  = 0x0;
    address internal STARGATE_ROUTER;
    address internal SUSHI_ROUTER;
    address public OWNER;

    mapping (address => bool) public TOKENS_ALLOWED;

    event RemoteSwap(uint256 amount, address dstAddress, address[] path, uint256 outputAmount);
    event LocalSwap();
    event TransferStg();
    
    // supporting usdt/usdc/busd
    function addToken(address token) public {
        require(msg.sender == OWNER, "You are not the owner");
        TOKENS_ALLOWED[token]   =   true;
        approve(token, STARGATE_ROUTER, INFINITY_AMOUNT);
    }

    function isTokenAllowed(address token) internal view returns (bool){
        return TOKENS_ALLOWED[token];
    }
    
    // env -> 1:ethereum, 2:alternative_networks
    constructor(address _stgRouter, uint256 env, address[] memory tokens) {
        //endpoint      =   ILayerZeroEndpoint(_layerZeroEndpoint);
        stargateRouter  =   IStargateRouter(_stgRouter);
        STARGATE_ROUTER =   _stgRouter;
        if(env == 1) {
            sushiswapRouter =   IUniswapV2Router02(SUSHI_ETH_ROUTER_ADDRESS);
            SUSHI_ROUTER    =   SUSHI_ETH_ROUTER_ADDRESS;
        } else {
            sushiswapRouter =   IUniswapV2Router02(SUSHI_ROUTER_ADDRESS);
            SUSHI_ROUTER    =   SUSHI_ROUTER_ADDRESS;
        }

        OWNER       =   msg.sender;

        for (uint i=0; i<tokens.length; i++) {
            addToken(tokens[i]);
        }
        
    }

    //function swapThenSend(uint256 amount, address[] memory route, uint256 minAmount, uint16 chainID, uint256 srcPoolID, uint256 dstPoolID, address target, uint256 slippageStargate) public payable {
    function swapAtSource(
        uint256 amount,
        address[] memory route,
        uint256 minAmount,
        uint16 chainID,
        uint256 srcPoolID,
        uint256 dstPoolID,
        address target,
        uint256 slippageStargate
    ) public payable returns (uint) {
        
        // 0. Check authorization
        uint256 isAllowed   =   manageToken(route[0]).allowance(msg.sender,address(this));
        require(amount > 0, "Amount must be higher than 0");
        require(isAllowed > amount, "You must allow this contract to spend your tokens");
        require(isTokenAllowed(route[route.length-1]), "The token wanted is not allowed");
        
        // 1. Transfer tokens from user to the contract
        manageToken(route[0]).transferFrom(msg.sender,address(this),amount);

        // 2. Is sushiswap allowed ?
        uint256 isSushiAllowed  =   manageToken(route[0]).allowance(address(this),SUSHI_ROUTER);
        if(isSushiAllowed < amount ) {
            require(approve(route[0], SUSHI_ROUTER, INFINITY_AMOUNT), "ERROR_001");
        } else { }
        
        // 3. Swap
        uint256[] memory swapIt;
        uint deadline           =   block.timestamp + 15;
        swapIt                  =   sushiswapRouter.swapExactTokensForTokens(amount, minAmount, route, address(this), deadline);
        uint256 outputAmount    =   swapIt[swapIt.length-1];

        return outputAmount;
        // 4. Send through Stargate and LayerZero
        //require(sendToStargate(1, 0, chainID, outputAmount, srcPoolID, dstPoolID, msg.sender, target, slippageStargate), "ERROR_002");
    }

    function swapNativeThenSend(
        uint256 amount,
        address[] memory route,
        uint256 minAmount,
        uint16 chainID,
        uint256 srcPoolID,
        uint256 dstPoolID,
        address target,
        uint256 slippageStargate
    ) public payable {
        
        // 0. Check 
        require(amount > 0, "Amount must be higher than 0");
        require(isTokenAllowed(route[route.length-1]), "The token wanted is not allowed");

        // 1. Swap
        uint256[] memory swapIt;
        uint deadline           =   block.timestamp + 15;
        swapIt =   sushiswapRouter.swapExactETHForTokens{
            value:amount}(
            minAmount,
            route,
            address(this),
            deadline);
        uint256 outputAmount    =   swapIt[swapIt.length-1];

        stgSwapParams memory p = buildStgParams(2, amount, chainID, outputAmount, srcPoolID, dstPoolID, msg.sender, target, slippageStargate, bytes(""));
 
        require(sendToStargate(p), "send to stargate failed");
    }
    

    function swapThenStg(
        uint256 amount,
        address[] memory route,
        uint256 minAmount,
        uint16 chainID,
        uint256 srcPoolID,
        uint256 dstPoolID,
        address target,
        uint256 slippageStargate,
        bytes memory payload
    ) payable public {
        // wrap destination swap in 
        uint outAmount = swapAtSource(amount, route, minAmount, chainID, srcPoolID, dstPoolID, target, slippageStargate);

        stgSwapParams memory p = buildStgParams(1, 0, chainID, outAmount, srcPoolID, dstPoolID, msg.sender, target, slippageStargate, payload);
        // send across stg
        sendToStargate(p);
        //sendToStargate(1, 0, chainID, outAmount, srcPoolID, dstPoolID, msg.sender, target, slippageStargate, payload);
    }

    //function swapNativeThenStgThenSwap() payable public {
    //    swapNativeThenSend(amount, route, minAmount, chainID, srcPoolID, dstPoolID, target, slippageStargate);

    //}

    function buildStgParams(
        uint256 txConf,
        uint256 nativeAmount,
        uint16 chainID,
        uint256 outputAmount,
        uint256 srcPoolID,
        uint256 dstPoolID,
        address sender,
        address target,
        uint256 slippageStg,
        bytes   memory payload
    ) internal returns(stgSwapParams memory) {
        // 0. Slippage 
        uint256 minAmount   =   outputAmount-((outputAmount/100)*slippageStg);
        uint256 theValue    =   0;
        if(txConf == 1) {
            theValue    =   msg.value;
        } else {
            theValue    =   msg.value-nativeAmount;
        }

        stgSwapParams memory p = stgSwapParams(
            theValue,
            chainID,
            srcPoolID,
            dstPoolID,
            payable(sender),
            outputAmount,
            minAmount,
            IStargateRouter.lzTxObj(0, 0, "0x"),
            abi.encodePacked(target),
            payload
        );
        return p;
    }

    function sendToStargate(stgSwapParams memory p) internal returns(bool) {
        IStargateRouter(stargateRouter).swap{value: p.value}(
            p.dstChainId,                           
            p.srcPoolId,                              
            p.dstPoolId,                                        
            payable(p.refundAddress),                     
            p.amountLD,                            
            p.minAmountLD,                   
            p.lzTxParams,
            p.to,
            p.payload
            );
        return true;
    }

    event testReceiveFromStg(uint16 _chainId,
        bytes _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD);

    // swap(x-u) -> stg(u) -> remoteSwap(u-y)
    //                        this
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external override{
        emit testReceiveFromStg(_chainId, _srcAddress, _nonce, _token, amountLD);
        // emit swap()
        (
            address dstAccount,
            uint256 amount,
            address[] memory path
        ) = abi.decode(payload, (address, uint256, address[]));
        require(path[0] == _token, "path[0] should be the token from stg");
        remoteSwap(amountLD, dstAccount, path);
    }
    // swap(x-u) -> stg(u) -> remoteSwap(u-y)
    //                        this part
    function remoteSwap(
        uint256 amount,
        address dstAddress,
        address[] memory path
    ) public returns (uint256) {

        // 0. Check authorization
        //uint256 isAllowed = manageToken(path[0]).allowance(msg.sender, address(this));
        //require(amount > 0, "Amount must be higher than 0");
        //require(isAllowed > amount, "You must allow this contract to spend your tokens");
        //require(isTokenAllowed(path[path.length-1]), "The token wanted is not allowed");
        
        // 2. Is sushiswap allowed ?
        uint256 isSushiAllowed  =   manageToken(path[0]).allowance(address(this),SUSHI_ROUTER);
        if(isSushiAllowed < amount ) {
            require(approve(path[0], SUSHI_ROUTER, INFINITY_AMOUNT), "approve return false");
        } else { }
        
        // 3. Swap
        uint256 minAmount = 0;
        uint deadline           =   block.timestamp + 15;
        
        try sushiswapRouter.swapExactTokensForTokens(amount, minAmount, path, dstAddress, deadline) returns (uint256[] memory swapIt){
            uint256 outputAmount    =   swapIt[swapIt.length-1];
            emit RemoteSwap(amount, dstAddress, path, outputAmount);
            return outputAmount;
        } catch {
            // incasef failure transfer u to dst
            return 0;
        }
    }

    function approve(address token, address router, uint256 amount) internal returns(bool) {
        return manageToken(token).approve(router, amount);
    }

    function inCaseIf(uint256 mode, address token, uint256 amount, address payable recipient) public payable {
        require(msg.sender == OWNER, "You are not the owner");
        if(mode == 1) {
            manageToken(token).transfer(OWNER,amount);
        } else {
            recipient.transfer(amount);
        }
    }

}