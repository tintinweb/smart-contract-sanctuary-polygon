// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library VaultInfo {

    enum VaultStatus{
        NotTraded,
        Traded,
        EpochEnded,
        PayoffCalculated,
        FeesCollected,
        Zombie,
        ProcessingDepositQueue,
        DepositQueueProcessed
    }

    struct Vault { 
        string  productName;
        address productAddress;
        uint64  vaultNumber;
        address vaultAddress;
        VaultStatus  vaultStatus;
        uint64  apr; 
        uint  vaultUnderlyingAmount;
        uint  vaultTotalCouponPayoff;
        uint  vaultFinalPayoff;
        bool  knockInOccurred;
        bool  knockOutOccurred;
        address  underlying;
        uint  tradeDate;
        uint startEpoch;
        uint endEpoch;
        uint8 tenorInDays;
    }


}