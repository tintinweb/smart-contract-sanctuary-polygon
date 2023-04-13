// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";


interface ERC20 {

    function decimals() external view returns (uint8);

}


interface IStargateRouter {

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }


    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

}


contract Web3DebitRouter0x is ReentrancyGuard {

IStargateRouter public stargateRouter;
uint public immutable source;
address payable public exchangeProxy;
uint public feeStore;
uint public idPayment;
address public owner;
bool public locked;


struct DataStargate0x {

    uint16 dstChainId;
    uint256 srcPoolId;
    uint256 dstPoolId;
    uint256 amountLD;
    uint256 minAmountLD;
    uint256 gasfee;
    address receiverAddress;
    address tokenBridge;
}


struct DataSwap0x {
    bytes swapCallData;
    address tokenIn;
    address tokenOut;
    uint amountOut;
    uint amountInMaximum;
    address store;
    uint memo;
    uint chainSource;
    address sender;
    uint amountSold;
}


event Routed(
    address indexed store,
    address indexed sender,
    uint memo,
    address tokenin,
    address tokenout,
    uint amountin,
    uint amountout,
    uint destchain,
    uint srcpool,
    uint dstpool,
    uint amountoutfixed);


event ReceivedFromStargate(
    uint _nonce,
    address _token,                 
    uint256 amountLD,
    address indexed store,
    address indexed sender,
    uint amountout,
    uint memo,
    uint source);
        

constructor(
    IStargateRouter _stargateRouter,
    address payable _exchangeProxy, 
    uint _sourcechain,
    address _owner) {
        
    require(_owner != address(0));
    require(_sourcechain > 0);
    require(_exchangeProxy != address(0));

    source = _sourcechain;
    owner = _owner;
    stargateRouter = _stargateRouter;
    exchangeProxy = _exchangeProxy;
}


modifier onlyOwner() {

    require(msg.sender == owner);
    _;

}


function transferOwner(address _newowner) external onlyOwner {

    require(_newowner != address(0));
    owner = _newowner;

}


function lockRouter() external onlyOwner {

    if (locked) {
        locked = false;
    }

    if (!locked) {
        locked = true;
    }

}


function changeStargateRouter(IStargateRouter _stargateRouter) external onlyOwner {
    
    stargateRouter = _stargateRouter;

}

function changeExchangeProxy(address payable _exchangeProxy) external onlyOwner {
    
    require(_exchangeProxy != address(0));
    exchangeProxy = _exchangeProxy;

}


function changeFeeStore(uint _feeStore) external onlyOwner {
    
    feeStore = _feeStore;

}





function noSwapPayOnChainSameERC20(
    DataSwap0x memory _dataSwap

    //address _tokenOut,
    //uint256 _amountOut,
    //address _store,
    //uint _memo
    ) external nonReentrant {

    require(!locked);
    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.amountOut == _dataSwap.amountInMaximum);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);
    require(_dataSwap.amountSold > 0);
    
    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataSwap.amountInMaximum);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataSwap.amountInMaximum);
        
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataSwap.amountInMaximum);
    
    _dataSwap.chainSource = source;
    _dataSwap.sender = msg.sender;
        
    _payment(_dataSwap);    
    
    
/*
    emit Routed(
        _store,
        msg.sender,
        _memo,
        _tokenOut,
        _tokenOut,
        _amountOut,
        _amountOut,
        0,
        0,
        0,
        0);
*/

}


function swapAndPayOnChainERC20(
    //bytes calldata _swapCallData,
    DataSwap0x calldata _dataSwap

    //address _tokenIn,
    //address _tokenOut,
    //uint256 _amountOut,
    //uint256 _amountInMaximum,
    //address _store,
    //uint _memo
    ) external nonReentrant {

    require(!locked);
    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);

/*
    DataSwapOnChain memory dataSwap = DataSwapOnChain(
        _swapTarget,
        _swapCallData,
        _tokenIn,
        _tokenOut,
        _amountOut,
        _amountInMaximum,
        _store,
        _memo);
*/
  
    _swapAndPayOnChainERC20(_dataSwap);

}


function _swapAndPayOnChainERC20(
    DataSwap0x memory _dataSwap) internal {
    
    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataSwap.amountInMaximum);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataSwap.amountInMaximum);
    
    uint balanceStartTokenIn = IERC20(_dataSwap.tokenIn).balanceOf(address(this));
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataSwap.amountInMaximum);
    TransferHelper.safeApprove(_dataSwap.tokenIn, address(exchangeProxy), _dataSwap.amountInMaximum);
        
    uint balanceStartTokenOut = IERC20(_dataSwap.tokenOut).balanceOf(address(this));
    
    (bool success,) = exchangeProxy.call{value: 0}(_dataSwap.swapCallData);
    require(success, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataSwap.tokenOut).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataSwap.amountOut);

    uint soldAmount = balanceStartTokenIn + _dataSwap.amountInMaximum - IERC20(_dataSwap.tokenIn).balanceOf(address(this));

    TransferHelper.safeApprove(_dataSwap.tokenIn, address(exchangeProxy), 0);
        
    if (soldAmount < _dataSwap.amountInMaximum) {
        TransferHelper.safeTransfer(_dataSwap.tokenIn, msg.sender, _dataSwap.amountInMaximum - soldAmount);
    }

    if (boughtAmount > _dataSwap.amountOut) {
        TransferHelper.safeTransfer(_dataSwap.tokenOut, msg.sender, boughtAmount - _dataSwap.amountOut);
    }

    _dataSwap.chainSource = source;
    _dataSwap.sender = msg.sender;
    _dataSwap.amountSold = soldAmount;

/*
    emit Routed(
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        soldAmount,
        _dataSwap.amountOut,
        0,
        0,
        0,
        0);
  */     
  
    _payment(_dataSwap);

}


function swapAndPayOnChainNATIVE(
    DataSwap0x calldata _dataSwap
    
    //ISwapRouterUniswapV3 _swapRouterUniswapV3,
    //bytes memory path,
    //address _tokenIn,
    //address _tokenOut,
    //uint256 _timeswap,
    //uint256 _amountOut,
    //uint256 _amountInMaximum,
    //address _store,
    //uint _memo
    
    ) external payable nonReentrant {

    require(!locked);
    require(msg.value == _dataSwap.amountInMaximum);
    
    //require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);

    

/*
    DataSwap memory _dataswap = DataSwap(
        _tokenIn,
        _tokenOut,
        _timeswap,
        _amountOut,
        _amountInMaximum,
        _store,
        _memo);
*/

    _swapAndPayOnChainNATIVE(_dataSwap);

}


function _swapAndPayOnChainNATIVE(
    DataSwap0x memory _dataSwap
    //bytes memory path,
    //ISwapRouterUniswapV3 _swapRouterUniswapV3
    ) internal {

    uint balanceStartTokenOut = IERC20(_dataSwap.tokenOut).balanceOf(address(this));
    uint balanceStartTokenIn = address(this).balance - msg.value;

    (bool success0x,) = exchangeProxy.call{value: msg.value}(_dataSwap.swapCallData);
    require(success0x, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataSwap.tokenOut).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataSwap.amountOut);

    uint soldAmount = balanceStartTokenIn + _dataSwap.amountInMaximum - address(this).balance;
    
    if (soldAmount < _dataSwap.amountInMaximum) {
        (bool success,) = msg.sender.call{ value: _dataSwap.amountInMaximum - soldAmount }("");
    }

    if (boughtAmount > _dataSwap.amountOut) {
        TransferHelper.safeTransfer(_dataSwap.tokenOut, msg.sender, boughtAmount - _dataSwap.amountOut);
    }

    _dataSwap.chainSource = source;
    _dataSwap.sender = msg.sender;
    _dataSwap.amountSold = soldAmount;
    
    
    _payment(_dataSwap);
    
    
    

    
      
    
     
    
/*
    emit Routed(
        _dataswap.store,
        msg.sender,
        _dataswap.memo,
        _dataswap.tokenIn,
        _dataswap.tokenOut,
        amountIn,
        _dataswap.amountOut,
        0,
        0,
        0,
        0);
*/

}




function swapToStargate(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate
    
    //uint16 dstChainId,
    //uint256 srcPoolId,
    //uint256 dstPoolId,
    //uint256 amountLD,
    //uint256 minAmountLD,
    //uint256 gasfee,
    //address receiverAddress,
    //address tokenincross,
    //address thestore,
    //uint thememo,    
    //address tokenoutcross,
    //uint theamountpay
    ) external payable nonReentrant {

    require(!locked);
    require(msg.value > 0);

    require(_dataStargate.dstChainId > 0);
    require(_dataStargate.srcPoolId > 0);
    require(_dataStargate.dstPoolId > 0);
    require(_dataStargate.amountLD > 0);
    require(_dataStargate.minAmountLD > 0);
    require(_dataStargate.gasfee > 0);
    require(_dataStargate.receiverAddress != address(0));
    
    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);
    
/*
    DataToStargate memory _datastargate = DataToStargate(
        dstChainId,
        srcPoolId,
        dstPoolId,
        amountLD,
        minAmountLD,
        gasfee,
        thememo,    
        receiverAddress,
        tokenincross,
        thestore,
        tokenoutcross);
*/

    _swapToStargate(_dataSwap, _dataStargate);
    
}


function _swapToStargate(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate
       
    //DataToStargate memory _datastargate, uint theamountpay
    ) internal {
    
    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataStargate.amountLD);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataStargate.amountLD);
        
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataStargate.amountLD);
    TransferHelper.safeApprove(_dataSwap.tokenIn, address(stargateRouter), _dataStargate.amountLD);
    
    bytes memory payload = abi.encode(
        _dataSwap.store,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        _dataSwap.memo,
        msg.sender,
        source,
        _dataSwap.tokenIn,
        _dataStargate.amountLD);

    stargateRouter.swap{value: msg.value }(
        _dataStargate.dstChainId,                          
        _dataStargate.srcPoolId,                           
        _dataStargate.dstPoolId,                           
        payable(msg.sender),                      
        _dataStargate.amountLD,                  
        _dataStargate.minAmountLD,               
        IStargateRouter.lzTxObj(_dataStargate.gasfee, 0, "0x"), 
        abi.encodePacked(_dataStargate.receiverAddress),    
        payload);                     


/*
    emit Routed(
        _datastargate.thestore_,
        msg.sender,
        _datastargate.thememo_,
        _datastargate.tokenincross_,
        _datastargate.tokenoutcross_,
        _datastargate.amountLD_,
        theamountpay,
        _datastargate.dstChainId_,
        _datastargate.srcPoolId_,
        _datastargate.dstPoolId_,
        _datastargate.minAmountLD_);
*/

}



function swapAndPayCrossChainERC20(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate
        
    //ISwapRouterUniswapV3 _swapRouterUniswapV3,
    //bytes memory path,   
    //DataToStargate1 memory datastruct
    ) external payable nonReentrant {   
        
    require(!locked);
    require(msg.value > 0);


//    DataToStargate1 memory data = datastruct;

    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);    
    
    require(_dataStargate.dstChainId > 0);
    require(_dataStargate.srcPoolId > 0);
    require(_dataStargate.dstPoolId > 0);
    require(_dataStargate.amountLD > 0);
    require(_dataStargate.minAmountLD > 0);
    require(_dataStargate.gasfee > 0);
    require(_dataStargate.receiverAddress != address(0));
    require(_dataStargate.tokenBridge != address(0));
    

    _swapAndPayCrossChainERC20(_dataSwap, _dataStargate);

}


function _swapAndPayCrossChainERC20(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate

    //DataToStargate1 memory data,
    //bytes memory path,
    //ISwapRouterUniswapV3 _swapRouterUniswapV3
    ) internal {

    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataSwap.amountInMaximum);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataSwap.amountInMaximum);

    uint balanceStartTokenIn = IERC20(_dataSwap.tokenIn).balanceOf(address(this));    
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataSwap.amountInMaximum);
    TransferHelper.safeApprove(_dataSwap.tokenIn, address(exchangeProxy), _dataSwap.amountInMaximum);
    
    uint balanceStartTokenOut = IERC20(_dataStargate.tokenBridge).balanceOf(address(this));
    
    (bool success,) = exchangeProxy.call{value: 0}(_dataSwap.swapCallData);
    require(success, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataStargate.tokenBridge).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataStargate.amountLD);

    uint soldAmount = balanceStartTokenIn + _dataSwap.amountInMaximum - IERC20(_dataSwap.tokenIn).balanceOf(address(this));

    TransferHelper.safeApprove(_dataSwap.tokenIn, address(exchangeProxy), 0);
        
    if (soldAmount < _dataSwap.amountInMaximum) {
        TransferHelper.safeTransfer(_dataSwap.tokenIn, msg.sender, _dataSwap.amountInMaximum - soldAmount);
    }

    if (boughtAmount > _dataStargate.amountLD) {
        TransferHelper.safeTransfer(_dataStargate.tokenBridge, msg.sender, boughtAmount - _dataStargate.amountLD);
    }

    TransferHelper.safeApprove(_dataStargate.tokenBridge, address(stargateRouter), _dataStargate.amountLD);  

    _dataSwap.amountSold = soldAmount;

    _swapToStargateFromERC20(_dataSwap, _dataStargate);

}


function _swapToStargateFromERC20(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate
    
    //DataToStargate1 memory data,
    //uint amountIn
    ) internal {

    bytes memory payload = abi.encode(
        _dataSwap.store,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        _dataSwap.memo,
        msg.sender,
        source,
        _dataSwap.tokenIn,
        _dataSwap.amountSold);

    stargateRouter.swap{value: msg.value }(
        _dataStargate.dstChainId,          
        _dataStargate.srcPoolId,           
        _dataStargate.dstPoolId,           
        payable(msg.sender),                
        _dataStargate.amountLD,            
        _dataStargate.minAmountLD,         
        IStargateRouter.lzTxObj(_dataStargate.gasfee, 0, "0x"), 
        abi.encodePacked(_dataStargate.receiverAddress),    
        payload);                     

/*
    emit Routed(
        data.thestore,
        msg.sender,
        data.thememo,
        data.thetokenIn,
        data.tokenoutcross,
        amountIn,
        data.theamountpay,
        data.dstChainId,
        data.srcPoolId,
        data.dstPoolId,
        data.minAmountLD);
*/
}


function swapAndPayCrossChainNATIVE(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate
        
    //ISwapRouterUniswapV3 _swapRouterUniswapV3,
    //bytes memory path,   
    //DataToStargate1 memory datastruct
    ) external payable nonReentrant {
    
    require(!locked);
    require(msg.value > 0);
  
    //DataToStargate1 memory data = datastruct;

    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.memo > 0);    
    
    require(_dataStargate.dstChainId > 0);
    require(_dataStargate.srcPoolId > 0);
    require(_dataStargate.dstPoolId > 0);
    require(_dataStargate.amountLD > 0);
    require(_dataStargate.minAmountLD > 0);
    require(_dataStargate.gasfee > 0);
    require(_dataStargate.receiverAddress != address(0));
    require(_dataStargate.tokenBridge != address(0));

    _swapAndPayCrossChainNATIVE(_dataSwap, _dataStargate);

}


function _swapAndPayCrossChainNATIVE(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate
    
    //DataToStargate1 memory data,
    //bytes memory path,
    //ISwapRouterUniswapV3 _swapRouterUniswapV3
    ) internal {
  
    
    uint balanceStartTokenOut = IERC20(_dataStargate.tokenBridge).balanceOf(address(this));
    uint balanceStartTokenIn = address(this).balance - msg.value;

    (bool success0x,) = exchangeProxy.call{value: _dataSwap.amountInMaximum }(_dataSwap.swapCallData);
    require(success0x, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataStargate.tokenBridge).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataStargate.amountLD);

    uint soldAmount = balanceStartTokenIn + _dataSwap.amountInMaximum - address(this).balance - (msg.value - _dataSwap.amountInMaximum);
    
    if (soldAmount < _dataSwap.amountInMaximum) {
        (bool success,) = msg.sender.call{ value: _dataSwap.amountInMaximum - soldAmount }("");
    }

    if (boughtAmount > _dataStargate.amountLD) {
        TransferHelper.safeTransfer(_dataStargate.tokenBridge, msg.sender, boughtAmount - _dataStargate.amountLD);
    }
    
    _dataSwap.amountSold = soldAmount;
        
    _swapToStargateFromNATIVE(_dataSwap, _dataStargate);

}


function _swapToStargateFromNATIVE(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate
    
    //DataToStargate1 memory data,
    //uint amountIn
    ) internal {
    
    bytes memory payload = abi.encode(
        _dataSwap.store,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        _dataSwap.memo,
        msg.sender,
        source,
        _dataSwap.tokenIn,
        _dataSwap.amountSold);

    stargateRouter.swap{value: msg.value - _dataSwap.amountInMaximum }(
        _dataStargate.dstChainId,                         
        _dataStargate.srcPoolId,                          
        _dataStargate.dstPoolId,                          
        payable(msg.sender),                      
        _dataStargate.amountLD,                  
        _dataStargate.minAmountLD,
        IStargateRouter.lzTxObj(_dataStargate.gasfee, 0, "0x"),
        abi.encodePacked(_dataStargate.receiverAddress),   
        payload);                     

/*
   emit Routed(
        data.thestore,
        msg.sender,
        data.thememo,
        data.thetokenIn,
        data.tokenoutcross,
        amountIn,
        data.theamountpay,
        data.dstChainId,
        data.srcPoolId,
        data.dstPoolId,
        data.minAmountLD);
*/

}


function sgReceive(
    uint16 /*_srcChainId*/,            
    bytes memory /*_srcAddress*/,      
    uint256 _nonce,                  
    address _token,                
    uint256 amountLD,              
    bytes memory payload) external nonReentrant {

    require(msg.sender == address(stargateRouter)); 

    (address theStore,
     address theTokenOut,
     uint theAmountOut,
     uint theMemo,
     address theSender,
     uint theSource,
     address theTokenIn,
     uint theAmountSold) = abi.decode(payload, (address, address, uint, uint, address, uint, address, uint));

 
    if (amountLD > theAmountOut) {
        TransferHelper.safeTransfer(theTokenOut, theSender, amountLD - theAmountOut);
    }

    DataSwap0x memory _dataSwap = DataSwap0x(
    '',
    theTokenIn,
    theTokenOut,
    theAmountOut,
    0,
    theStore,
    theMemo,
    theSource,
    theSender,
    theAmountSold);
    
    _payment(_dataSwap);


/*
    emit ReceivedFromStargate(
        _nonce,
        _token,
        amountLD,
        thestore,
        thesender,
        theamount,
        thememo,
        thesource);
*/

}    


function _payment(
    DataSwap0x memory _dataSwap) internal {

    uint decimals = ERC20(_dataSwap.tokenOut).decimals();
    idPayment += 1;

    uint feeAmount = _dataSwap.amountOut * ((feeStore) * 10 ** decimals / 10000);
    feeAmount = feeAmount / 10 ** decimals;

    uint netAmount = _dataSwap.amountOut - feeAmount;
    
    TransferHelper.safeTransfer(_dataSwap.tokenOut, _dataSwap.store, netAmount);

    if (feeAmount > 0) {
        TransferHelper.safeTransfer(_dataSwap.tokenOut, owner, feeAmount);
    }
       
 /*
    emit Payment(
        _datapayment.thestore,
        _datapayment.thesender,
        _datapayment.thetokenin,
        _datapayment.thetoken,
        _datapayment.theamountin,
        _datapayment.theamount,
        _datapayment.thesource,
        _datapayment.thememo,
        feeamount,
        netamount);
*/

}


function withdrawEther() external payable onlyOwner nonReentrant {
  
    (bool sent,) = owner.call{value: address(this).balance}("");
    
}


function balanceEther() external view returns (uint) {
 
    return address(this).balance;

}







receive() payable external {}

}