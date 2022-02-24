/**
 *Submitted for verification at polygonscan.com on 2022-02-24
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
    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

}
contract MyDefi{
    
    IUniswap uniswap;
    IWormhole bridge;
    
    constructor(address _uniswap) public {
        uniswap = IUniswap(_uniswap);
        // bridge = IWormhole(_bridge);

    }

    function tastSwapExactETHForTokens(address _bridgeAddress, address SwappedTokenAddress,uint256 amountOut, uint16 recipientChainId, bytes32 recipient, uint256 arbiterFeeValue,uint32 nonceValue ) external {
        // address[] memory path = new address[](2);
        // path[0] = uniswap.WETH();
        // path[1] = token;
        // uniswap.swapExactETHForTokens{value: msg.value}(amountOut,path,receipient,deadline);
        bridge = IWormhole(_bridgeAddress);
        bridge.transferTokens(SwappedTokenAddress, amountOut, recipientChainId, recipient, arbiterFeeValue,nonceValue);
        

        }


}



/*
0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff

0xaca654bdf148d1a5d490f5d1a44b84b4773b934c*/


// approve function --> UST