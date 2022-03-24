// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import {FlashLoanReceiverBase} from "./FlashloanReceiverBase.sol";
import {ILendingPool, ILendingPoolAddressesProvider, IERC20} from "./Interfaces.sol";
import {SafeMath} from "./Libraries.sol";
import {Withdrawable} from "./Withdrawable.sol";

contract FlashloanMoula is FlashLoanReceiverBase, Withdrawable {
    using SafeMath for uint256;

    IUniswapV2Router02 buyRouter;
    IUniswapV2Router02 sellRouter;

    address assetToProfitFrom;
    uint256 assetBorrowedAmount;

    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public {
    }

    function executeOperation(address[] calldata assets, uint256[] calldata amounts, uint256[] calldata premiums, address initiator, bytes calldata params) external override returns (bool)    {
        try this.takeArbitrage(assets[0]) {
        } catch Error(string memory reason) {
            // Failed with reason
        } catch (bytes memory) {
            // failing assertion, division by zero.. blah blah
        }

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }

    function _flashloan(address[] memory assets, uint256[] memory amounts) internal {
        address receiverAddress = address(this);

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        uint256[] memory modes = new uint256[](assets.length);

        // 0 = no debt (flash), 1 = stable, 2 = variable
        for (uint256 i = 0; i < assets.length; i++) {
            modes[i] = 0;
        }

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function flashloan(
        address _assetToBorrow,
        uint256 _amount,
        address _assetToProfitFrom,
        address _buyRouterAddress,
        address _sellRouterAddress
    ) public onlyOwner {
        // Init
        assetToProfitFrom = _assetToProfitFrom;
        assetBorrowedAmount = _amount;
        buyRouter = IUniswapV2Router02(_buyRouterAddress);
        sellRouter = IUniswapV2Router02(_sellRouterAddress);

        // Flashloan
        address[] memory assets = new address[](1);
        assets[0] = _assetToBorrow;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        _flashloan(assets, amounts);
    }

    function takeArbitrage(address _assetBorrowed) public {
        uint deadline = block.timestamp + 120;

        uint assetToProfitFromAmount = buyRouter.getAmountsOut(assetBorrowedAmount, getPath(_assetBorrowed, assetToProfitFrom))[1];

        IERC20(_assetBorrowed).approve(address(buyRouter), assetBorrowedAmount);

        // Trade 1: Execute swap of Ether into designated ERC20 token on buyRouter
        // https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#swapethforexacttokens
        try buyRouter.swapTokensForExactTokens(
            assetToProfitFromAmount,
            assetBorrowedAmount,
            getPath(_assetBorrowed, assetToProfitFrom),
            address(this),
            deadline
        ){
        } catch Error(string memory reason) {
        }

        uint assetToBorrowAmountBack = sellRouter.getAmountsOut(assetToProfitFromAmount, getPath(assetToProfitFrom, _assetBorrowed))[1];

        IERC20(assetToProfitFrom).approve(address(sellRouter), assetToProfitFromAmount);

        // Trade 2: Execute swap of the ERC20 token back into ETH on sellRouter
        try sellRouter.swapExactTokensForTokens(
            assetToProfitFromAmount,
            assetToBorrowAmountBack,
            getPath(assetToProfitFrom, _assetBorrowed),
            address(this),
            deadline
        ){
        } catch Error(string memory reason) {
        }
    }

    function getPath(address assetA, address assetB) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = assetA;
        path[1] = assetB;
        return path;
    }
}