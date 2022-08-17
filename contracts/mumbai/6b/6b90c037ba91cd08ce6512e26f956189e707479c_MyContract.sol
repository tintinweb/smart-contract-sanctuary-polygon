// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

contract MyContract
{

    struct TestStruct {
        address a;
        address b;
        uint256 c;
        uint256 d;
    }

    constructor(address addr)
        public
    {
        // solhint-disable-next-line no-empty-blocks
    }

    function executeTest()
        public
        payable
        returns (bytes memory returnResult)
    {
        TestStruct memory args;
        {
            bytes memory abcd = new bytes(0);
            args = abi.decode(abcd, (TestStruct));
        }
    }
}