/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

/**
 *Submitted for verification at Etherscan.io on 2019-07-30
*/

pragma solidity 0.5.16; // optimization enabled, 99999 runs, evm: petersburg


/**
 * @title Immutable Create2 Contract Factory
 * @author 0age
 * @notice This contract provides a safeCreate2 function that takes a salt value
 * and a block of initialization code as arguments and passes them into inline
 * assembly. The contract prevents redeploys by maintaining a mapping of all
 * contracts that have already been deployed, and prevents frontrunning or other
 * collisions by requiring that the first 20 bytes of the salt are equal to the
 * address of the caller (this can be bypassed by setting the first 20 bytes to
 * the null address). There is also a view function that computes the address of
 * the contract that will be created when submitting a given salt or nonce along
 * with a given block of initialization code.
 * @dev This contract has not yet been fully tested or audited - proceed with
 * caution and please share any exploits or optimizations you discover.
 */
contract DisplayCreate2Address {
  


    function findCreate2Address(
        bytes32 salt,
        bytes calldata initCode,
        address factory
    ) external view returns (address deploymentAddress) {
        // determine the address where the contract will be deployed.
        deploymentAddress = address(
            uint160(                      // downcast to match the address type.
                uint256(                    // convert to uint to truncate upper digits.
                    keccak256(                // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked(       // pack all inputs to the hash together.
                            hex"ff",              // start with 0xff to distinguish from RLP.
                            factory,        // this contract will be the caller.
                            salt,                 // pass in the supplied salt value.
                            keccak256(            // pass in the hash of initialization code.
                                abi.encodePacked(
                                    initCode
                                )
                            )
                        )
                    )
                )
            )
        );

        return deploymentAddress;
    }

    /**
     * @dev Compute the address of the contract that will be created when
   * submitting a given salt or nonce to the contract along with the keccak256
   * hash of the contract's initialization code. The CREATE2 address is computed
   * in accordance with EIP-1014, and adheres to the formula therein of
   * `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]` when
   * performing the computation. The computed address is then checked for any
   * existing contract code - if so, the null address will be returned instead.
   * @param salt bytes32 The nonce passed into the CREATE2 address calculation.
   * @param initCodeHash bytes32 The keccak256 hash of the initialization code
   * that will be passed into the CREATE2 address calculation.
   * @return Address of the contract that will be created, or the null address
   * if a contract has already been deployed to that address.
   */
    function findCreate2AddressViaHash(
        bytes32 salt,
        bytes32 initCodeHash,
        address factory
    ) external view returns (address deploymentAddress) {
        // determine the address where the contract will be deployed.
        deploymentAddress = address(
            uint160(                      // downcast to match the address type.
                uint256(                    // convert to uint to truncate upper digits.
                    keccak256(                // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked(       // pack all inputs to the hash together.
                            hex"ff",              // start with 0xff to distinguish from RLP.
                            factory,        // this contract will be the caller.
                            salt,                 // pass in the supplied salt value.
                            initCodeHash          // pass in the hash of initialization code.
                        )
                    )
                )
            )
        );

        return deploymentAddress;
    }


}