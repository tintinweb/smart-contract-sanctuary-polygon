// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

library ContractLib {
    error NotAContract();

    // @dev It's important to verify an address is a contract if you're going
    // to call methods on it because many transfer functions check the returned
    // data length to determine success and an address with no bytecode will
    // return no data thus appearing like a success.
   function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    function assertContract(address addr) internal view {
        if (!isContract(addr)) {
            revert NotAContract();
        }
    }

    /// An address created with CREATE2 is deterministic.
    /// Given the input arguments, we know exactly what the resulting
    /// deployed contract's address will be.
    /// @param deployer The address that created the contract.
    /// @param salt The salt used when creating the contract.
    /// @param initCodeHash The keccak hash of the initCode of the deployed contract.
    function getCreate2Address(
        address deployer,
        bytes32 salt,
        bytes32 initCodeHash
    ) public pure returns (address deployedAddr) {
        deployedAddr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            deployer,
                            salt,
                            initCodeHash
                        )
                    )
                )
            )
        );
    }

}