/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// SPDX-License-Identifier: WTFPL

pragma solidity 0.8.13;

contract Lazy {
    function imTooLazyToUseCLI(address _addr, bytes calldata _data) external payable returns (bytes memory) {
        (bool success, bytes memory returndata) = _addr.call{value: msg.value}(_data);
        require(success, "LAZY_CALL");
        return returndata;
    }
}