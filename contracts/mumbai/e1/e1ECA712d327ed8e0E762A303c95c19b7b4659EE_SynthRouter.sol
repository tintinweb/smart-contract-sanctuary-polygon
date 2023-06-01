//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract SynthRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _CORE_MODULE = 0x2A080457783adDe06009f1959ca7309Bd40CC772;
    address private constant _SYNTH_TOKEN_MODULE = 0x34f5F0720cd92d8E86ad02fEf8B35A7892BeC716;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x53a47bb7) {
                    if lt(sig,0x313ce567) {
                        switch sig
                        case 0x04e7e0b9 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.setDecayRate()
                        case 0x06fdde03 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.name()
                        case 0x095ea7b3 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.approve()
                        case 0x1624f6c6 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.initialize()
                        case 0x1627540c { result := _CORE_MODULE } // CoreModule.nominateNewOwner()
                        case 0x18160ddd { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.totalSupply()
                        case 0x23b872dd { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.transferFrom()
                        leave
                    }
                    switch sig
                    case 0x313ce567 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.decimals()
                    case 0x3659cfe6 { result := _CORE_MODULE } // CoreModule.upgradeTo()
                    case 0x392e53cd { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.isInitialized()
                    case 0x39509351 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.increaseAllowance()
                    case 0x3a98ef39 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.totalShares()
                    case 0x3cf80e6c { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.advanceEpoch()
                    case 0x40c10f19 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.mint()
                    leave
                }
                if lt(sig,0xa457c2d7) {
                    switch sig
                    case 0x53a47bb7 { result := _CORE_MODULE } // CoreModule.nominatedOwner()
                    case 0x70a08231 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.balanceOf()
                    case 0x718fe928 { result := _CORE_MODULE } // CoreModule.renounceNomination()
                    case 0x79ba5097 { result := _CORE_MODULE } // CoreModule.acceptOwnership()
                    case 0x8da5cb5b { result := _CORE_MODULE } // CoreModule.owner()
                    case 0x95d89b41 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.symbol()
                    case 0x9dc29fac { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.burn()
                    leave
                }
                switch sig
                case 0xa457c2d7 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.decreaseAllowance()
                case 0xa9059cbb { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.transfer()
                case 0xa9c1f2f1 { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.decayRate()
                case 0xaaf10f42 { result := _CORE_MODULE } // CoreModule.getImplementation()
                case 0xc7f62cda { result := _CORE_MODULE } // CoreModule.simulateUpgradeTo()
                case 0xda46098c { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.setAllowance()
                case 0xdd62ed3e { result := _SYNTH_TOKEN_MODULE } // SynthTokenModule.allowance()
                leave
            }

            implementation := findImplementation(sig32)
        }

        if (implementation == address(0)) {
            revert UnknownSelector(sig4);
        }

        // Delegatecall to the implementation contract
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}