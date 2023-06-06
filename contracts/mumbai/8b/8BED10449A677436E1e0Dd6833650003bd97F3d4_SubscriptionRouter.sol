//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract SubscriptionRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _MAIN_CORE_MODULE = 0xC56c5C73055897B9936aA209007a0A8F119bae8F;
    address private constant _GRATEFUL_SUBSCRIPTION = 0x52C631c22246d5E46AE5a10a69b24b0E5459729b;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x70a08231) {
                    if lt(sig,0x3659cfe6) {
                        switch sig
                        case 0x01ffc9a7 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.supportsInterface()
                        case 0x06fdde03 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.name()
                        case 0x081812fc { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.getApproved()
                        case 0x095ea7b3 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.approve()
                        case 0x1627540c { result := _MAIN_CORE_MODULE } // MainCoreModule.nominateNewOwner()
                        case 0x23b872dd { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.transferFrom()
                        leave
                    }
                    switch sig
                    case 0x3659cfe6 { result := _MAIN_CORE_MODULE } // MainCoreModule.upgradeTo()
                    case 0x42842e0e { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.safeTransferFrom()
                    case 0x53a47bb7 { result := _MAIN_CORE_MODULE } // MainCoreModule.nominatedOwner()
                    case 0x56189236 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.getCurrentTokenId()
                    case 0x6352211e { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.ownerOf()
                    case 0x6a627842 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.mint()
                    leave
                }
                if lt(sig,0xa6487c53) {
                    switch sig
                    case 0x70a08231 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.balanceOf()
                    case 0x718fe928 { result := _MAIN_CORE_MODULE } // MainCoreModule.renounceNomination()
                    case 0x79ba5097 { result := _MAIN_CORE_MODULE } // MainCoreModule.acceptOwnership()
                    case 0x8da5cb5b { result := _MAIN_CORE_MODULE } // MainCoreModule.owner()
                    case 0x95d89b41 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.symbol()
                    case 0xa22cb465 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.setApprovalForAll()
                    leave
                }
                switch sig
                case 0xa6487c53 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.initialize()
                case 0xaaf10f42 { result := _MAIN_CORE_MODULE } // MainCoreModule.getImplementation()
                case 0xb88d4fde { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.safeTransferFrom()
                case 0xc7f62cda { result := _MAIN_CORE_MODULE } // MainCoreModule.simulateUpgradeTo()
                case 0xc87b56dd { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.tokenURI()
                case 0xe985e9c5 { result := _GRATEFUL_SUBSCRIPTION } // GratefulSubscription.isApprovedForAll()
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