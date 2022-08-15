// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.5;

contract MyOtherContract {
    /// @dev Name of this feature.
    string public constant FEATURE_NAME = "MyOtherContract";

    function getBlockNumber()
        public
        view
        returns (uint256)
    {
        return block.number;
    }
}