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

contract MyDefi{
    
    IUniswap uniswap;
    address bridge;
    
    constructor(address _uniswap, address _bridge) public {
        uniswap = IUniswap(_uniswap);
        bridge = _bridge;

    }

    function tastSwapExactETHForTokens(uint amountOut,address token,uint deadline, address receipient) external payable returns(uint64){
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(amountOut,path,receipient,deadline);
        (bool success,bytes memory result)=bridge.delegatecall(abi.encode("transferTokens(token, amountOut, 4, bytes32(uint256(uint160(msg.sender)) << 96),0,1645180936)"));
        require(success, "DelegateCall Failed");
        return abi.decode(result, (uint16));


        }

}