//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract CoreRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _MAIN_CORE_MODULE = 0xC56c5C73055897B9936aA209007a0A8F119bae8F;
    address private constant _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE = 0xFfBd79aba1F2ceAf86Ac123cB95D12786dfa1383;
    address private constant _BALANCES_MODULE = 0x69cD9eD6Ce0B7AAE075000FB8c7117Ac8D4c2d6f;
    address private constant _CONFIG_MODULE = 0x9755Ef351dFf57Aaf624255773476A9aFBA15d62;
    address private constant _FEES_MODULE = 0xA41494227eab828f23b493050B6340afD1a00262;
    address private constant _FUNDS_MODULE = 0x8C821a0D98dab198D6ac0218bBe69d4fa18b2520;
    address private constant _LIQUIDATIONS_MODULE = 0xb5880B9c7Ba809F082669296418A3b1F5f24d7D0;
    address private constant _MULTICALL_MODULE = 0xD76f2a86cED532F2Bfa6Bcd40F79B1d42f2E30c6;
    address private constant _PROFILES_MODULE = 0xe5729126DCadbE941f40F7Cc566adE0862A4fE66;
    address private constant _SUBSCRIPTIONS_MODULE = 0x1e90Ca391fE25d99bb6FA962FC910924a05199CC;
    address private constant _VAULTS_MODULE = 0x98F783a660C442b68a588d5D27d83543DF5555aC;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x7805ffa5) {
                    if lt(sig,0x447e0ac6) {
                        if lt(sig,0x2d22bef9) {
                            switch sig
                            case 0x0ab33d16 { result := _PROFILES_MODULE } // ProfilesModule.isAuthorized()
                            case 0x0e09db34 { result := _BALANCES_MODULE } // BalancesModule.getRemainingTimeToZero()
                            case 0x0e2a6a58 { result := _VAULTS_MODULE } // VaultsModule.pauseVault()
                            case 0x0e91657d { result := _PROFILES_MODULE } // ProfilesModule.renouncePermission()
                            case 0x11d7a49d { result := _FEES_MODULE } // FeesModule.setGratefulFeeTreasury()
                            case 0x11efbf61 { result := _FEES_MODULE } // FeesModule.getFeePercentage()
                            case 0x1627540c { result := _MAIN_CORE_MODULE } // MainCoreModule.nominateNewOwner()
                            case 0x269c9ab6 { result := _CONFIG_MODULE } // ConfigModule.setLiquidationTimeRequired()
                            leave
                        }
                        switch sig
                        case 0x2d22bef9 { result := _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE } // GratefulAssociatedSystemsModule.initOrUpgradeNft()
                        case 0x2d3e461f { result := _VAULTS_MODULE } // VaultsModule.setMaxRate()
                        case 0x3068e2f6 { result := _VAULTS_MODULE } // VaultsModule.setMinRate()
                        case 0x3659cfe6 { result := _MAIN_CORE_MODULE } // MainCoreModule.upgradeTo()
                        case 0x38a699a4 { result := _PROFILES_MODULE } // ProfilesModule.exists()
                        case 0x39976ed7 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionRates()
                        case 0x3f1a5a5b { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.subscribe()
                        leave
                    }
                    if lt(sig,0x60988e09) {
                        switch sig
                        case 0x447e0ac6 { result := _PROFILES_MODULE } // ProfilesModule.createProfile()
                        case 0x45fe26a2 { result := _CONFIG_MODULE } // ConfigModule.setSolvencyTimeRequired()
                        case 0x4d9e9129 { result := _PROFILES_MODULE } // ProfilesModule.hasPermission()
                        case 0x4e31d06b { result := _PROFILES_MODULE } // ProfilesModule.revokePermission()
                        case 0x53a47bb7 { result := _MAIN_CORE_MODULE } // MainCoreModule.nominatedOwner()
                        case 0x564ab52d { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionDuration()
                        case 0x5d1995f7 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.unsubscribe()
                        case 0x5dd59929 { result := _PROFILES_MODULE } // ProfilesModule.getProfilePermissions()
                        leave
                    }
                    switch sig
                    case 0x60988e09 { result := _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE } // GratefulAssociatedSystemsModule.getAssociatedSystem()
                    case 0x641f9561 { result := _PROFILES_MODULE } // ProfilesModule.getProfileId()
                    case 0x689e5695 { result := _VAULTS_MODULE } // VaultsModule.deactivateVault()
                    case 0x6aa2025b { result := _VAULTS_MODULE } // VaultsModule.addVault()
                    case 0x6ddc6588 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionFrom()
                    case 0x718fe928 { result := _MAIN_CORE_MODULE } // MainCoreModule.renounceNomination()
                    case 0x73ee1bf6 { result := _CONFIG_MODULE } // ConfigModule.getLiquidationTimeRequired()
                    leave
                }
                if lt(sig,0xc2637d01) {
                    if lt(sig,0x9eef2da7) {
                        switch sig
                        case 0x7805ffa5 { result := _LIQUIDATIONS_MODULE } // LiquidationsModule.liquidate()
                        case 0x79ba5097 { result := _MAIN_CORE_MODULE } // MainCoreModule.acceptOwnership()
                        case 0x7f7f51a6 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionId()
                        case 0x8da5cb5b { result := _MAIN_CORE_MODULE } // MainCoreModule.owner()
                        case 0x8e671754 { result := _PROFILES_MODULE } // ProfilesModule.getProfileOwner()
                        case 0x99218ba0 { result := _VAULTS_MODULE } // VaultsModule.activateVault()
                        case 0x9b9954cc { result := _PROFILES_MODULE } // ProfilesModule.grantPermission()
                        case 0x9bedc9db { result := _FUNDS_MODULE } // FundsModule.withdrawFunds()
                        leave
                    }
                    switch sig
                    case 0x9eef2da7 { result := _PROFILES_MODULE } // ProfilesModule.getGratefulProfileAddress()
                    case 0xaaf10f42 { result := _MAIN_CORE_MODULE } // MainCoreModule.getImplementation()
                    case 0xac9650d8 { result := _MULTICALL_MODULE } // MulticallModule.multicall()
                    case 0xae06c1b7 { result := _FEES_MODULE } // FeesModule.setFeePercentage()
                    case 0xb1ffc03e { result := _BALANCES_MODULE } // BalancesModule.balanceOf()
                    case 0xb776ff6b { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.isSubscribed()
                    case 0xb7c61f06 { result := _VAULTS_MODULE } // VaultsModule.getVault()
                    leave
                }
                if lt(sig,0xdc311dd3) {
                    switch sig
                    case 0xc2637d01 { result := _FEES_MODULE } // FeesModule.initializeFeesModule()
                    case 0xc6f79537 { result := _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE } // GratefulAssociatedSystemsModule.initOrUpgradeToken()
                    case 0xc6fd3fcb { result := _BALANCES_MODULE } // BalancesModule.canBeLiquidated()
                    case 0xc7f62cda { result := _MAIN_CORE_MODULE } // MainCoreModule.simulateUpgradeTo()
                    case 0xcc722fac { result := _PROFILES_MODULE } // ProfilesModule.notifyProfileTransfer()
                    case 0xd245d983 { result := _GRATEFUL_ASSOCIATED_SYSTEMS_MODULE } // GratefulAssociatedSystemsModule.registerUnmanagedSystem()
                    case 0xd2aaef4e { result := _FEES_MODULE } // FeesModule.getFeeRate()
                    case 0xd756896b { result := _CONFIG_MODULE } // ConfigModule.initializeConfigModule()
                    leave
                }
                switch sig
                case 0xdc311dd3 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscription()
                case 0xe6701923 { result := _BALANCES_MODULE } // BalancesModule.getFlow()
                case 0xed9ea314 { result := _FUNDS_MODULE } // FundsModule.depositFunds()
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