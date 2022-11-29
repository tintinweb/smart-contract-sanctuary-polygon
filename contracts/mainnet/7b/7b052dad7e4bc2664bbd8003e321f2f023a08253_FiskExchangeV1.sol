/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


interface FiskExchangeInterface{

    //Trident Router
    function exactInputSingleWithNativeToken(uint256 amountIn, uint256 amountOutMinimum, address pool, address tokenIn, bytes calldata data) external payable returns (uint256 amountOut);

    //BentoBox
    function toAmount(address token, uint256 share, bool roundUp) external view returns (uint256 amount);
    function toShare(address token, uint256 amount, bool roundUp) external view returns (uint256 share);

    //Liquidity Pool
    function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);
    function getAmountIn(bytes calldata data) external view returns (uint256 finalAmountIn);
}

contract FiskExchangeV1{

    address constant private routerAddress = 0xc5017BE80b4446988e8686168396289a9A62668E;
    address constant private bentoAddress = 0x0319000133d3AdA02600f0875d2cf03D442C3367;
    address constant private liquidityAddress = 0x1e8e058d6267936c92e9d0D83D34B7960daf69B9;

    FiskExchangeInterface immutable private router = FiskExchangeInterface(routerAddress);
    FiskExchangeInterface immutable private bento = FiskExchangeInterface(bentoAddress);
    FiskExchangeInterface immutable private liquidity = FiskExchangeInterface(liquidityAddress);


    //Trident Router
    function SwapMaticForFisk(uint256 amount, uint256 slippage) payable public returns(uint256 amountOut){

        require(slippage < 150);

        uint256 amountIn = amount;
        uint256 amountOutMinimum = amount *  (1000 - slippage) / 1000;
        address pool = liquidityAddress;
        address tokenIn = address(0);
        bytes memory data = abi.encode(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, msg.sender, 1);

         return router.exactInputSingleWithNativeToken{value:msg.value}(amountIn, amountOutMinimum, pool, tokenIn, data);
    }


    //BentoBox
    function _wrappedToUnwrapped(uint256 amount) private view returns(uint256){

        return(bento.toAmount(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, amount, false));
    }

    function _unwrappedToWrapped(uint256 share) private view returns(uint256){

        return(bento.toShare(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, share, false));
    }
    

    //Liquidity Pool
    function ExactFiskForMatic(uint256 inputFisk) public view returns(uint256){
        
        return(_wrappedToUnwrapped(liquidity.getAmountOut(abi.encode(0xaBE9255A99fd2EFB4a15fcF375E5D3987E32Ad74, inputFisk))));
    }
    
    function ExactMaticForFisk(uint256 inputMatic) public view returns(uint256){

        return(liquidity.getAmountOut(abi.encode(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, _unwrappedToWrapped(inputMatic))));
    }
    
    function FiskForExactMatic(uint256 outputMatic) public view returns(uint256){

        return(liquidity.getAmountIn(abi.encode(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, _unwrappedToWrapped(outputMatic)))); 
    }
    
    function MaticForExactFisk(uint256 outputFisk) public view returns(uint256){

        return(_wrappedToUnwrapped(liquidity.getAmountIn(abi.encode(0xaBE9255A99fd2EFB4a15fcF375E5D3987E32Ad74, outputFisk))));
    }


    receive() external payable{
        
        revert();
    }

    fallback() external{
        
        revert();   
    }
}