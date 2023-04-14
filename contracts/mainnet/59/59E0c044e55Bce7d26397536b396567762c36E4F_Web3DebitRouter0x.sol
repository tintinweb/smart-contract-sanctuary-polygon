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
address public treasury;
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
    uint amountSold;
    uint amountBought;
}


event Routed(
    uint indexed id,
    address indexed store,
    address indexed sender,
    uint memo,
    address tokenIn,
    address tokenOut,
    uint amountOut,
    uint fee,
    uint soldAmount,
    uint boughtAmount,
    uint destChain,
    uint amountOutFixed,
    address tokenBridge);


event ReceivedFromStargate(
    uint nonce,
    uint indexed id,
    uint srcChain,
    address indexed store,
    address indexed sender,
    address token,                 
    uint256 amountIn,
    uint amountPay,
    uint fee);
        

constructor(
    IStargateRouter _stargateRouter,
    address payable _exchangeProxy, 
    uint _source,
    address _owner,
    address _treasury) {
        
    require(_owner != address(0));
    require(_treasury != address(0));
    require(_source > 0);
    require(_exchangeProxy != address(0));

    source = _source;
    owner = _owner;
    stargateRouter = _stargateRouter;
    exchangeProxy = _exchangeProxy;
    treasury = _treasury;
}


modifier onlyOwner() {

    require(msg.sender == owner);
    _;

}


function transferOwner(address _owner) external onlyOwner {

    require(_owner != address(0));
    owner = _owner;

}


function transferTreasury(address _treasury) external {

    require(msg.sender == treasury);
    require(_treasury != address(0));
    treasury = _treasury;

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
    DataSwap0x calldata _dataSwap) external nonReentrant {

    require(!locked);
    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.tokenIn == _dataSwap.tokenOut);
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.amountOut == _dataSwap.amountInMaximum);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);
    require(_dataSwap.amountSold > 0);
    require(_dataSwap.amountBought > 0);
    require(_dataSwap.amountSold == _dataSwap.amountBought);

    idPayment += 1;

    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataSwap.amountInMaximum);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataSwap.amountInMaximum);
        
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataSwap.amountInMaximum);
        
    uint fee = _payment(_dataSwap.store, _dataSwap.tokenOut, _dataSwap.amountOut);    

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        fee,
        _dataSwap.amountSold,
        _dataSwap.amountBought,
        0,
        0,
        address(0));

}


function swapAndPayOnChainERC20(
    DataSwap0x calldata _dataSwap) external nonReentrant {

    require(!locked);
    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);
 
    idPayment += 1;

    _swapAndPayOnChainERC20(_dataSwap);

}


function _swapAndPayOnChainERC20(
    DataSwap0x calldata _dataSwap) internal {
    
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

    uint fee = _payment(_dataSwap.store, _dataSwap.tokenOut, _dataSwap.amountOut);

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        fee,
        soldAmount,
        boughtAmount,
        0,
        0,
        address(0));

}


function swapAndPayOnChainNATIVE(
    DataSwap0x calldata _dataSwap) external payable nonReentrant {

    require(!locked);
    require(_dataSwap.amountInMaximum > 0);
    require(msg.value == _dataSwap.amountInMaximum);
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);

    idPayment += 1;

    _swapAndPayOnChainNATIVE(_dataSwap);

}


function _swapAndPayOnChainNATIVE(
    DataSwap0x calldata _dataSwap) internal {

    uint balanceStartTokenOut = IERC20(_dataSwap.tokenOut).balanceOf(address(this));
    uint balanceStartTokenIn = address(this).balance;

    (bool success0x,) = exchangeProxy.call{value: msg.value}(_dataSwap.swapCallData);
    require(success0x, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataSwap.tokenOut).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataSwap.amountOut);

    uint soldAmount = balanceStartTokenIn - address(this).balance;
    
    if (soldAmount < _dataSwap.amountInMaximum) {
        (bool success,) = msg.sender.call{ value: _dataSwap.amountInMaximum - soldAmount }("");
    }

    if (boughtAmount > _dataSwap.amountOut) {
        TransferHelper.safeTransfer(_dataSwap.tokenOut, msg.sender, boughtAmount - _dataSwap.amountOut);
    }
    
    uint fee = _payment(_dataSwap.store, _dataSwap.tokenOut, _dataSwap.amountOut);

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        fee,
        soldAmount,
        boughtAmount,
        0,
        0,
        address(0));

}


function swapToStargate(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate) external payable nonReentrant {

    require(!locked);
    require(msg.value > 0);

    require(_dataStargate.dstChainId > 0);
    require(_dataStargate.srcPoolId > 0);
    require(_dataStargate.dstPoolId > 0);
    require(_dataStargate.amountLD > 0);
    require(_dataStargate.minAmountLD > 0);
    require(_dataStargate.gasfee > 0);
    require(_dataStargate.receiverAddress != address(0));
    require(_dataStargate.tokenBridge != address(0));


    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);

    idPayment += 1;

    _swapToStargate(_dataSwap, _dataStargate);
    
}


function _swapToStargate(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate) internal {
    
    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataStargate.amountLD);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataStargate.amountLD);
        
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataStargate.amountLD);
    TransferHelper.safeApprove(_dataSwap.tokenIn, address(stargateRouter), _dataStargate.amountLD);
    
    bytes memory payload = abi.encode(
        idPayment,
        source,
        _dataSwap.store,
        _dataSwap.amountOut,
        msg.sender);

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

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        0,
        _dataStargate.amountLD,
        _dataStargate.amountLD,
        _dataStargate.dstChainId,
        _dataStargate.minAmountLD,
        _dataStargate.tokenBridge);

}


function swapAndPayCrossChainERC20(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate) external payable nonReentrant {   
        
    require(!locked);
    require(msg.value > 0);

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
    
    idPayment += 1;

    _swapAndPayCrossChainERC20(_dataSwap, _dataStargate);

}


function _swapAndPayCrossChainERC20(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate) internal {

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
    _dataSwap.amountBought = boughtAmount;

    _swapToStargateFromERC20(_dataSwap, _dataStargate);

}


function _swapToStargateFromERC20(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate) internal {

    bytes memory payload = abi.encode(
        idPayment,
        source,
        _dataSwap.store,
        _dataSwap.amountOut,
        msg.sender);

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

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        0,
        _dataSwap.amountSold,
        _dataSwap.amountBought,
        _dataStargate.dstChainId,
        _dataStargate.minAmountLD,
        _dataStargate.tokenBridge);

}


function swapAndPayCrossChainNATIVE(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate) external payable nonReentrant {
    
    require(!locked);
    require(msg.value > 0);
  
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

    idPayment += 1;

    _swapAndPayCrossChainNATIVE(_dataSwap, _dataStargate);

}


function _swapAndPayCrossChainNATIVE(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate) internal {
      
    uint balanceStartTokenOut = IERC20(_dataStargate.tokenBridge).balanceOf(address(this));
    uint balanceStartTokenIn = address(this).balance;

    (bool success0x,) = exchangeProxy.call{value: _dataSwap.amountInMaximum }(_dataSwap.swapCallData);
    require(success0x, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataStargate.tokenBridge).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataStargate.amountLD);

    uint soldAmount = balanceStartTokenIn - address(this).balance;
        
    if (soldAmount < _dataSwap.amountInMaximum) {
        (bool success,) = msg.sender.call{ value: _dataSwap.amountInMaximum - soldAmount }("");
    }

    if (boughtAmount > _dataStargate.amountLD) {
        TransferHelper.safeTransfer(_dataStargate.tokenBridge, msg.sender, boughtAmount - _dataStargate.amountLD);
    }

    TransferHelper.safeApprove(_dataStargate.tokenBridge, address(stargateRouter), _dataStargate.amountLD);  

    _dataSwap.amountSold = soldAmount;
    _dataSwap.amountBought = boughtAmount;

    _swapToStargateFromNATIVE(_dataSwap, _dataStargate);

}


function _swapToStargateFromNATIVE(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate) internal {
    
    bytes memory payload = abi.encode(
        idPayment,
        source,
        _dataSwap.store,
        _dataSwap.amountOut,
        msg.sender);

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

   emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        0,
        _dataSwap.amountSold,
        _dataSwap.amountBought,
        _dataStargate.dstChainId,
        _dataStargate.minAmountLD,
        _dataStargate.tokenBridge);

}


function sgReceive(
    uint16 /*_srcChainId*/,            
    bytes memory /*_srcAddress*/,      
    uint256 _nonce,                  
    address _token,                
    uint256 amountLD,              
    bytes memory payload) external nonReentrant {

    require(msg.sender == address(stargateRouter)); 

    (uint id,
     uint sourceId,
     address store,
     uint amountOut,
     address sender) = abi.decode(payload, (uint, uint, address, uint, address));
 
    uint amountToPay;

    if (amountLD > amountOut) {
        TransferHelper.safeTransfer(_token, sender, amountLD - amountOut);
        amountToPay = amountOut;
    }

    if (amountLD <= amountOut) {
        amountToPay = amountLD;
    }

    uint fee = _payment(store, _token, amountToPay);

    emit ReceivedFromStargate(
        _nonce,
        id,
        sourceId,
        store,
        sender,
        _token,
        amountLD,
        amountToPay,
        fee);

}    


function _payment(
    address _store,
    address _tokenOut,
    uint _amountOut) internal returns (uint) {

    uint decimals = ERC20(_tokenOut).decimals();
    
    uint feeAmount = _amountOut * ((feeStore) * 10 ** decimals / 10000);
    feeAmount = feeAmount / 10 ** decimals;

    uint netAmount = _amountOut - feeAmount;
    
    TransferHelper.safeTransfer(_tokenOut, _store, netAmount);

    if (feeAmount > 0) {
        TransferHelper.safeTransfer(_tokenOut, treasury, feeAmount);
    }
 
    return feeAmount;

}


function withdrawEther() external payable nonReentrant {
  
    require(msg.sender == treasury);
    (bool sent,) = treasury.call{value: address(this).balance}("");
    
}


function balanceEther() external view returns (uint) {
 
    return address(this).balance;

}


function balanceERC20(IERC20 _token) external view returns (uint) {
 
    return _token.balanceOf(address(this));

}


function withdrawERC20(IERC20 _token) external nonReentrant {
  
    require(msg.sender == treasury);
    TransferHelper.safeTransfer(address(_token), treasury, _token.balanceOf(address(this)));
    
}


receive() external payable {}


}