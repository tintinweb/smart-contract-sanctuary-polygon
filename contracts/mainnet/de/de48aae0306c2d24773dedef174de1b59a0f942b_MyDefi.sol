/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

pragma solidity ^0.8.2;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

interface IWormhole{
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external view returns (uint64 sequence);
}

contract MyDefi{
    
    IUniswap uniswap;
    IWormhole bridge;
    
    constructor(address _uniswap, address _bridge) public {
        uniswap = IUniswap(_uniswap);
        bridge = IWormhole(_bridge);

    }

    function tastSwapExactETHForTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) public returns (uint64){
        // address[] memory path = new address[](2);
        // path[0] = uniswap.WETH();
        // path[1] = token;
        // uniswap.swapExactETHForTokens{value: msg.value}(amountOut,path,receipient,deadline);
        bridge.transferTokens(token, amount, recipientChain, recipient, arbiterFee, nonce);
    }
}