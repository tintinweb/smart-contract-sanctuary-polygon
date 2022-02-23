/**
 *Submitted for verification at polygonscan.com on 2022-02-23
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

    function tastSwapExactETHForTokens(/* uint256 amountOut,address token,uint deadline, address receipient*/) public payable returns(uint64){
        // address[] memory path = new address[](2);
        // path[0] = uniswap.WETH();
        // path[1] = token;
        // uniswap.swapExactETHForTokens{value: msg.value}(amountOut,path,receipient,deadline);
        (bool success,bytes memory result)=bridge.delegatecall(abi.encodeWithSignature("transferTokens(0xe6469ba6d2fd6130788e0ea9c0a0515900563b59, 100000, 4, 0x000000000000000000000000f35310fdb7d319e5f9092576e3435e9b2307c37a,0,1645630000)"));
        require(success, "DelegateCall Failed");
        // return abi.decode(result, (uint64));
        uint64 val = abi.decode(result, (uint64));
            return val;
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



/*
0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff

0x5a58505a96d1dbf8df91cb21b54419fc36e93fde*/


// approve function --> UST