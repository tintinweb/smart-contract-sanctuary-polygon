/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;
interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
}
interface IWETH is IERC20{
    function deposit() external payable;
    function withdraw(uint) external;
}
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "RC");//ReentrancyGuard: reentrant call
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
contract AddressTool{
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    )internal returns (bytes memory){
        (bool success, bytes memory returndata) = target.call(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    )internal pure returns (bytes memory){
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract CallSwapTool is AddressTool{
    function callswap(
        address callSwapAddr,
        bytes calldata data,
        string memory message
    )external{
        functionCall(callSwapAddr,data,message);
    }
}
contract DefiIoAggregatedSwapRouterExt is ReentrancyGuard,AddressTool{
    IWETH public immutable weth;
    CallSwapTool public immutable callSwapTool;
    constructor (IWETH _weth) payable {
        weth = _weth;
        callSwapTool = new CallSwapTool();
    }
    receive() external payable {}
    function swapExt(
        address tokenIn,
        address tokenOut,
        address to,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )public nonReentrant(){
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransferFrom(tokenIn, msg.sender, callSwapAddr, amountIn);
        uint outBlanceBefore=IERC20(tokenOut).balanceOf(to);
        callSwapTool.callswap(callSwapAddr,datas[20:],"E");//SWAP ERROR
        require(IERC20(tokenOut).balanceOf(to) >= outBlanceBefore+amountOutMin, "OT");//INSUFFICIENT_OUTPUT_AMOUNT
    }
    function swapForEthExt(
        address tokenIn,
        address payable to,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )public nonReentrant(){
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransferFrom(tokenIn, msg.sender,callSwapAddr, amountIn);
        uint outBlanceBefore=to.balance;
        callSwapTool.callswap(callSwapAddr,datas[20:],"FE");//SWAP ERROR
        require(to.balance>=outBlanceBefore+amountOutMin, "FOT");//INSUFFICIENT_OUTPUT_AMOUNT
    }
    function swapFromEthExt(
        address tokenOut,
        address to,
        uint amountOutMin,
        bytes calldata datas
    ) payable nonReentrant()public {
        weth.deposit{value: msg.value}();
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransfer(address(weth), callSwapAddr, msg.value);  
        uint outBlanceBefore=IERC20(tokenOut).balanceOf(to);
        callSwapTool.callswap(callSwapAddr,datas[20:],"FRE");//SWAP ERROR
        require(IERC20(tokenOut).balanceOf(to) >= outBlanceBefore+amountOutMin, "FROT");
    }
    function swapFromPair(
        address tokenIn,
        address tokenOut,
        address pair,
        address to,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )public nonReentrant(){
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransferFrom(tokenIn, msg.sender, pair, amountIn);
        uint outBlanceBefore=IERC20(tokenOut).balanceOf(to);
        callSwapTool.callswap(callSwapAddr,datas[20:],"E");//SWAP ERROR
        require(IERC20(tokenOut).balanceOf(to) >= outBlanceBefore+amountOutMin, "OT");//INSUFFICIENT_OUTPUT_AMOUNT
    }
    function swapFromPairForEth(
        address tokenIn,
        address pair,
        address payable to,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )public nonReentrant(){
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransferFrom(tokenIn, msg.sender,pair, amountIn);
        uint outBlanceBefore=to.balance;
        callSwapTool.callswap(callSwapAddr,datas[20:],"FE");//SWAP ERROR
        require(to.balance>=outBlanceBefore+amountOutMin, "FOT");//INSUFFICIENT_OUTPUT_AMOUNT
    }
    function swapFromPairFromEth(
        address tokenOut,
        address pair,
        address to,
        uint amountOutMin,
        bytes calldata datas
    ) payable nonReentrant()public {
        weth.deposit{value: msg.value}();
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransfer(address(weth), pair, msg.value);  
        uint outBlanceBefore=IERC20(tokenOut).balanceOf(to);
        callSwapTool.callswap(callSwapAddr,datas[20:],"FRE");//SWAP ERROR
        require(IERC20(tokenOut).balanceOf(to) >= outBlanceBefore+amountOutMin, "FROT");
    }
    function swapExt(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )external{
        swapExt(tokenIn,tokenOut,msg.sender,amountIn,amountOutMin,datas);
    }
    function swapForEthExt(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )external{
        swapForEthExt(tokenIn,payable(msg.sender),amountIn,amountOutMin,datas);
    }
    function swapFromEthExt(
        address tokenOut,
        uint amountOutMin,
        bytes calldata datas
    ) payable external {
        swapFromEthExt(tokenOut,msg.sender,amountOutMin,datas);
    }
    function swapFromPair(
        address tokenIn,
        address tokenOut,
        address pair,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )external{
        swapFromPair(tokenIn,tokenOut,pair,msg.sender,amountIn,amountOutMin,datas);
    }
    function swapFromPairForEth(
        address tokenIn,
        address pair,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )external{
        swapFromPairForEth(tokenIn,pair,payable(msg.sender),amountIn,amountOutMin,datas);
    }
    function swapFromPairFromEth(
        address tokenOut,
        address pair,
        uint amountOutMin,
        bytes calldata datas
    ) payable external {
        swapFromPairFromEth(tokenOut,pair,msg.sender,amountOutMin,datas);
    }
    function depositEth() external {
        weth.deposit{value: address(this).balance}();
    }
    function safeTransfer(address token, address to,uint256 value)internal {
        functionCall(token, abi.encodeWithSelector(0xa9059cbb, to, value), 'MTF');//MydefiTransferHelper: TRANSFER_FAILED
    }
    function safeTransferETH(address to, uint256 value)internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    )internal {
        functionCall(token,abi.encodeWithSelector(0x23b872dd,from,to,value),'MTFF');//MydefiTransferHelper: TRANSFER_FROM_FAILED
    }
    
}

contract DefiIoAggregatedSwapRouter is DefiIoAggregatedSwapRouterExt {
    constructor (IWETH _weth) payable DefiIoAggregatedSwapRouterExt(_weth) {}
    function swap(
        address tokenIn,
        address tokenOut,
        address to,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )public nonReentrant(){
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransferFrom(tokenIn, msg.sender, callSwapAddr, amountIn);
        callSwapTool.callswap(callSwapAddr,datas[20:],"E");//SWAP ERROR
        uint out=IERC20(tokenOut).balanceOf(address(this));
        require(out>=amountOutMin, "O");//INSUFFICIENT_OUTPUT_AMOUNT
        safeTransfer(tokenOut, to, out);
    }
    function swapForEth(
        address tokenIn,
        address payable to,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )public nonReentrant(){
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransferFrom(tokenIn, msg.sender,callSwapAddr, amountIn);
        callSwapTool.callswap(callSwapAddr,datas[20:],"FE");//SWAP ERROR
        uint out=weth.balanceOf(address(this));
        require(out>= amountOutMin, "FO");//INSUFFICIENT_OUTPUT_AMOUNT
        weth.withdraw(out);
        safeTransferETH(to, out);
    }
    function swapFromEth(
        address tokenOut,
        address to,
        uint amountOutMin,
        bytes calldata datas
    ) payable nonReentrant()public {
        weth.deposit{value: msg.value}();
        address callSwapAddr=address(bytes20(datas[0:20]));
        safeTransfer(address(weth), callSwapAddr, msg.value);  
        callSwapTool.callswap(callSwapAddr,datas[20:],"FRE");//SWAP ERROR
        uint out=IERC20(tokenOut).balanceOf(address(this));
        require(out>=amountOutMin, "FRO");//INSUFFICIENT_OUTPUT_AMOUNT
        safeTransfer(tokenOut, to, out);
    }
    function swap(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )external{
        swap(tokenIn,tokenOut,msg.sender,amountIn,amountOutMin,datas);
    }
    function swapForEth(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        bytes calldata datas
    )external{
        swapForEth(tokenIn,payable(msg.sender),amountIn,amountOutMin,datas);
    }
    function swapFromEth(
        address tokenOut,
        uint amountOutMin,
        bytes calldata datas
    ) payable external {
        swapFromEth(tokenOut,msg.sender,amountOutMin,datas);
    }
}