/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface BAMMSwapLike {
    function swap(uint lusdAmount, address returnToken, uint minReturn, address dest, bytes memory data) external returns(uint);
    function cBorrow() view external returns(address);
}

interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

interface ICToken is IERC20 {
    function underlying() external view returns(address);
    function redeem(uint redeemAmount) external returns (uint);
    function mint(uint amount) external returns(uint);
    function symbol() external returns(string memory);
}

interface SushiRouterLike {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);    
}

contract Swap {
    SushiRouterLike constant SUSHI_ROUTER = SushiRouterLike(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address constant WMATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address constant H_MATIC = address(0xEbd7f3349AbA8bB15b897e03D6c1a4Ba95B55e31);
    
    function dumpOnSushi(address src, uint srcAmount, address dest) public {
        address[] memory path = new address[](3);
        path[0] = src;
        path[1] = WMATIC;
        path[2] = dest;

        IERC20(src).approve(address(SUSHI_ROUTER), srcAmount);
        SUSHI_ROUTER.swapExactTokensForTokens(srcAmount, 1, path, address(this), now + 1);
    }

    function dumpMaticOnSushi(uint srcAmount, address dest) public {
        address[] memory path = new address[](2);
        path[0] = WMATIC;
        path[1] = dest;

        SUSHI_ROUTER.swapExactETHForTokens.value(srcAmount)(1, path, address(this), now + 1);
    }

    function bammFlashswap(address initiator, uint lusdAmount, uint returnAmount, bytes memory data) external {
        (ICToken debt, ICToken collateral, bool isMaticCollateral) = abi.decode(data, (ICToken, ICToken, bool));

        // redeem the cCollateral
        collateral.redeem(collateral.balanceOf(address(this)));
        address underlying = isMaticCollateral ? address(0) : collateral.underlying();
        uint underlyingCollateralAmount = isMaticCollateral ? address(this).balance : IERC20(underlying).balanceOf(address(this));

        // dump it on sushi
        address debtUnderlying = debt.underlying();
        if(! isMaticCollateral) {
            dumpOnSushi(underlying, underlyingCollateralAmount, debtUnderlying);
        }
        else {
            dumpMaticOnSushi(underlyingCollateralAmount, debtUnderlying);
        }
        // deposit all balance to cBorrow
        uint debtUnderlyingBalance = IERC20(debtUnderlying).balanceOf(address(this));
        IERC20(debtUnderlying).approve(address(debt), debtUnderlyingBalance);
     
        debt.mint(debtUnderlyingBalance);

        // give allowance, to repay the flash loan
        debt.approve(msg.sender, lusdAmount); // this can be exploited if the contract has non zero balance
    }    

    function swap(address bamm, uint cBorrowAmount, address cCollateral) public {
        bytes memory data = abi.encode(BAMMSwapLike(bamm).cBorrow(), cCollateral, cCollateral == H_MATIC);
        BAMMSwapLike(bamm).swap(cBorrowAmount, cCollateral, 0, address(this), data);
    }

    fallback() external payable {}
}