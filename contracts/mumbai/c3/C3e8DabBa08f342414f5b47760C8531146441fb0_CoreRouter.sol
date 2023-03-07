//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract CoreRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _MAIN_CORE_MODULE = 0x7cb603D79d670Fa69eA099281Dd5eBcDc58115Fc;
    address private constant _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE = 0x31f4607b71D359e12CE6aD84cc2E521234725360;
    address private constant _BALANCES_MODULE = 0x0f8299253fA40169C367d34868A4127F45Ec1Ff1;
    address private constant _CONFIG_MODULE = 0xEB2CcE814d31D9a70c8b4c5632BA6c0988821d98;
    address private constant _FEES_MODULE = 0x8E8F3d0eEfa6Da7aB5CBBA6F77ececd0B7667dEB;
    address private constant _FUNDS_MODULE = 0x770C27e9daF50FbDd0a1390303F2B68B9A7939e9;
    address private constant _LIQUIDATIONS_MODULE = 0x38bb4f81718fDB3eC2978a59D9BCD866572954C6;
    address private constant _PROFILES_MODULE = 0x3fb54FFf38cE88c1602Ee19BF501D52644064CCD;
    address private constant _SUBSCRIPTIONS_MODULE = 0x03009928d0948178aAb9eEc3C4d9fEcfe947B19c;
    address private constant _VAULTS_MODULE = 0x9aB03395751f486b7b4B5e34de1C82c4fdEA4C93;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x79ba5097) {
                    if lt(sig,0x39976ed7) {
                        if lt(sig,0x2d3e461f) {
                            switch sig
                            case 0x0e09db34 { result := _BALANCES_MODULE } // BalancesModule.getRemainingTimeToZero()
                            case 0x0e2a6a58 { result := _VAULTS_MODULE } // VaultsModule.pauseVault()
                            case 0x11d7a49d { result := _FEES_MODULE } // FeesModule.setGratefulFeeTreasury()
                            case 0x11efbf61 { result := _FEES_MODULE } // FeesModule.getFeePercentage()
                            case 0x1627540c { result := _MAIN_CORE_MODULE } // MainCoreModule.nominateNewOwner()
                            case 0x269c9ab6 { result := _CONFIG_MODULE } // ConfigModule.setLiquidationTimeRequired()
                            case 0x2d22bef9 { result := _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE } // GratefulAssociatedSystemsModule.initOrUpgradeNft()
                            leave
                        }
                        switch sig
                        case 0x2d3e461f { result := _VAULTS_MODULE } // VaultsModule.setMaxRate()
                        case 0x2e1120a1 { result := _FUNDS_MODULE } // FundsModule.depositFunds()
                        case 0x3068e2f6 { result := _VAULTS_MODULE } // VaultsModule.setMinRate()
                        case 0x352e2760 { result := _FUNDS_MODULE } // FundsModule.withdrawFunds()
                        case 0x3659cfe6 { result := _MAIN_CORE_MODULE } // MainCoreModule.upgradeTo()
                        case 0x38ed2de7 { result := _PROFILES_MODULE } // ProfilesModule.allowProfile()
                        leave
                    }
                    if lt(sig,0x641f9561) {
                        switch sig
                        case 0x39976ed7 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionRates()
                        case 0x45fe26a2 { result := _CONFIG_MODULE } // ConfigModule.setSolvencyTimeRequired()
                        case 0x53a47bb7 { result := _MAIN_CORE_MODULE } // MainCoreModule.nominatedOwner()
                        case 0x564ab52d { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionDuration()
                        case 0x5a0be8d0 { result := _PROFILES_MODULE } // ProfilesModule.isProfileAllowed()
                        case 0x60988e09 { result := _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE } // GratefulAssociatedSystemsModule.getAssociatedSystem()
                        case 0x610aabdc { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.subscribe()
                        leave
                    }
                    switch sig
                    case 0x641f9561 { result := _PROFILES_MODULE } // ProfilesModule.getProfileId()
                    case 0x6aa2025b { result := _VAULTS_MODULE } // VaultsModule.addVault()
                    case 0x6ddc6588 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionFrom()
                    case 0x718fe928 { result := _MAIN_CORE_MODULE } // MainCoreModule.renounceNomination()
                    case 0x73ee1bf6 { result := _CONFIG_MODULE } // ConfigModule.getLiquidationTimeRequired()
                    case 0x774e7eae { result := _PROFILES_MODULE } // ProfilesModule.getApprovedAndProfileId()
                    leave
                }
                if lt(sig,0xc7f62cda) {
                    if lt(sig,0xb776ff6b) {
                        switch sig
                        case 0x79ba5097 { result := _MAIN_CORE_MODULE } // MainCoreModule.acceptOwnership()
                        case 0x7f7f51a6 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionId()
                        case 0x8da5cb5b { result := _MAIN_CORE_MODULE } // MainCoreModule.owner()
                        case 0x9fdc9f4e { result := _PROFILES_MODULE } // ProfilesModule.disallowProfile()
                        case 0xaaf10f42 { result := _MAIN_CORE_MODULE } // MainCoreModule.getImplementation()
                        case 0xae06c1b7 { result := _FEES_MODULE } // FeesModule.setFeePercentage()
                        case 0xb1ffc03e { result := _BALANCES_MODULE } // BalancesModule.balanceOf()
                        leave
                    }
                    switch sig
                    case 0xb776ff6b { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.isSubscribed()
                    case 0xb7c61f06 { result := _VAULTS_MODULE } // VaultsModule.getVault()
                    case 0xc2637d01 { result := _FEES_MODULE } // FeesModule.initializeFeesModule()
                    case 0xc2f610e4 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.unsubscribe()
                    case 0xc6f79537 { result := _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE } // GratefulAssociatedSystemsModule.initOrUpgradeToken()
                    case 0xc6fd3fcb { result := _BALANCES_MODULE } // BalancesModule.canBeLiquidated()
                    leave
                }
                if lt(sig,0xe6701923) {
                    switch sig
                    case 0xc7f62cda { result := _MAIN_CORE_MODULE } // MainCoreModule.simulateUpgradeTo()
                    case 0xd245d983 { result := _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE } // GratefulAssociatedSystemsModule.registerUnmanagedSystem()
                    case 0xd2aaef4e { result := _FEES_MODULE } // FeesModule.getFeeRate()
                    case 0xd5b3e4d9 { result := _LIQUIDATIONS_MODULE } // LiquidationsModule.liquidate()
                    case 0xd756896b { result := _CONFIG_MODULE } // ConfigModule.initializeConfigModule()
                    case 0xdc311dd3 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscription()
                    leave
                }
                switch sig
                case 0xe6701923 { result := _BALANCES_MODULE } // BalancesModule.getFlow()
                case 0xf536c520 { result := _PROFILES_MODULE } // ProfilesModule.createProfile()
                case 0xfae82647 { result := _VAULTS_MODULE } // VaultsModule.unpauseVault()
                case 0xfc725969 { result := _FEES_MODULE } // FeesModule.getFeeTreasuryId()
                case 0xfcacdcdf { result := _CONFIG_MODULE } // ConfigModule.getSolvencyTimeRequired()
                case 0xffdd4ce8 { result := _BALANCES_MODULE } // BalancesModule.getBalanceCurrentData()
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