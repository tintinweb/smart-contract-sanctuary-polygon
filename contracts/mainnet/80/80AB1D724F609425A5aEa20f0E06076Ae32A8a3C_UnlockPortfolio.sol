/**
 *Submitted for verification at polygonscan.com on 2022-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICarterasDesbloqueadas {
    function setCartera(address ad,uint cartera) external;
    function getCartera(address ad) external view returns(uint);
}
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external pure returns (uint8);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}
interface ILiquidity {
    function swapAndLiquify(uint256 amount) external;
    function addLiquidity(uint256 tokenAmount, uint256 otherTokenAmount) external;
    function getTokenPrice() external view returns(uint);
}
interface IDEXRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
}
contract UnlockPortfolio {
    ICarterasDesbloqueadas public unlocked_carteras;
    ILiquidity public liquidity;
    mapping (address => bool) public permitedAddress;
    mapping (uint => uint) public amountByPortfolio;
    address constant private USDC=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant private HBLOCK=0x1b69D5b431825cd1fC68B8F883104835F3C72C80;
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        delete unlocked;
        _;
        unlocked = 1;
    }
    constructor(){
        initAmountByPortfolio();
        permitedAddress[msg.sender]=true;
        unlocked_carteras=ICarterasDesbloqueadas(0x9798982ce54DD67D7b225B6043539F505a5287ad);
        liquidity=ILiquidity(0xA967d9e99b94704369e099CAb4c2235Cd417E6b6);
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setPermitedAddress(address ad, bool permited) external whenPermited {
        permitedAddress[ad]=permited;
    }
    function setLiquidityAddress(address ad) external whenPermited {
        liquidity=ILiquidity(ad);
    }
    function setCarterasDesbloquedas(address ad) external whenPermited{
        unlocked_carteras=ICarterasDesbloqueadas(ad);
    }
    function setAmountByPortfolio(uint id, uint amount) external whenPermited {
        amountByPortfolio[id]=amount;
    }
    function swapAndSendHBLOCK(address ad,uint amount) internal{
        address router=0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = HBLOCK;
        IERC20(USDC).approve(router,amount);
        IDEXRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount,0,path,ad,block.timestamp);
    }
    function autoLiquidityFee(uint fee) internal{
        if(fee>0){
            address liquidityContract=address(liquidity);
            uint minBalanceFeeToken=(fee*ILiquidity(liquidityContract).getTokenPrice())/(10**6);
            if(IERC20(HBLOCK).balanceOf(liquidityContract)>=minBalanceFeeToken){
                IERC20(USDC).transfer(liquidityContract,fee);
                ILiquidity(liquidityContract).addLiquidity(minBalanceFeeToken,fee);
            }else{
                swapAndSendHBLOCK(liquidityContract,fee);
                uint tAmount=IERC20(HBLOCK).balanceOf(liquidityContract);
                if(tAmount>200*10**18){
                    ILiquidity(liquidityContract).swapAndLiquify(tAmount);
                }
            }
        }
    }
    function unlockPortfolio(uint _idPortfolio) external lock{
        require(_idPortfolio>0 && _idPortfolio<23, "Portfolio not exist");
        unlocked_carteras.setCartera(msg.sender,_idPortfolio);
        uint amount=amountByPortfolio[_idPortfolio];
        require(IERC20(USDC).transferFrom(msg.sender,address(this),amount),"Error: Not approved or can't transfer this token");
        autoLiquidityFee(amount);
    }
    function initAmountByPortfolio() private {
        uint USDCByCell=10**6/2;//USDC Decimals
        amountByPortfolio[1]=USDCByCell;
        amountByPortfolio[2]=3*USDCByCell;
        amountByPortfolio[3]=6*USDCByCell;
        amountByPortfolio[4]=8*USDCByCell;
        amountByPortfolio[5]=9*USDCByCell;
        amountByPortfolio[6]=11*USDCByCell;
        amountByPortfolio[7]=13*USDCByCell;
        amountByPortfolio[8]=14*USDCByCell;
        amountByPortfolio[9]=16*USDCByCell;
        amountByPortfolio[10]=18*USDCByCell;
        amountByPortfolio[11]=19*USDCByCell;
        amountByPortfolio[12]=21*USDCByCell;
        amountByPortfolio[13]=23*USDCByCell;
        amountByPortfolio[14]=24*USDCByCell;
        amountByPortfolio[15]=26*USDCByCell;
        amountByPortfolio[16]=27*USDCByCell;
        amountByPortfolio[17]=29*USDCByCell;
        amountByPortfolio[18]=31*USDCByCell;
        amountByPortfolio[19]=32*USDCByCell;
        amountByPortfolio[20]=34*USDCByCell;
        amountByPortfolio[21]=37*USDCByCell;
        amountByPortfolio[22]=39*USDCByCell;
    }
    function withdrawToken(address token,address wallet,uint amount) external whenPermited {
        require(IERC20(token).transfer(wallet,amount),"Fail on transfer.");
    }
    function withdrawMatic(address wallet,uint amount) external whenPermited {
        (bool success,) = wallet.call{value:amount}(new bytes(0));
        require(success, 'MATIC TRANSFER FAILED');
    }
}