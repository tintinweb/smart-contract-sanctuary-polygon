/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WalletParts {
    fallback() external payable {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            switch div(calldataload(0), exp(2, 224))
            case 0x9d55b53f /* bytes4(keccak256("execute(uint256,address,uint256,bytes,uint8,bytes32,bytes32,uint8,bytes32,bytes32)")) */ {
                execute()
                stop()
            }
            case 0x7fb372b0 /* bytes4(keccak256("replaceGatekeeper(address,address)")) */ {
                replaceGatekeeper()
                stop()
            }
            case 0x754d1d54 /* bytes4(keccak256("initialize(uint256,address,address,address)")) */ {
                initialize()
                stop()
            }
            case 0x2f54bf6e /* bytes4(keccak256("isOwner(address)")) */ {
                isOwner()
                stop()
            }
            case 0xc19d93fb /* bytes4(keccak256("state()")) */ {
                state()
                stop()
            }
            default {
                // We stop the transaction here and accept any ETH that was passed in.
                stop()
            }

            // ================= END OF function() =================

            /// This function should only be called with the understanding that
            /// it's going to use the lowest 4 memory slots. The caller should
            /// not store its own state in those slots.
            function __ecrecover(h, v, r, s) -> a {
                // The builtin ecrecover() function is stored in a builtin contract deployed at
                // address 0x1, with a gas cost hard-coded to 3000 Gas. It expects to be passed
                // exactly 4 words:
                // (offset 0x00) keccak256 hash of the signed data
                // (offset 0x20) v value of the ECDSA signature, with v==27 or v==28
                // (offset 0x40) r value of the ECDSA signature
                // (offset 0x60) s value of the ECDSA signature

                // Since we will receive signatures with v values of 0 or 1, we can unconditionally
                // add 27 to transform them into the format expected by ecrecover().
                v := add(v, 27)
                sstore(1007, v)

                mstore(0, h)
                mstore(0x20, v)
                mstore(0x40, r)
                mstore(0x60, s)

                // Instead of sending 3000 == 0x0bb8 Gas, we will send a little more with 0x0c00
                // since this will have the same result and save us some Gas when deploying the
                // contract (0x00 bytes are cheaper to deploy).
                if iszero(staticcall(0x0c00, 0x1, 0, 0x80, 0, 0x20)) {
                    invalid()
                }

                a := mload(0)
            }

            /// Verifies and updates the wallet state based on a user-provided identifier.
            ///
            /// See the top level documentation for the format of the state and the identifier.
            ///
            /// This will either succeed and update the wallet state with the new nonce, or
            /// stop the execution.
            function __verifyAndUpdateState(_identifier) {
                let _state := sload(0)

                // Mask to check that the the top 76 bits of the _state and of the identifier are
                // equal.
                //
                // It's cheaper to construct the mask than a constant. Since shift instructions are
                // not available yet in mainnet, we use multiplications and divisions to achieve
                // the same effect.
                //
                // Value is 0b11..1100..00 ie. 76 ones followed by 180 zeroes
                let mask := mul(not(0), exp(2, 180))

                // Slot number stored in the identifier.
                let slot := and(_identifier, 0xFF)

                // Shift that allows to read/write in this slot.
                let shift := exp(2, mul(slot, 18))

                // New value of the nonce present in the identifier.
                // Old version of the nonce present in the current _state.
                //
                // Both nonces are shifted to the left by (18 * slot).
                //
                // Note that 0x3FFFF is 18 bits all set to 1, which is the mask for a slot content.
                let newNonce := mul(
                    and(div(_identifier, 0x100), 0x3FFFF),
                    shift
                )
                let oldNonce := and(_state, mul(0x3FFFF, shift))

                // Invalid if:
                //   `(_state & mask) != (_identifier & mask)
                //    || slot > 9
                //    || newNonce <= oldNonce
                //    || timestamp() > (!mask & _identifier) >> 26)`
                if or(
                    or(
                        or(
                            // The initial 76 bits of the identifier must match those of
                            // the wallet _state.
                            iszero(
                                eq(and(_state, mask), and(_identifier, mask))
                            ),
                            // Though a full byte is used to encode the slot number, only 10 slots
                            // (numbered 0 to 9) are actually available.
                            gt(slot, 9)
                        ),
                        // The new nonce must be greater than the old nonce, but skipping
                        // individual values is fine - it's a way of invalidating pending
                        // transactions.
                        iszero(gt(newNonce, oldNonce))
                    ),
                    // Expiry is a timestamp (stored as a 154 bits) after which
                    // the transaction is no longer valid. This provides a strong
                    // guarantee to the sender that once-signed transactions do not
                    // remain valid forever.
                    //
                    // To extract expiry from the identifier, first we mask out the top 76 bits,
                    // then we shift the rest 26 bits to the right, which leaves us with only the
                    // middle 154 bits containing the expiry.
                    gt(timestamp(), div(and(not(mask), _identifier), 0x4000000))
                ) {
                    invalid()
                }

                // By substracting the correctly bit-positioned old nonce from the
                // _state, we effectively reset the nonce bits to zero. Since only
                // bits within the slot are set, it's not possible for this
                // operation to change any other bit in the _state. For the same
                // reason, adding the new nonce to the reset _state replaces the
                // old nonce while leaving the rest of the _state untouched.
                //
                // Overflow cannot happen due to both nonces being at most 18 bit values.
                _state := add(sub(_state, oldNonce), newNonce)

                sstore(0, _state)
            }

            /// @notice Check if a given address is an owner of this wallet.
            ///
            /// @param _address address The address to check.
            ///
            /// @return uint256 1 if the address is an owner, 0 otherwise.
            function isOwner() {
                let _address := calldataload(0x4)

                // Only a non-zero address can be an owner. However, we don't need to check that
                // _address != 0 since if that's the case, we would load storage at 0x0 which is
                // the wallet state which can never have value 1 anyway.

                mstore(0, eq(sload(_address), 1)) // 1 signifies an owner.
                return(0, 0x20)
            }

            /**
             * @notice initializes state and ownership
             * @dev can only be called once
             * @dev Does not check the validity of arguments
             * @param _state uint256 Initial state of the wallet
             * @param _gatekeeperA address First gatekeeper
             * @param _gatekeeperB address Second gatekeeper
             * @param _owner address Initial owner
             */
            function initialize() {
                // The constructor does not check the validity of its arguments. It is up to the
                // deployer of the contract to construct one with a valid state.
                //
                // In particular, the following should hold true for the initial state of the contract
                // to be valid:
                // (1) _gatekeeperA != 0
                // (2) _gatekeeperB != 0
                // (3) _gatekeeperA != _gatekeeperB != _owner
                // (4) _gatekeeperA, gatekeeperB and _owner should be 160 bit addresses with the higher
                //      96 bits set to zero
                // (5) _state higher 76 bits should be non-zero, and different from all the other
                //     deployments of the wallet
                // (6) _state lower 180 bits should be non-all-ones (and preferably all zeroes)
                //
                // We order the operations this way to explicitly support the case where _owner == 0,
                // which will result in a wallet deployed without any owner. This is a valid state for
                // the wallet, even though of course we probably want to add an owner before doing any
                // execute() or transferErc20() operation on it.

                // Uninitalized contract will have zero value at location
                let init := sload(0xaa)

                //verify contract has not been initialized
                if eq(init, 1) {
                    invalid()
                }

                //initialize flag
                sstore(0xaa, 1)

                //calldata
                let _state := calldataload(0x4)
                let _gatekeeperA := calldataload(0x24)
                let _gatekeeperB := calldataload(0x44)
                let _owner := calldataload(0x64)

                sstore(_owner, 1) // 1 signifies an owner.
                sstore(0, _state) // The 0th slot always contains the state.
                sstore(_gatekeeperA, 3) // 3 signifies a gatekeeper.
                sstore(_gatekeeperB, 3) // 3 signifies a gatekeeper.

                stop()
            }

            /// @notice Replace a gatekeeper with another address.
            ///
            /// @dev This cannot be called directly. You must call through execute().
            ///
            /// @dev This will always leave the wallet with two different valid gatekeepers.
            ///
            /// @param _old address The address to remove from gatekeepers.
            /// @param _new address The address to add to gatekeepers.
            function replaceGatekeeper() {
                let _old := calldataload(0x4)
                let _new := calldataload(0x24)

                // Invalid if:
                //   `caller() != address() || state[_old] != 3 || state[_new] != 0`
                if or(
                    or(
                        // Checks whether the currently executing code was called by the
                        // contract itself, and reverts if that's not the case.
                        iszero(eq(caller(), address())),
                        // _old must currently be a gatekeeper.
                        //
                        // Note that if _old == 0 this will always trip since state is
                        // guaranteed to be >3.
                        iszero(eq(sload(_old), 3))
                    ),
                    // _new must not have any previous role (i.e. owner or gatekeeper).
                    //
                    // Note that if _new == 0 this will always trip since state is
                    // guaranteed to be >3.
                    iszero(eq(sload(_new), 0))
                ) {
                    invalid()
                }

                // Note that at this point we are guaranteed that _old != _new since we could
                // not have both storage[_old] == 3 and storage[_new] == 0 at the same time.

                sstore(_old, 0) // Delete the old mapping.
                sstore(_new, 3) // Add the new mapping.

                stop()
            }

            /// @notice Executes a simple, inflexible multi-signed transaction.
            ///
            /// @dev The first signer can be an owner or a gatekeeper; the second signer must be a
            /// gatekeeper.
            ///
            /// @param _identifier uint256 A valid transaction identifier.
            /// @param _destination address The destination to call.
            /// @param _value uint256 The ETH value to include in the call.
            /// @param _data bytes The data to include in the call.
            /// @param _sig1V uint8 Part `v` of the first signer's signature.
            /// @param _sig1R bytes32 Part `r` of the first signer's signature.
            /// @param _sig1S bytes32 Part `s` of the first signer's signature.
            /// @param _sig2V uint8 Part `v` of the second signer's signature.
            /// @param _sig2R bytes32 Part `r` of the second signer's signature.
            /// @param _sig2S bytes32 Part `s` of the second signer's signature.
            function execute() {
                // When executing this function, the calldata is intended to be:
                //
                //   start | description                   | length in bytes
                // --------+-------------------------------+------------------
                //   0x00  | Method signature              | 0x4
                //   0x04  | _identifier                   | 0x20
                //   0x24  | _destination                  | 0x20
                //   0x44  | _value                        | 0x20
                //   0x64  | _dataOffset                   | 0x20
                //   0x84  | _sig1V                        | 0x20
                //   0xa4  | _sig1R                        | 0x20
                //   0xc4  | _sig1S                        | 0x20
                //   0xe4  | _sig2V                        | 0x20
                //   0x104 | _sig2R                        | 0x20
                //   0x124 | _sig2S                        | 0x20
                //   0x144 | _dataLength                   | 0x20
                //   0x164 | _data                         | _dataLength
                //
                // We will copy these in memory using the following layout:
                //
                //   start | description                   | length in bytes
                // --------+-------------------------------+------------------
                //   0x00  | Scratch space for __ecrecover | 0x80
                //   0x80  | EIP191 prefix 0x1900          | 0x2          \
                //   0x82  | EIP191 address                | 0x20         |
                //   0xa2  | _methodSignature              | 0x4          |
                //   0xa6  | _identifier                   | 0x20         | sig1 & sig2
                //   0xc6  | _destination                  | 0x20         |
                //   0xe6  | _value                        | 0x20         |
                //   0x106 | _data                         | _dataLength  /
                //
                // This memory layout is set up so that we can hash all the operation data directly.
                //
                // Note that the hash includes the method signature itself, so that a blob signed
                // for execute() cannot be used for transferErc20(), or the opposite.
                //
                // Note that the hash also includes the wallet address() so that an operation signed
                // for this wallet cannot be applied to another wallet that would happen to have the
                // same owners/gatekeepers.

                let _dataOffset := calldataload(0x64)
                sstore(1000, _dataOffset)
                let _dataLength := calldataload(0x144)
                sstore(1001, _dataLength)
                // Invalid if:
                //   `_dataOffset != 0x140 || _dataLength > 0xffff`
                if or(
                    // _dataLength should always be 0x140 bytes after the first parameter.
                    // Make sure this is the case.
                    iszero(eq(0x140, _dataOffset)),
                    // Limit data length to a reasonable size so that
                    // we don't have to worry about overflow later.
                    gt(_dataLength, 0xffff)
                ) {
                    invalid()
                }

                // Set up EIP191 prefix.
                mstore8(0x80, 0x19)
                mstore8(0x81, 0x00)
                mstore(0x82, address())

                // Copy method signature + _identifier + _destination + _value to memory.
                calldatacopy(0xa2, 0, 0x64)
                log0(0xa2, 0x64)

                // Copy _data (without offset or length) after that.
                calldatacopy(0x106, 0x164, _dataLength)

                // Hash all user data except the signatures.
                //
                // The second argument cannot overflow due to an
                // earlier check limiting the maximum value of the
                // length variable.
                let hash := keccak256(0x80, add(0x86, _dataLength))
                sstore(1002, hash)

                // First signature.
                let _sigV := calldataload(0x84)
                sstore(1003, _sigV)
                let _sigR := calldataload(0xa4)
                sstore(1004, _sigR)
                let _sigS := calldataload(0xc4)
                sstore(1005, _sigS)

                // Recover the first signer. Calling this function
                // is going to overwrite the first 4 memory slots,
                // but we haven't stored anything there.
                let signer := __ecrecover(hash, _sigV, _sigR, _sigS)
                sstore(1006, signer)

                sstore(1008, sload(signer))

                // Invalid if:
                //   `signer == 0 || state[signer] == 0`

                if iszero(signer) {
                    invalid()
                }

                if iszero(sload(signer)) {
                    invalid()
                }

                // Second signature. Reuse variables to avoid stack depth issues.
                // _sigV := calldataload(0xe4)
                // _sigR := calldataload(0x104)
                // _sigS := calldataload(0x124)

                // // Recover the second signer.
                // signer := __ecrecover(hash, _sigV, _sigR, _sigS)

                // // Invalid if:
                // //   `signer == 0 || state[signer] != 3`
                // if or(
                //     // The second signer should not be zero.
                //     iszero(signer),
                //     // The second signer must be a gatekeeper.
                //     //
                //     // Since we know that `signer != 0` at this point, we know that `sload(signer)`
                //     // cannot be the state, and thus it can only be 0, 1 or 3 depending on
                //     // the role of `signer`.
                //     iszero(eq(sload(signer), 3))
                // ) {
                //     invalid()
                // }

                // // Now make sure the nonce is valid, and consume it if that's the case.
                // let _identifier := calldataload(0x4)
                // __verifyAndUpdateState(_identifier)

                // // Finally, run the call, passing the _destination, _value and _data that we
                // // have verified.
                // let _destination := calldataload(0x24)
                // let _value := calldataload(0x44)
                // if iszero(
                //     call(gas(), _destination, _value, 0x106, _dataLength, 0, 0)
                // ) {
                //     invalid()
                // }

                stop()
            }

            /// @notice Get the current state of the wallet.
            ///
            /// @return uint256 State of the wallet.
            function state() {
                mstore(0, sload(0))
                return(0, 0x20)
            }
        }
    }

    receive() external payable {}
}