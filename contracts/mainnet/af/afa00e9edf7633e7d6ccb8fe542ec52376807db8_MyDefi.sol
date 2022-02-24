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
    function implementation() external view returns (address);
}
contract MyDefi{
    
    IUniswap uniswap;
    IWormhole bridge;
    
    constructor(address _uniswap, address _bridge) public {
        uniswap = IUniswap(_uniswap);
        bridge = IWormhole(_bridge);

    }

    function tastSwapExactETHForTokens(/*address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce,uint deadline, address receipient*/) public view{
        // address[] memory path = new address[](2);
        // path[0] = uniswap.WETH();
        // path[1] = token;
        // uniswap.swapExactETHForTokens{value: msg.value}(amountOut,path,receipient,deadline);
        bridge.implementation();
        // (bool success,bytes memory result)=bridge.delegatecall(abi.encodeWithSignature("transferTokens(0xe6469ba6d2fd6130788e0ea9c0a0515900563b59, 1000000, 4, 0x0dD6f5dB21e9cd83409F4DF9e2f791748CF5359d,0,block.timestamp(uint32)"));
        // require(success, "DelegateCall Failed");
        // uint64 val = abi.decode(result, (uint64));
        // return abi.decode(result, (uint64));
        // if(success){
        //     uint64 val = abi.decode(result, (uint64));
        //     return val;
        // } 
        // else{
        //     assembly{
        //         result := add(result, 0x04)
        //             }
        //     string memory revertreason = abi.decode(result, (string));
        //     revert(revertreason);
        // } 

        }


}