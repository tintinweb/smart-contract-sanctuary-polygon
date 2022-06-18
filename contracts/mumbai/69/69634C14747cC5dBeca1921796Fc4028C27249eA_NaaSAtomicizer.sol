// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/LibBytes.sol";

contract NaaSAtomicizer {
    using LibBytes for bytes;
    
    function atomicize(
        address[] calldata addrs,
        uint256[] calldata values,
        uint256[] calldata calldataLengths,
        bytes calldata calldatas
    ) external {
        require(
            addrs.length == values.length &&
                addrs.length == calldataLengths.length,
            "Addresses, calldata lengths, and values must match in quantity"
        );

        uint256 j = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            bytes memory cd = new bytes(calldataLengths[i]);
            for (uint256 k = 0; k < calldataLengths[i]; k++) {
                cd[k] = calldatas[j];
                j++;
            }
            (bool success, bytes memory result) = addrs[i].call{value: values[i]}(cd);
            require(success, string(abi.encodePacked("Atomicizer subcall failed: ", result.getRevertMsg())));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibBytes {
    function getRevertMsg(bytes memory value)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (value.length < 68) return "Reverted silently";

        assembly {
            // Slice the sighash.
            value := add(value, 0x04)
        }
        return abi.decode(value, (string)); // All that remains is the revert string
    }
}