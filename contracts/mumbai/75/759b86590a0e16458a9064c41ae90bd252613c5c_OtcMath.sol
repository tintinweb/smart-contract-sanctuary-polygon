// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library OtcMath {
    function getTakerAmount0(
        uint makerAmount0,
        uint makerAmount1,
        uint takerAmount1
    ) external pure returns (uint) {
        if (makerAmount0 == makerAmount1) {
            return takerAmount1;
        } else {
            return (takerAmount1 * makerAmount0) / makerAmount1;
        }
    }

    function getQuoteAmount(
        uint ulyAmount,
        uint price,
        uint8 ulyDec,
        uint8 quoteDec,
        uint8 priceDec
    ) external pure returns (uint) {
        // amount = x * 10 ** 18 ETH
        // price = y * 10 ** 8 USDT/ETH
        // quoteAmount = (amount / 10**18) * (price / 10**8) * 10**6 = x * y / 10**(18 + 8 - 6)
        return (ulyAmount * price) / 10 ** (ulyDec + quoteDec - priceDec);
    }
}