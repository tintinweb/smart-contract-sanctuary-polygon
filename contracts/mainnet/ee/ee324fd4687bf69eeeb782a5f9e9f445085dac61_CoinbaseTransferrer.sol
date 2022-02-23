/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.12;

contract CoinbaseTransferrer {
    function coinbasetransfer() external payable {
        block.coinbase.transfer(msg.value);
    }
}