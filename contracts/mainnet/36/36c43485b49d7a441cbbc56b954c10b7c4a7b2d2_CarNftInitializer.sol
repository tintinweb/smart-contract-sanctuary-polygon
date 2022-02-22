// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.9;

import "./Cars.sol";

contract CarNftInitializer is Cars {
    constructor() {
        carModels.push("Z1300");
        carModels.push("Z1800");
        carModels.push("Z2400");
        carModels.push("G2700");
        carModels.push("G3000");
        carModels.push("G3700");
        carModels.push("X4200");
        carModels.push("X4500");
        carModels.push("X5200");
        carModels.push("X6200");

        nativeToken = IERC20Metadata(0xe7359a30fA1f9925df406682673DC862513b7Bf9);
        gasToken = IERC20Burnable(0xb115ecE47FfBd8477eBC2a87198c48140dDD2510);
        _benf = address(0x4fB82C4927cd7BE24FEA45179a6db9998eb3818C);

        _initialProps[0] = CarProps(0, 14, 12, 8, 13);
        _initialProps[1] = CarProps(1, 16, 13, 9, 13);
        _initialProps[2] = CarProps(2, 18, 16, 10, 13);
        _initialProps[3] = CarProps(3, 60, 16, 8, 80);
        _initialProps[4] = CarProps(4, 60, 12, 12, 90);
        _initialProps[5] = CarProps(5, 60, 12, 15, 100);
        _initialProps[6] = CarProps(6, 80, 20, 20, 60);
        _initialProps[7] = CarProps(7, 85, 30, 25, 60);
        _initialProps[8] = CarProps(8, 96, 40, 30, 70);
        _initialProps[9] = CarProps(9, 113, 50, 35, 70);

        uint256 factor = 10**nativeToken.decimals();
        uint256 initPrice = 10 * factor;
        for (uint256 i = 0; i < 10; i++) {
            carPrices[i] = initPrice;
            initPrice += (10 * factor);
        }

        upgradeLimits.push(UpgradeXpLimit(50, 200));
        upgradeLimits.push(UpgradeXpLimit(200, 500));
        upgradeLimits.push(UpgradeXpLimit(500, 10000));
    }

    function setCarPrice(uint256 id, uint256 price) external onlyOwner {
        carPrices[id] = price;
    }

    function switchMintActive() external onlyOwner {
        mintActive = !mintActive;
    }
}