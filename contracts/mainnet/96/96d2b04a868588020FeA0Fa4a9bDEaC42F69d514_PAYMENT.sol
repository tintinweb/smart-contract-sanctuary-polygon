// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "PaymentSplitter.sol";

contract PAYMENT is PaymentSplitter {

    constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {}

}
/*
["0xe0E1774cE528Cb40fCf948131Bd1c6A72cd817dB", "0xD63db2E580EF6417ef188DeFcdf67252662cbeE9"]

[50, 50]
*/