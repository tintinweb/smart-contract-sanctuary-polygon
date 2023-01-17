/**
 *Submitted for verification at polygonscan.com on 2023-01-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

uint256 constant DIGITS = 5;

contract ARTRatesManager {

    string[] supportedCurrencies = ["USD", "EUR", "UAH", "JPY", "AUD", "CAD", "SEK", "CNY", "GBP"];

    struct CartCurencies {
        mapping(string => uint256) values;
    }

    mapping(string => uint256) rates;

    event UnsupportedCurrency(address owner, string currency);

    function updateRate(string memory currencyISO, uint rate) public {
        if (isSupportedCurrency(currencyISO)) {
            rates[currencyISO] = rate;
        }
    }

    function calculateART(string[] memory currencies, uint256[] memory values) public returns (uint256) {
        uint256 artTokenAmountResult = 0;
        for (uint256 index = 0; index < currencies.length; index++) {
            string memory currency = currencies[index];
            if (isSupportedCurrency(currency)) {
                uint256 value = values[index];
                uint256 rate = rates[currency];

                uint256 artTokenAmount = value * rate;
                artTokenAmountResult += artTokenAmount;
            } else {
                emit UnsupportedCurrency(msg.sender, currency);
            }
        }
        return artTokenAmountResult;
    }

    function isSupportedCurrency(string memory currency) internal view returns (bool) {
        for (uint256 index = 0; index < supportedCurrencies.length; index++) {
            if (compare(currency, supportedCurrencies[index])) {
                return true;
            }
        }
        return false;
    }

    function compare(string memory strLeft, string memory strRight) public pure returns (bool) {
        if (bytes(strLeft).length != bytes(strRight).length) {
            return false;
        }
        return keccak256(abi.encodePacked(strLeft)) == keccak256(abi.encodePacked(strRight));
    }
}