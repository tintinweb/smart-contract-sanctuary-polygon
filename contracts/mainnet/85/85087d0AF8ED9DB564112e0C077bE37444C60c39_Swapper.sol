/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
interface IDEXRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
}
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    //extra
    function withdraw(uint wad) external;
    function deposit() external payable;
}
interface ILiquidity {
    function swapAndLiquify(uint256 amount) external;
    function addLiquidity(uint256 tokenAmount, uint256 otherTokenAmount) external;
    function getTokenPrice() external view returns(uint);
}
interface IRouter {
    function getBestSwapsByTokens(address tokenA, address tokenB,uint amountA) external view returns (uint price,bytes memory bestSwap);
    function getGasEfficientSwapsByTokens(address tokenA, address tokenB,uint amountA) external view returns (uint price,bytes memory bestSwap);
}
interface ISwap{
    function tokensForTokensByPath(bytes calldata path,uint minAmountTokenB,address to) external;
}
contract Swapper {
    ISwap public swap;
    ILiquidity public liquidity;
    IRouter public route;
    bool public promo=true;
    mapping (address => bool) public permitedAddress;
    address constant private WMATIC=0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant private MATIC=0x0000000000000000000000000000000000001010;
    address constant private USDC=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant private HBLOCK=0x1b69D5b431825cd1fC68B8F883104835F3C72C80;
    address constant private quickSwapRouter=0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    constructor(){
        permitedAddress[msg.sender]=true;
        liquidity=ILiquidity(0xA967d9e99b94704369e099CAb4c2235Cd417E6b6);
        route=IRouter(0x2eCE1d3d6FC18a9Ced99d0Fa3ffdaF0993bdA334);
        swap=ISwap(0x9b7C8a15E5B49897c6F1a1db3aC7fe015044c18c);
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setPermitedAddress(address ad, bool permited) external whenPermited {
        permitedAddress[ad]=permited;
    }
    function setPromo(bool enabled) external whenPermited {
        promo=enabled;
    }
    function setLiquidityAddress(address ad) external whenPermited {
        liquidity=ILiquidity(ad);
    }
    function setRouter(address ad) external whenPermited {
        route=IRouter(ad);
    }
    function setSwap(address ad) external whenPermited {
        swap=ISwap(ad);
    }
    receive() external payable {}
    function swapAndSendHBLOCK(address ad,uint amount) internal{
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = HBLOCK;
        IERC20(USDC).approve(quickSwapRouter,amount);
        IDEXRouter(quickSwapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount,0,path,ad,block.timestamp);
    }
    function autoLiquidityFee(uint fee) internal{
        uint minBalanceFeeToken=(fee*liquidity.getTokenPrice())/(10**6);
        if(IERC20(HBLOCK).balanceOf(address(liquidity))>=minBalanceFeeToken){
            IERC20(USDC).transfer(address(liquidity),fee);
            liquidity.addLiquidity(minBalanceFeeToken,fee);
        }else{
            swapAndSendHBLOCK(address(liquidity),fee);
            uint tAmount=IERC20(HBLOCK).balanceOf(address(liquidity));
            if(tAmount>200*10**18){
                liquidity.swapAndLiquify(tAmount);
            }
        }
    }
    function payfee(address token) internal {
        uint feeOnTokenPair=IERC20(token).balanceOf(address(this));
        if(feeOnTokenPair>0){
            if(token!=USDC){
                (uint price,bytes memory path) = route.getGasEfficientSwapsByTokens(token,USDC,feeOnTokenPair);
                if(price>0){
                    require(IERC20(token).transfer(address(swap),feeOnTokenPair));
                    swap.tokensForTokensByPath(path,0,address(this));
                    feeOnTokenPair=IERC20(USDC).balanceOf(address(this));
                }else{
                    require(IERC20(token).transfer(msg.sender,feeOnTokenPair));//else Error on transfer
                    return;
                }
            }
            if(promo){
                uint amountPromo=feeOnTokenPair/3;
                swapAndSendHBLOCK(msg.sender,amountPromo);
                feeOnTokenPair-=amountPromo;
            }
            autoLiquidityFee(feeOnTokenPair);
        }
    }
    function getBestSwapsByTokens(address tokenA, address tokenB,uint amountA) external view returns (uint,bytes memory){
        return route.getBestSwapsByTokens(tokenA,tokenB,amountA);
    }
    function bestSwapTokensForTokensByPath(bytes calldata path,uint amountA,uint minAmountTokenB) external payable {
        require(path.length>0);//Bad tokens
        bool hasTokenA;address tokenA;address tokenB;
        assembly {
            tokenA := shr(96, calldataload(add(path.offset, 20)))
            tokenB := shr(96, calldataload(add(path.offset,sub(path.length,24))))
        }
        (hasTokenA,tokenB,amountA)=receiveTokenA(tokenA,tokenB,amountA);
        if(hasTokenA){
            swap.tokensForTokensByPath(path,minAmountTokenB,msg.sender);
            payfee(tokenB);
            refundMatic();
        }
    }
    function bestPathSwapTokensForTokens(address tokenA,address tokenB,uint amountA,uint minAmountTokenB) external payable {
        require(tokenA!=tokenB && tokenA!=address(0) && tokenB!=address(0));//Bad tokens
        bool hasTokenA;
        (hasTokenA,tokenB,amountA)=receiveTokenA(tokenA,tokenB,amountA);
        if(hasTokenA){
            (uint price,bytes memory path) = route.getGasEfficientSwapsByTokens(tokenA,tokenB,amountA);
            require(price>0);//No route for swap
            swap.tokensForTokensByPath(path,minAmountTokenB,msg.sender);
            payfee(tokenB);
            refundMatic();
        }
    }
    //refund Matic sends by error
    function refundMatic() internal{
        uint amount;
        assembly {
            amount := selfbalance()
        }
        if(amount>0){
            (bool success, )=msg.sender.call{value:amount}("");
            require(success);//else Transfer failed
        }
    }
    function receiveTokenA(address tokenA,address tokenB,uint amountA) internal returns(bool,address,uint){
        if(WMATIC==tokenA && MATIC==tokenB){
            IERC20(tokenA).transferFrom(msg.sender,address(this),amountA);
            IERC20(WMATIC).withdraw(amountA);
            (bool success, )=msg.sender.call{value:amountA}("");
            require(success);//else Transfer failed
            return (false,tokenB,amountA);
        }
        uint MATICBalance;
        assembly {
            MATICBalance := selfbalance()
        }
        bool isNative=(MATIC==tokenA || WMATIC==tokenA) && MATICBalance>0;
        if(isNative){
            amountA=MATICBalance;
            (bool success, )=WMATIC.call{value:amountA}("");
            require(success);//else Transfer failed
            if(WMATIC==tokenB){
                require(IERC20(WMATIC).transfer(msg.sender,amountA));//else Transfer failed
                return (false,tokenB,amountA);
            }
            IERC20(WMATIC).transfer(address(swap),amountA);
        }
        if(!isNative){
            IERC20(tokenA).transferFrom(msg.sender,address(swap),amountA);
        }
        if(MATIC==tokenB){
            tokenB=WMATIC;
        }
        return (true,tokenB,amountA);
    }
}