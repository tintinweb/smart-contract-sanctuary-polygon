/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

/**
 *Submitted for verification at FtmScan.com on 2023-03-16
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

interface Ipair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint) ;
}
interface IERC20{
    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);

}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
contract Swap{
        using SafeMath for uint;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    address private owner;
    
    constructor (){
        owner = msg.sender;
    }
    receive() external payable {}

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) public pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(10000-fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
function getAmountOutAMM(uint amountIn, address tokenIn, address pair,uint fee) public view returns (uint amountOut) {
        return (Ipair(pair).getAmountOut(amountIn, tokenIn)).mul(10000-fee) / 10000;
    }
function gettokens(address pair) public view returns (address,address) {
        return (Ipair(pair).token0(), Ipair(pair).token1());
    }
function execute(address tokenIn, 
        uint amountIn, 
        address pair, 
        uint minAmountOut,
        uint fee,
        address to, 
        bool isAMM
        ) public onlyOwner{
        uint256 amount0Out;
        uint256 amount1Out;
        uint256 amountOut;
        if (isAMM){
            amountOut = getAmountOutAMM(amountIn, tokenIn, pair,fee);
        }else{
            uint r0;
            uint r1;
            (r0,r1,) = Ipair(pair).getReserves();
            amountOut = getAmountOut(amountIn, r0, r1, fee);
        }
        require(amountOut > minAmountOut,"Insufficient");
        if (tokenIn == Ipair(pair).token0()){
            amount0Out = 0;
            amount1Out = amountOut;
        }else{
            amount0Out = amountOut;
            amount1Out = 0;
        }
        safeTransferFrom(tokenIn,msg.sender, pair, amountIn);
        Ipair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
        
    }
    function withdrawEth(uint value) external onlyOwner{
        address to = msg.sender;
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
    
    function withdraw(address token, uint amount) external onlyOwner {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, msg.sender, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Pancake: TRANSFER_FAILED');
    }
}