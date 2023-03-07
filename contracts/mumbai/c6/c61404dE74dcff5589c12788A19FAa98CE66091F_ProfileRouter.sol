//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract ProfileRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _MAIN_CORE_MODULE = 0x6F84331DB6a19762aa9830E4d966397D108cE9aa;
    address private constant _GRATEFUL_PROFILE = 0x4D7336Ce6eaA8cdc40753DD90711370Cd8719ae1;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x6352211e) {
                    if lt(sig,0x3659cfe6) {
                        switch sig
                        case 0x01ffc9a7 { result := _GRATEFUL_PROFILE } // GratefulProfile.supportsInterface()
                        case 0x06fdde03 { result := _GRATEFUL_PROFILE } // GratefulProfile.name()
                        case 0x081812fc { result := _GRATEFUL_PROFILE } // GratefulProfile.getApproved()
                        case 0x095ea7b3 { result := _GRATEFUL_PROFILE } // GratefulProfile.approve()
                        case 0x1627540c { result := _MAIN_CORE_MODULE } // MainCoreModule.nominateNewOwner()
                        case 0x18160ddd { result := _GRATEFUL_PROFILE } // GratefulProfile.totalSupply()
                        case 0x23b872dd { result := _GRATEFUL_PROFILE } // GratefulProfile.transferFrom()
                        case 0x2f745c59 { result := _GRATEFUL_PROFILE } // GratefulProfile.tokenOfOwnerByIndex()
                        leave
                    }
                    switch sig
                    case 0x3659cfe6 { result := _MAIN_CORE_MODULE } // MainCoreModule.upgradeTo()
                    case 0x392e53cd { result := _GRATEFUL_PROFILE } // GratefulProfile.isInitialized()
                    case 0x40c10f19 { result := _GRATEFUL_PROFILE } // GratefulProfile.mint()
                    case 0x42842e0e { result := _GRATEFUL_PROFILE } // GratefulProfile.safeTransferFrom()
                    case 0x42966c68 { result := _GRATEFUL_PROFILE } // GratefulProfile.burn()
                    case 0x4f6ccce7 { result := _GRATEFUL_PROFILE } // GratefulProfile.tokenByIndex()
                    case 0x53a47bb7 { result := _MAIN_CORE_MODULE } // MainCoreModule.nominatedOwner()
                    leave
                }
                if lt(sig,0xa6487c53) {
                    switch sig
                    case 0x6352211e { result := _GRATEFUL_PROFILE } // GratefulProfile.ownerOf()
                    case 0x70a08231 { result := _GRATEFUL_PROFILE } // GratefulProfile.balanceOf()
                    case 0x718fe928 { result := _MAIN_CORE_MODULE } // MainCoreModule.renounceNomination()
                    case 0x79ba5097 { result := _MAIN_CORE_MODULE } // MainCoreModule.acceptOwnership()
                    case 0x8832e6e3 { result := _GRATEFUL_PROFILE } // GratefulProfile.safeMint()
                    case 0x8da5cb5b { result := _MAIN_CORE_MODULE } // MainCoreModule.owner()
                    case 0x95d89b41 { result := _GRATEFUL_PROFILE } // GratefulProfile.symbol()
                    case 0xa22cb465 { result := _GRATEFUL_PROFILE } // GratefulProfile.setApprovalForAll()
                    leave
                }
                switch sig
                case 0xa6487c53 { result := _GRATEFUL_PROFILE } // GratefulProfile.initialize()
                case 0xaaf10f42 { result := _MAIN_CORE_MODULE } // MainCoreModule.getImplementation()
                case 0xb88d4fde { result := _GRATEFUL_PROFILE } // GratefulProfile.safeTransferFrom()
                case 0xc7f62cda { result := _MAIN_CORE_MODULE } // MainCoreModule.simulateUpgradeTo()
                case 0xc87b56dd { result := _GRATEFUL_PROFILE } // GratefulProfile.tokenURI()
                case 0xe985e9c5 { result := _GRATEFUL_PROFILE } // GratefulProfile.isApprovedForAll()
                case 0xff53fac7 { result := _GRATEFUL_PROFILE } // GratefulProfile.setAllowance()
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