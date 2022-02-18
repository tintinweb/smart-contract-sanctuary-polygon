/**
 *Submitted for verification at polygonscan.com on 2022-02-18
*/

pragma solidity ^0.8.2;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract MyDefi{
    
    IUniswap uniswap;
    address bridge;
    
    constructor(address _uniswap, address _bridge) public {
        uniswap = IUniswap(_uniswap);
        bridge = _bridge;

    }

    function tastSwapExactETHForTokens(uint amountOut,address token,uint deadline) external payable {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(amountOut,path,msg.sender,deadline);
        bridge.call(abi.encode("transferTokens(address swappedTokenAddress, uint amountOut, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce)"));
    }
}