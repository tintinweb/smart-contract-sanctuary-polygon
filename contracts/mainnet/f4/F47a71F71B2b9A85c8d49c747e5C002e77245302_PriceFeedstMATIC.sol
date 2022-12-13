pragma solidity ^0.8.0;

import "IstMATICRateProvider.sol";
import "IPriceFeeds.sol";
contract PriceFeedstMATIC {
    IPriceFeeds internal constant _PRICEFEED = IPriceFeeds(0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC);
    address internal constant _MATICRATEPROVIDER = 0xdEd6C522d803E35f65318a9a4d7333a22d582199;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant STMATIC = 0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    uint256 internal constant _DECIMALADJUSTER = 100;
    function latestAnswer() external view returns (int256) {
        
        uint256 amountToSwap = IstMATICRateProvider(_MATICRATEPROVIDER).getRate()*_DECIMALADJUSTER;

        return int256(_PRICEFEED
            .queryReturn(
                WMATIC,
                USDC,
                amountToSwap
            )
        );
    }
}

pragma solidity ^0.8.0;

interface IstMATICRateProvider {
    function getRate() external view returns (uint256);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.9.0;


interface IPriceFeeds {

    function pricesFeeds(address token)
        external
        view
        returns(address pricefeed);

    function queryRate(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function amountInEth(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function setPriceFeed(address[] calldata tokens, address[] calldata feeds) external;

    function setDecimals(address[] calldata tokens) external;
}