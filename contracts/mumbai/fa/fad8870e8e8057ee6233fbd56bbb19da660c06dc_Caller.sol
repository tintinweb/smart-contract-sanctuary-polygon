/**
 *Submitted for verification at polygonscan.com on 2022-02-18
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.12;

contract Caller {

    event Call(bytes);

    function callExternal(address _addr, bytes calldata _data) external {
        (bool success, bytes memory data) = _addr.call(_data);
        require(success);
        emit Call(data);
    }
}