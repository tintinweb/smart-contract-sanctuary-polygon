//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title UnseenAtomicizer
 * @notice Atomicizer contract used to execute packed calls { ex: fees , royalties }
 * @author Unseen | decapinator.eth
 */
contract UnseenAtomicizer {
    function atomicize(
        address[] calldata addrs,
        uint256[] calldata values,
        uint256[] calldata calldataLengths,
        bytes calldata calldatas
    ) external returns (bytes memory data) {
        require(
            addrs.length == values.length &&
                addrs.length == calldataLengths.length,
            "Addresses, calldata lengths, and values must match in quantity"
        );
        uint8 addrsLength = uint8(addrs.length);
        uint32 cumulativeLength = 0;
        for (uint256 i = 0; i < addrsLength; ++i) {
            (bool success, ) = addrs[i].call{value: values[i]}(
                calldatas[cumulativeLength:cumulativeLength +
                    calldataLengths[i]]
            );
            require(success, "Atomicizer subcall failed");
            cumulativeLength += uint32(calldataLengths[i]);
        }

        return bytes.concat(abi.encode(addrs), calldatas);
    }
}