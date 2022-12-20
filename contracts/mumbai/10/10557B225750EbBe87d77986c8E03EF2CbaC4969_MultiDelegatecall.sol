// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiDelegatecall {
    error DelegatecallFailed();

    function multiDelegatecall(bytes[] memory data)
    external
    payable
    returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        for (uint i; i < data.length; i++) {
            (bool ok, bytes memory res) = address(this).delegatecall(data[i]);
            if (!ok) {
                revert DelegatecallFailed();
            }
            results[i] = res;
        }
    }
}