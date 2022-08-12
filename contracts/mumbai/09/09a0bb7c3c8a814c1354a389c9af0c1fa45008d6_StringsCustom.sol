/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

// contracts/StringsCustom.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StringsCustom {
    string[] private _store;

    function pushString(string[] calldata _str) external returns (bool) {
        for (uint32 i = 0; i <= _str.length; i++) {
            _store.push(_str[i]);
        }

        return true;
    }
}