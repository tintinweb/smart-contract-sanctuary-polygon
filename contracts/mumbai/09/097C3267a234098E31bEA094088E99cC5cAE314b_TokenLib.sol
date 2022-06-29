// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../Interfaces/StructLib.sol";
import "./SpotFeeLib.sol";
import "./Strings.sol";

import "../StMaster/StMaster.sol";

library TokenLib {
    using strings for *;

    event AddedSecTokenType(uint256 id, string name, StructLib.SettlementType settlementType, uint64 expiryTimestamp, uint256 underlyerTypeId, uint256 refCcyId, uint16 initMarginBips, uint16 varMarginBips);
    event SetFutureVariationMargin(uint256 tokenTypeId, uint16 varMarginBips);
    event SetFutureFeePerContract(uint256 tokenTypeId, uint256 feePerContract);

    event Burned(uint256 tokenTypeId, address indexed from, uint256 burnedQty);
    event BurnedFullSecToken(uint256 indexed stId, uint256 tokenTypeId, address indexed from, uint256 burnedQty);
    event BurnedPartialSecToken(uint256 indexed stId, uint256 tokenTypeId, address indexed from, uint256 burnedQty);

    event Minted(uint256 indexed batchId, uint256 tokenTypeId, address indexed to, uint256 mintQty, uint256 mintSecTokenCount);
    event MintedSecToken(uint256 indexed stId, uint256 indexed batchId, uint256 tokenTypeId, address indexed to, uint256 mintedQty);

    event AddedBatchMetadata(uint256 indexed batchId, string key, string value);
    event SetBatchOriginatorFee_Token(uint256 indexed batchId, StructLib.SetFeeArgs originatorFee);
    event SetBatchOriginatorFee_Currency(uint256 indexed batchId, uint16 origCcyFee_percBips_ExFee);

    //event dbg1(uint256 id, uint256 typeId);
    //event dbg2(uint256 postIdShifted);

    //
    // TOKEN TYPES
    //
    function addSecTokenType(
        StructLib.LedgerStruct storage       ld,
        StructLib.StTypesStruct storage      std,
        StructLib.CcyTypesStruct storage     ctd,
        string memory                        name,
        StructLib.SettlementType             settlementType,
        StructLib.FutureTokenTypeArgs memory ft,
        address payable                      cashflowBaseAddr
    )
    public {
        // * allow any number of of direct spot or future types on commodity contract
        // * allow only a single direct spot type on cashflow-base contract
        // * allow any number of cashflow-base (indirect) spot types on cashflow-controller contract
        //   (todo - probably should allow direct futures-settlement type on cashflow-controller; these are centralised i.e. can't be withdrawn, so don't need separate base contracts)
        require((ld.contractType == StructLib.ContractType.COMMODITY           && cashflowBaseAddr == address(0x0)) ||
                (ld.contractType == StructLib.ContractType.CASHFLOW_BASE       && cashflowBaseAddr == address(0x0) && settlementType == StructLib.SettlementType.SPOT && std._tt_Count == 0) ||
                (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER && cashflowBaseAddr != address(0x0) && settlementType == StructLib.SettlementType.SPOT)
               , "Bad cashflow request");

        require(bytes(name).length > 0, "Invalid name");

        for (uint256 tokenTypeId = 1; tokenTypeId <= std._tt_Count; tokenTypeId++) {
            require(keccak256(abi.encodePacked(std._tt_name[tokenTypeId])) != keccak256(abi.encodePacked(name)), "Duplicate name");
        }
        if (settlementType == StructLib.SettlementType.FUTURE) {
            // Certik: (Major) TLL-01 | Inexplicable Constant
            // Resolved: (Major) TLL-01 | Removed ft.expiryTimestamp > 1585699708 require statement
            require(ft.underlyerTypeId > 0 && ft.underlyerTypeId <= std._tt_Count, "Bad underlyerTypeId");
            require(std._tt_settle[ft.underlyerTypeId] == StructLib.SettlementType.SPOT, "Bad underyler settlement type");
            require(ft.refCcyId > 0 && ft.refCcyId <= ctd._ct_Count, "Bad refCcyId");
            // Certik: (Major) TLL-02 | Unsafe Addition
            // Resolved: (Major) TLL-02 | Solidity v0.8.0 uses SafeMath by default, no changes required for fix
            require(ft.initMarginBips + ft.varMarginBips <= 10000, "Bad total margin");
            require(ft.contractSize > 0, "Bad contractSize");
        }
        else if (settlementType == StructLib.SettlementType.SPOT) {
            require(ft.expiryTimestamp == 0, "Invalid expiryTimestamp");
            require(ft.underlyerTypeId == 0, "Invalid underlyerTypeId");
            require(ft.refCcyId == 0, "Invalid refCcyId");
            require(ft.contractSize == 0, "Invalid contractSize");
            require(ft.feePerContract == 0, "Invalid feePerContract");
        }

        std._tt_Count++;
        require(std._tt_Count <= 0xFFFFFFFFFFFFFFFF, "Too many types"); // max 2^64

        if (cashflowBaseAddr != address(0x0)) {
            // add base, indirect type (to cashflow controller)
            //StMaster base = StMaster(cashflowBaseAddr);
            //string memory s0 = base.name;
            //strings.slice memory s = "asd".toSlice();
            //string memory ss = s.toString();
            //string storage baseName = base.name;
            std._tt_name[std._tt_Count] = name; // https://ethereum.stackexchange.com/questions/3727/contract-reading-a-string-returned-by-another-contract
            std._tt_settle[std._tt_Count] = settlementType;
            std._tt_addr[std._tt_Count] = cashflowBaseAddr;

            // set/segment base's curMaxId
            uint256 segmentStartId = (std._tt_Count << 192)
                //| ((1 << 192) - 1) // test: token id overflow
                | 0 // segment - first 64 bits: type ID (max 0xFFFFFFFFFFFFFFFF), remaining 192 bits: local/segmented sub-id
            ;
            StMaster base = StMaster(cashflowBaseAddr);
            base.setTokenTotals(segmentStartId, segmentStartId, 0, 0);
        }
        else {
            // add direct type (to commodity or cashflow base)
            std._tt_name[std._tt_Count] = name;
            std._tt_settle[std._tt_Count] = settlementType;
            std._tt_addr[std._tt_Count] = cashflowBaseAddr;

            // futures
            if (settlementType == StructLib.SettlementType.FUTURE) {
                std._tt_ft[std._tt_Count] = ft;
            }
        }

        emit AddedSecTokenType(std._tt_Count, name, settlementType, ft.expiryTimestamp, ft.underlyerTypeId, ft.refCcyId, ft.initMarginBips, ft.varMarginBips);
    }

    function setFuture_FeePerContract(
        StructLib.StTypesStruct storage std, uint256 tokTypeId, uint128 feePerContract
    )
    public {
        require(tokTypeId >= 1 && tokTypeId <= std._tt_Count, "Bad tokTypeId");
        require(std._tt_settle[tokTypeId] == StructLib.SettlementType.FUTURE, "Bad token settlement type");
        std._tt_ft[tokTypeId].feePerContract = feePerContract;
        emit SetFutureFeePerContract(tokTypeId, feePerContract);
    }

    function setFuture_VariationMargin(
        StructLib.StTypesStruct storage std, uint256 tokTypeId, uint16 varMarginBips
    )
    public {
        require(tokTypeId >= 1 && tokTypeId <= std._tt_Count, "Bad tokTypeId");
        require(std._tt_settle[tokTypeId] == StructLib.SettlementType.FUTURE, "Bad token settlement type");
        require(std._tt_ft[tokTypeId].initMarginBips + varMarginBips <= 10000, "Bad total margin");
        std._tt_ft[tokTypeId].varMarginBips = varMarginBips;
        emit SetFutureVariationMargin(tokTypeId, varMarginBips);
    }

    function getSecTokenTypes(
        StructLib.StTypesStruct storage std
    )
    public view returns (StructLib.GetSecTokenTypesReturn memory) {
        StructLib.SecTokenTypeReturn[] memory tokenTypes;
        tokenTypes = new StructLib.SecTokenTypeReturn[](std._tt_Count);

        for (uint256 tokTypeId = 1; tokTypeId <= std._tt_Count; tokTypeId++) {
            tokenTypes[tokTypeId - 1] = StructLib.SecTokenTypeReturn({
                    id: tokTypeId,
                  name: std._tt_name[tokTypeId],
        settlementType: std._tt_settle[tokTypeId],
                    ft: std._tt_ft[tokTypeId],
      cashflowBaseAddr: std._tt_addr[tokTypeId]
            });
        }

        StructLib.GetSecTokenTypesReturn memory ret = StructLib.GetSecTokenTypesReturn({
            tokenTypes: tokenTypes
        });
        return ret;
    }

    //
    // MINTING
    //
    struct MintSecTokenBatchArgs {
        uint256              tokTypeId;
        uint256              mintQty; // accept 256 bits, so we can downcast and test if in 64-bit range
        int64                mintSecTokenCount;
        address payable      batchOwner;
        StructLib.SetFeeArgs origTokFee;
        uint16               origCcyFee_percBips_ExFee;
        string[]             metaKeys;
        string[]             metaValues;
    }
    function mintSecTokenBatch(
        StructLib.LedgerStruct storage  ld,
        StructLib.StTypesStruct storage std,
        MintSecTokenBatchArgs memory    a
    )
    public {
        require(ld._contractSealed, "Contract is not sealed");
        require(a.tokTypeId >= 1 && a.tokTypeId <= std._tt_Count, "Bad tokTypeId");
        require(a.mintSecTokenCount == 1, "Set mintSecTokenCount 1");
        require(a.mintQty >= 0x1 && a.mintQty <= 0x7fffffffffffffff, "Bad mintQty"); // max int64
        require(uint256(ld._batches_currentMax_id) + 1 <= 0xffffffffffffffff, "Too many batches");
        require(a.origTokFee.fee_max >= a.origTokFee.fee_min || a.origTokFee.fee_max == 0, "Bad fee args");
        require(a.origTokFee.fee_percBips <= 10000, "Bad fee args");
        require(a.origTokFee.ccy_mirrorFee == false, "ccy_mirrorFee unsupported for token-type fee");
        require(a.origCcyFee_percBips_ExFee <= 10000, "Bad fee args");

        // cashflow base: enforce uni-batch
        if (ld.contractType == StructLib.ContractType.CASHFLOW_BASE) {
            require(ld._batches_currentMax_id == 0, "Bad cashflow request");
            // todo: cashflow base - only allow mint from controller...
        }

        // check for token id overflow (192 bit range is vast - really not necessary)
        if (ld.contractType == StructLib.ContractType.CASHFLOW_BASE) {
            uint256 l_id = ld._tokens_currentMax_id & ((1 << 192) - 1); // strip leading 64-bits (controller's type ID) - gets a "local id", i.e. a count
            require(l_id + uint256(uint64(a.mintSecTokenCount)) <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "Too many tokens"); // max 192-bits trailing bits
        }

        // ### string[] param lengths are reported as zero!
        /*require(metaKeys.length == 0, "At least one metadata key must be provided");
        require(metaKeys.length <= 42, "Maximum metadata KVP length is 42");
        require(metaKeys.length != metaValues.length, "Metadata keys/values length mismatch");
        for (uint i = 0; i < metaKeys.length; i++) {
            require(bytes(metaKeys[i]).length == 0 || bytes(metaValues[i]).length == 0, "Zero-length metadata key or value supplied");
        }*/

        // create batch (for all contract types, i.e. batch is duplicated/denormalized in cashflow base)
        StructLib.SecTokenBatch memory newBatch = StructLib.SecTokenBatch({
                         id: ld._batches_currentMax_id + 1,
            mintedTimestamp: block.timestamp,
                  tokTypeId: a.tokTypeId,
                  mintedQty: uint256(a.mintQty),
                  burnedQty: 0,
                   metaKeys: a.metaKeys,
                 metaValues: a.metaValues,
                 origTokFee: a.origTokFee,
  origCcyFee_percBips_ExFee: a.origCcyFee_percBips_ExFee,
                 originator: a.batchOwner
        });
        ld._batches[newBatch.id] = newBatch;
        ld._batches_currentMax_id++;

        // emit batch create event (commodity & controller - not base; its batch and tok-type IDs are local)
        if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) {
            emit Minted(newBatch.id, a.tokTypeId, a.batchOwner, uint256(a.mintQty), uint256(uint64(a.mintSecTokenCount)));
        }

        // create ledger entry as required
        StructLib.initLedgerIfNew(ld, a.batchOwner);

        // mint & assign STs (delegate to cashflow base in cashflow controller)
        if (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER) { // controller: delegate to base
            //require(std._tt_addr[a.tokTypeId] != address(0x0), "Bad cashflow request");
            StMaster base = StMaster(std._tt_addr[a.tokTypeId]);

            // emit (preempt) token minted event(s) (controller - not base; its batch and tok-type IDs are local)
            for (int256 ndx = 0; ndx < a.mintSecTokenCount; ndx++) {
                uint256 newId = base.getSecToken_MaxId() + 1 + uint256(ndx);
                int64 stQty = int64(uint64(a.mintQty)) / int64(a.mintSecTokenCount);
                emit MintedSecToken(newId, newBatch.id, a.tokTypeId, a.batchOwner, uint256(uint64(stQty)));
            }

            // mint - passthrough to base
            base.mintSecTokenBatch(
                1/*tokTypeId*/, // base: UNI_TOKEN (controller does type ID mapping for clients)
                a.mintQty,
                a.mintSecTokenCount,
                a.batchOwner,
                a.origTokFee,
                a.origCcyFee_percBips_ExFee,
                a.metaKeys,
                a.metaValues
            );
        }
        else {
            for (int256 ndx = 0; ndx < a.mintSecTokenCount; ndx++) {
                uint256 newId = ld._tokens_currentMax_id + 1 + uint256(ndx);
                int64 stQty = int64(uint64(a.mintQty)) / int64(a.mintSecTokenCount);
                ld._sts[newId].batchId = uint64(newBatch.id);
                ld._sts[newId].mintedQty = stQty;
                ld._sts[newId].currentQty = stQty; // mint ST

                // emit token minted event(s) (core)
                if (ld.contractType == StructLib.ContractType.COMMODITY) {
                    emit MintedSecToken(newId, newBatch.id, a.tokTypeId, a.batchOwner, uint256(uint64(stQty)));
                }

                ld._ledger[a.batchOwner].tokenType_stIds[a.tokTypeId].push(newId); // assign ST to ledger

                // initialize base token ID, if not already set
                // this is needed because cashflow base types use a segmented ID [64 leading bits of controller type ID data & 192 trailing bits of token ID data]
                // without base ID being set, there's not way for base types to walk their maps of {ID => token}
                if (ld._tokens_base_id == 0) {
                    ld._tokens_base_id = newId;
                }
            }
        }

        // core - update current/max STID
        ld._tokens_currentMax_id += uint256(uint64(a.mintSecTokenCount)); // controller: minted COUNT (not an ID), base / commodity: a true max. LOCAL ID

        // core - update global totals; note - totals are maintained on base AND on controller/commodity
        //if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) {
            ld._spot_totalMintedQty += uint256(a.mintQty);
            ld._ledger[a.batchOwner].spot_sumQtyMinted += uint256(a.mintQty);
        //}
    }

    //
    // BURNING
    //
    struct BurnTokenArgs {
        address                         ledgerOwner;
        uint256                         tokTypeId;
        int256                          burnQty; // accept 256 bits, so we can downcast and test if in 64-bit range
        uint256[]                       k_stIds;
    }
    function burnTokens(
        StructLib.LedgerStruct storage  ld,
        StructLib.StTypesStruct storage std,
        BurnTokenArgs memory            a
    )
    public {
        require(ld._contractSealed, "Contract is not sealed");
        require(ld._ledger[a.ledgerOwner].exists == true, "Bad ledgerOwner");
        require(a.burnQty >= 0x1 && a.burnQty <= 0x7fffffffffffffff, "Bad burnQty"); // max int64

        // core - update global totals, preemptively; note - totals are maintained on base AND on controller/commodity
        //if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) {
            ld._spot_totalBurnedQty += uint256(a.burnQty);
            ld._ledger[a.ledgerOwner].spot_sumQtyBurned += uint256(a.burnQty);
        //}

        // emit burn event (core & controller)
        if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) {
            emit Burned(a.tokTypeId, a.ledgerOwner, uint256(a.burnQty));
        }

        // controller: delegate burn op. to base
        if (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER) {
            StMaster base = StMaster(std._tt_addr[a.tokTypeId]);
            base.burnTokens(
                a.ledgerOwner,
                1/*a.tokTypeId*/, // base: UNI_TOKEN (controller does type ID mapping for clients),
                a.burnQty,
                a.k_stIds
            );
            return;
        }

        // base / commodity: validate, burn & emit events
        require(a.tokTypeId >= 1 && a.tokTypeId <= std._tt_Count, "Bad tokTypeId");
        if (a.k_stIds.length == 0) { // burn by qty
            require(StructLib.sufficientTokens(ld, a.ledgerOwner, a.tokTypeId, int256(a.burnQty), 0) == true, "Insufficient tokens");
        }
        // else { // burn by ID(s)
        //     int256 stQty;
        //     for (uint256 i = 0; i < a.k_stIds.length; i++) {
        //         require(StructLib.tokenExistsOnLedger(ld, a.tokTypeId, a.ledgerOwner, a.k_stIds[i]), "Bad stId"); // check supplied ST belongs to the supplied owner
        //         stQty += ld._sts[a.k_stIds[i]].currentQty; // get implied burn qty
        //     }
        //     require(stQty == a.burnQty, "Quantity mismatch");
        // }

        // burn (remove or resize) sufficient ST(s)
        uint256 ndx = 0;
        int64 remainingToBurn = int64(a.burnQty);
        
        while (remainingToBurn > 0) {
            uint256[] storage tokenType_stIds = ld._ledger[a.ledgerOwner].tokenType_stIds[a.tokTypeId];
            uint256 stId = tokenType_stIds[ndx];
            
            // Certik: (Minor) TLL-03 | Potentially Negative Quantities Negative quantities should be skipped by the while loop as the addition in L380 will lead to the remaining to burn increasing.
            // Resolved: (Minor) TLL-03 | Added a check to ensure only non-negative values of StQty to be considered for burning.      
            int64 stQty = ld._sts[stId].currentQty;
            require(stQty >= 0, "Unexpected stQty");
            
            uint64 batchId = ld._sts[stId].batchId;
            // if burning by specific ST IDs, skip over STs that weren't specified
            bool skip = false;
            if (a.k_stIds.length > 0) {
                skip = true;
                for (uint256 i = 0; i < a.k_stIds.length; i++) {
                    if (a.k_stIds[i] == stId) { skip = false; break; }
                }
            }
            if (skip) {
                ndx++;
            }
            else {
                if (remainingToBurn >= stQty) {
                    // burn the full ST
                    //ld._sts_currentQty[stId] = 0;
                    ld._sts[stId].currentQty = 0;

                    // remove from ledger
                    tokenType_stIds[ndx] = tokenType_stIds[tokenType_stIds.length - 1];
                    //tokenType_stIds.length--;
                    tokenType_stIds.pop(); // solc 0.6

                    //ld._ledger[a.ledgerOwner].tokenType_sumQty[a.tokTypeId] -= stQty;

                    // burn from batch
                    ld._batches[batchId].burnedQty += uint256(uint64(stQty));

                    remainingToBurn -= stQty;

                    emit BurnedFullSecToken(stId, ld.contractType == StructLib.ContractType.CASHFLOW_BASE ? stId >> 192 : a.tokTypeId, a.ledgerOwner, uint256(uint64(stQty)));
                }
                else {
                    // resize the ST (partial burn)
                    //ld._sts_currentQty[stId] -= remainingToBurn;
                    ld._sts[stId].currentQty -= remainingToBurn;

                    // retain on ledger
                    //ld._ledger[a.ledgerOwner].tokenType_sumQty[a.tokTypeId] -= remainingToBurn;

                    // burn from batch
                    ld._batches[batchId].burnedQty += uint256(uint64(remainingToBurn));

                    emit BurnedPartialSecToken(stId, ld.contractType == StructLib.ContractType.CASHFLOW_BASE ? stId >> 192 : a.tokTypeId, a.ledgerOwner, uint256(uint64(remainingToBurn)));
                    remainingToBurn = 0;
                }
            }
        }
    }

    //
    // GET TOKEN
    //
    function getSecToken(
        StructLib.LedgerStruct storage  ld,
        StructLib.StTypesStruct storage std,
        uint256                         stId
    )
    public view returns (
        StructLib.LedgerSecTokenReturn memory
    ) {
        if (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER) { // controller: delegate to base
            uint256 tokTypeId = stId >> 192;
            StMaster base = StMaster(std._tt_addr[tokTypeId]);
            StructLib.LedgerSecTokenReturn memory ret = base.getSecToken(stId);

            // remap base return field: tokTypeId & tokTypeName
            //  (from base unitype to controller type)
            ret.tokTypeId = tokTypeId;
            ret.tokTypeName = std._tt_name[tokTypeId];

            // remap base return field: batchId
            // (from base unibatch id (1) to controller batch id;
            //  ASSUMES: only one batch per type in the controller (uni-batch/uni-mint model))
            for (uint64 batchId = 1; batchId <= ld._batches_currentMax_id; batchId++) {
                if (ld._batches[batchId].tokTypeId == tokTypeId) {
                    ret.batchId = batchId;
                    break;
                }
            }

            return ret;
        }
        else {
            return StructLib.LedgerSecTokenReturn({
                    exists: ld._sts[stId].mintedQty != 0,
                      stId: stId,
                 tokTypeId: ld._batches[ld._sts[stId].batchId].tokTypeId,
               tokTypeName: std._tt_name[ld._batches[ld._sts[stId].batchId].tokTypeId],
                   batchId: ld._sts[stId].batchId,
                 mintedQty: ld._sts[stId].mintedQty,
                currentQty: ld._sts[stId].currentQty,
                  ft_price: ld._sts[stId].ft_price,
            ft_ledgerOwner: ld._sts[stId].ft_ledgerOwner,
          ft_lastMarkPrice: ld._sts[stId].ft_lastMarkPrice,
                     ft_PL: ld._sts[stId].ft_PL
            });
        }
    }

    // POST-MINTING: add KVP metadata
    // TODO: must pass-through to base?!
    function addMetaSecTokenBatch(
        StructLib.LedgerStruct storage ld,
        uint256                        batchId,
        string memory                  metaKeyNew,
        string memory                  metaValueNew
    )
    public {
        require(ld._contractSealed, "Contract is not sealed");
        require(batchId >= 1 && batchId <= ld._batches_currentMax_id, "Bad batchId");

        for (uint256 kvpNdx = 0; kvpNdx < ld._batches[batchId].metaKeys.length; kvpNdx++) {
            require(keccak256(abi.encodePacked(ld._batches[batchId].metaKeys[kvpNdx])) != keccak256(abi.encodePacked(metaKeyNew)), "Duplicate key");
        }

        ld._batches[batchId].metaKeys.push(metaKeyNew);
        ld._batches[batchId].metaValues.push(metaValueNew);
        emit AddedBatchMetadata(batchId, metaKeyNew, metaValueNew);
    }

    // POST-MINTING: set batch TOKEN fee
    // TODO: must pass-through to base?!
    function setOriginatorFeeTokenBatch(
        StructLib.LedgerStruct storage ld,
        uint256 batchId,
        StructLib.SetFeeArgs memory originatorFeeNew)
    public {
        require(ld._contractSealed, "Contract is not sealed");
        require(batchId >= 1 && batchId <= ld._batches_currentMax_id, "Bad batchId");

        // can only lower fee after minting
        require(ld._batches[batchId].origTokFee.fee_fixed >= originatorFeeNew.fee_fixed, "Bad fee args");
        require(ld._batches[batchId].origTokFee.fee_percBips >= originatorFeeNew.fee_percBips, "Bad fee args");
        require(ld._batches[batchId].origTokFee.fee_min >= originatorFeeNew.fee_min, "Bad fee args");
        require(ld._batches[batchId].origTokFee.fee_max >= originatorFeeNew.fee_max, "Bad fee args");

        require(originatorFeeNew.fee_max >= originatorFeeNew.fee_min || originatorFeeNew.fee_max == 0, "Bad fee args");
        require(originatorFeeNew.fee_percBips <= 10000, "Bad fee args");
        require(originatorFeeNew.ccy_mirrorFee == false, "ccy_mirrorFee unsupported for token-type fee");

        ld._batches[batchId].origTokFee = originatorFeeNew;
        emit SetBatchOriginatorFee_Token(batchId, originatorFeeNew);
    }

    // POST-MINTING: set batch CURRENCY fee
    // TODO: must pass-through to base?!
    function setOriginatorFeeCurrencyBatch(
        StructLib.LedgerStruct storage ld,
        uint64                         batchId,
        uint16                         origCcyFee_percBips_ExFee
    )
    public {
        require(ld._contractSealed, "Contract is not sealed");
        require(batchId >= 1 && batchId <= ld._batches_currentMax_id, "Bad batchId");
        require(origCcyFee_percBips_ExFee <= 10000, "Bad fee args");

        // can only lower fee after minting
        require(ld._batches[batchId].origCcyFee_percBips_ExFee >= origCcyFee_percBips_ExFee, "Bad fee args");

        ld._batches[batchId].origCcyFee_percBips_ExFee = origCcyFee_percBips_ExFee;
        emit SetBatchOriginatorFee_Currency(batchId, origCcyFee_percBips_ExFee);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./StErc20.sol";
import "./StPayable.sol";

import "../Interfaces/StructLib.sol";
import "../Libs/TransferLib.sol";
import "../Libs/Erc20Lib.sol";
import "../Libs/LedgerLib.sol";

abstract // solc 0.6

 /**
  * @title Transferable Security Tokens
  * @author Dominic Morris (7-of-9)
  * @notice transfer or trade of security tokens
  * <pre>   - inherits Owned ownership smart contract</pre>
  * <pre>   - inherits StLedger security token ledger contract</pre>
  * <pre>   - inherits StFees fees contract</pre>
  * <pre>   - inherits StErc20 erc20 token contract</pre>
  * <pre>   - inherits StPayable payable token contract</pre>
  * <pre>   - uses StructLib interface library</pre>
  * <pre>   - uses LedgerLib runtime library</pre>
  * <pre>   - uses TransferLib runtime library</pre>
  * <pre>   - uses Erc20Lib runtime library</pre>
  */
  
contract StTransferable is Owned,
    StErc20, StPayable {

    /**
     * @dev returns the hashcode of the ledger
     * @param mod modulus operand for modulus operation on ledger index
     * @param n base integer modulus operation validation
     * @return ledgerHashcode
     * @param ledgerHashcode returns the hashcode of the ledger
     */
     
    function getLedgerHashcode(uint mod, uint n) external view returns (bytes32 ledgerHashcode) {
        return LedgerLib.getLedgerHashcode(ld, std, ctd, erc20d, /*cashflowData,*/ globalFees, mod, n);
    }

    /**
     * @dev transfer or trade operation on security tokens
     * @param transferArgs transfer or trade arguments<br/>
     * ledger_A<br/>
     * ledger_B<br/>
     * qty_A : ST quantity moving from A (excluding fees, if any)<br/>
     * k_stIds_A : if len>0: the constant/specified ST IDs to transfer (must correlate with qty_A, if supplied)<br/>
     * tokTypeId_A : ST type moving from A<br/>
     * qty_B : ST quantity moving from B (excluding fees, if any)<br/>
     * k_stIds_B : if len>0: the constant/specified ST IDs to transfer (must correlate with qty_B, if supplied)<br/>
     * tokTypeId_B : ST type moving from B<br/>
     * ccy_amount_A : currency amount moving from A (excluding fees, if any)<br/>
     * ccyTypeId_A : currency type moving from A<br/>
     * ccy_amount_B : currency amount moving from B (excluding fees, if any)<br/>
     * ccyTypeId_B : currency type moving from B<br/>
     * applyFees : apply global fee structure to the transfer (both legs)<br/>
     * feeAddrOwner : account address of fee owner
     */
     
    function transferOrTrade(StructLib.TransferArgs memory transferArgs)
    public onlyCustodian() onlyWhenReadWrite() {
        // abort if sending tokens from a non-whitelist account
        require(!(transferArgs.qty_A > 0 && !erc20d._whitelisted[transferArgs.ledger_A]), "Not whitelisted (A)"); 
        require(!(transferArgs.qty_B > 0 && !erc20d._whitelisted[transferArgs.ledger_B]), "Not whitelisted (B)");

        transferArgs.feeAddrOwner = deploymentOwner;
        TransferLib.transferOrTrade(ld, std, ctd, globalFees, transferArgs);
    }

    // FAST - fee preview exchange fee only
    /**
     * @dev returns fee preview - exchange fee only
     * @param transferArgs transfer args same as transferOrTrade
     * @return feesAll
     * @param feesAll returns fees calculation for the exchange
     */
    function transfer_feePreview_ExchangeOnly(StructLib.TransferArgs calldata transferArgs)
    external view returns (StructLib.FeesCalc[1] memory feesAll) {
        return TransferLib.transfer_feePreview_ExchangeOnly(ld, globalFees, deploymentOwner, transferArgs);
    }

    // SLOW - fee preview, with batch originator token fees (full, slow) - old/deprecate
    // 24k -- REMOVE NEXT...
    uint256 constant MAX_BATCHES_PREVIEW = 128; // library constants not accessible in contract; must duplicate TransferLib value
    
    /**
     * @dev returns all fee preview (old / deprecated)
     * @param transferArgs transfer args same as transferOrTrade
     * @return feesAll
     * @param feesAll returns fees calculation for the exchange
     */
    function transfer_feePreview(StructLib.TransferArgs calldata transferArgs)
    external view returns (StructLib.FeesCalc[1 + MAX_BATCHES_PREVIEW * 2] memory feesAll) {
        return TransferLib.transfer_feePreview(ld, std, globalFees, deploymentOwner, transferArgs);
    }

    // 24k
    // function getCcy_totalTransfered(uint256 ccyTypeId)
    // external view returns (uint256) {
    //     return ld._ccyType_totalTransfered[ccyTypeId];
    // }
    // function getSecToken_totalTransferedQty()
    // external view returns (uint256) {
    //     return ld._spot_total.transferedQty;
    // }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./StFees.sol";
import "./StErc20.sol";

import "../Libs/LedgerLib.sol";
import "../Interfaces/StructLib.sol";
import "../Interfaces/ReentrancyGuard.sol";
import "../Libs/PayableLib.sol";

abstract // solc 0.6

 /**
  * @title Payable Security Tokens
  * @author Ankur Daharwal (ankurdaharwal) and Dominic Morris (7-of-9)
  * @notice all security token payable operations including token purchasing and issuer payments
  * <pre>   - inherits StFees fee contract</pre>
  * <pre>   - inherits StErc20 token contract</pre>
  * <pre>   - uses StructLib interface library</pre>
  * <pre>   - uses LedgerLib runtime library</pre>
  * <pre>   - uses PayableLib runtime library</pre>
  */

contract StPayable is
    StErc20, ReentrancyGuard {
        
    // === CFT - Cashflow Types === V1/MVP DONE ** =>>> CFT SPLIT LEDGER (decentralized token balances w/ central WL, collateral balances, and centralized spot transferOrTrade entry point...)
    //
    //  Cashflow type is fundamentally way less fungible than Commodity type, i.e. loanA != loanB, equityA != equityB, etc.
    //  Only way to preserve ERC20 semanitcs for CFTs, is for each CFT to have its own contract address;
    //    (i.e. we can't use token-types (or batch metadata) to separate different CFTs in a single contract ledger)
    //
    //          (1) CASHFLOW_CONTROLLER: new contract type
    //                  (a) its n tokTypes wrap n CASHFLOW-type contracts
    //                  (b) so addSecTokType() for CFT-C needs to take the address of a deployed CFT contract...
    //
    //          (2) CASHFLOW_CONTROLLER: is entry point for the split ledger - all clients talk only to it
    //                  > mint: DONE (passthrough to base)
    //                  > getSecToken: DONE (passthrough to bases)
    //                  > getLedgerEntry: DONE (return (a) n ccy's from CFT-C ... UNION ... (b) n tok's from n CFT's)
    //                  > burn: DONE (passthrough to base)
    //                  > DONE: transferOrTrade: update 1 ccy in CFT-C ... update 1 tok in CFT
    //                  > DONE: transfer_feePreview[_ExchangeOnly] ... >> combine/merge base output (orig tok fees w/ ccy fees...)
    //                  > DONE: ledgerhashcode (delegations to base)
    //
    //          (3) CASHFLOW_CONTROLLER === (interface compatible) with COMMODITY (base) EXCEPT:
    //                  > can only add indirect (CASHFLOW_BASE) types
    //                  > only 1 mint action per sec-type (i.e. mint is passed through to the unitoken model on CASHFLOW_BASE)
    //                  > no ERC20 support (not fungible, meaningless) -- ERC20 works only on CASHFLOW_BASE
    //
    // === CFT ====>>> V2...
    //  >>> TODO: PoC data load/compare JS tests for CFT-C and CFT-B...
    //      TODO: pri2 - PI: softcap/escrow/timelimits, etc...
    //      TODO: pri2 - PI: issuance fee on subscriptions..
    //      done/v1: pri1 - issuerPayments (EQ)   v0.1 -- MVP (any amount ok, no validations) -- test pack: changing issuancePrice mid-issuance
    //      done/v1: pri1 - issuerPayments (BOND) v0.1 -- MVP basic (no validations, i.e. eq-path only / simple term-structure table -- revisit loan/interest etc. later)

//#if process.env.CONTRACT_TYPE === 'CASHFLOW_BASE'
    StructLib.CashflowStruct cashflowData;
//#
    /**
     * @dev returns cashflow data for a cashflow token (base)
     * @return cashFlowData
     * @param cashFlowData returns cashflow data for a cashflow token (base)
     */
    function getCashflowData() public view returns(StructLib.CashflowStruct memory cashFlowData) {
        return PayableLib.getCashflowData(ld, cashflowData);
    }

    StructLib.IssuerPaymentBatchStruct ipbd; // current issuer payment batch

    /**
     * @dev returns current issuer payment batch for cashflow token (base)
     * @return issuerPaymentBatch
     * @param issuerPaymentBatch returns current issuer payment batch for cashflow token (base)
     */
    function getIssuerPaymentBatch() public view returns(StructLib.IssuerPaymentBatchStruct memory issuerPaymentBatch) {
        return PayableLib.getIssuerPaymentBatch(ipbd);
    }
    
    //address public chainlinkAggregator_btcUsd;
    address public chainlinkAggregator_ethUsd;
    address public chainlinkAggregator_bnbUsd;

    // function get_btcUsd() public view returns(int256) {
    //     if (chainlinkAggregator_btcUsd == address(0x0)) return -1;
    //     IChainlinkAggregator ref = IChainlinkAggregator(chainlinkAggregator_btcUsd);
    //     return ref.latestAnswer();
    // }

    /**
     * @dev returns chainlink ETH price in USD
     * @return ethPriceInUSD
     * @param ethPriceInUSD returns chainlink ETH price in USD
     */
    function get_ethUsd() public view returns(int256 ethPriceInUSD) {
        if (chainlinkAggregator_ethUsd == address(0x0)) return -1;
        return PayableLib.get_chainlinkRefPrice(chainlinkAggregator_ethUsd);
    }

    /**
     * @dev returns chainlink BNB price in USD
     * @return bnbPriceInUSD
     * @param bnbPriceInUSD returns chainlink BNB price in USD
     */
    function get_bnbUsd() public view returns(int256 bnbPriceInUSD) {
        if (chainlinkAggregator_bnbUsd == address(0x0)) return -1;
        return PayableLib.get_chainlinkRefPrice(chainlinkAggregator_bnbUsd);
    }

    //function() external  payable  onlyWhenReadWrite() {
    
    /**
     * @dev token subscriptions in USD, ETH or BNB for cashflow token (base)
     */
    receive() external payable nonReentrant() onlyWhenReadWrite() {
        PayableLib.pay(ld, std, ctd, cashflowData, globalFees, deploymentOwner, get_ethUsd(), get_bnbUsd());
    }
    
    //function() external  payable  onlyWhenReadWrite() {
    /**
     * @dev issuer payments in ETH or BNB for cashflow token (base)
     * @param count next token holders from ledger to be paid in the payment batch
     */
    function receiveIssuerPaymentBatch(uint32 count) external payable nonReentrant() onlyWhenReadWrite() {
        PayableLib.issuerPay(count, ipbd, ld, cashflowData);
    }

    /**
     * @dev set issuance values (only issuer)
     * @param wei_currentPrice set token price in wei
     * @param cents_currentPrice set token price in cents
     * @param qty_saleAllocation set max token sale allocation amount
     */
    function setIssuerValues(
        // address issuer,
        // StructLib.SetFeeArgs memory originatorFee,
        uint256 wei_currentPrice,
        uint256 cents_currentPrice,
        uint256 qty_saleAllocation
    ) external onlyWhenReadWrite() {
        PayableLib.setIssuerValues(
            ld,
            cashflowData,
            wei_currentPrice,
            cents_currentPrice,
            qty_saleAllocation,
            deploymentOwner
        );
    }
//#endif
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./StLedger.sol";

import "../Interfaces/StructLib.sol";
import "../Libs/LedgerLib.sol";
import "../Libs/SpotFeeLib.sol";

 /**
  * @title Mintable Security Tokens
  * @author Dominic Morris (7-of-9)
  * @notice retirement of security tokens
  * <pre>   - inherits Owned ownership smart contract</pre>
  * <pre>   - inherits StLedger security token ledger contract</pre>
  * <pre>   - uses StructLib interface library</pre>
  * <pre>   - uses LedgerLib runtime library</pre>
  * <pre>   - uses SpotFeeLib runtime library</pre>
  */

abstract contract StMintable is
    StLedger {

    /**
     * @dev mint a fresh security token batch
     * @param tokTypeId token type
     * @param mintQty unit quantity of tokens to be minted
     * @param mintSecTokenCount set as 1
     * @param batchOwner account address of the issuer or batch originator
     * @param originatorFee batch originator token fee setting on all transfers of tokens from this batch
     * @param origCcyFee_percBips_ExFee batch originator currency fee setting on all transfers of tokens from this batch - % of exchange currency 
     * @param metaKeys meta-data keys that attribute to partial fungibility of the tokens
     * @param metaValues meta-data values that attribute to partial fungibility of the tokens
     */
     
    function mintSecTokenBatch(
        uint256                     tokTypeId,
        uint256                     mintQty,
        int64                       mintSecTokenCount,
        address payable             batchOwner,
        StructLib.SetFeeArgs memory originatorFee,
        uint16                      origCcyFee_percBips_ExFee,
        string[] memory             metaKeys,
        string[] memory             metaValues
    )
    public onlyOwner() onlyWhenReadWrite() {
        TokenLib.MintSecTokenBatchArgs memory args = TokenLib.MintSecTokenBatchArgs({
                tokTypeId: tokTypeId,
                  mintQty: mintQty,
        mintSecTokenCount: mintSecTokenCount,
               batchOwner: batchOwner,
               origTokFee: originatorFee,
origCcyFee_percBips_ExFee: origCcyFee_percBips_ExFee,
                 metaKeys: metaKeys,
               metaValues: metaValues
        });
        TokenLib.mintSecTokenBatch(ld, std, args);
    }

    /**
     * @dev add additional meta data to a security token batch
     * @param batchId unique identifier of the security token batch
     * @param metaKeyNew new meta-data key
     * @param metaValueNew new meta-data value
     */
    function addMetaSecTokenBatch(
        uint64 batchId,
        string calldata metaKeyNew,
        string calldata metaValueNew)
    external onlyOwner() onlyWhenReadWrite() {
        TokenLib.addMetaSecTokenBatch(ld, batchId, metaKeyNew, metaValueNew);
    }

    /**
     * @dev add additional meta data to a security token batch
     * @param batchId unique identifier of the security token batch
     * @param originatorFee set new originator fee value
     */
    function setOriginatorFeeTokenBatch(
        uint64 batchId,
        StructLib.SetFeeArgs calldata originatorFee)
    external onlyOwner() onlyWhenReadWrite() {
        TokenLib.setOriginatorFeeTokenBatch(ld, batchId, originatorFee);
    }
    
    /**a
     * @dev add additional meta data to a security token batch
     * @param batchId unique identifier of the security token batch
     * @param origCcyFee_percBips_ExFee set new originator fee % (bips)
     */
    function setOriginatorFeeCurrencyBatch(
        uint64 batchId,
        uint16 origCcyFee_percBips_ExFee)
    external onlyOwner() onlyWhenReadWrite() {
        TokenLib.setOriginatorFeeCurrencyBatch(ld, batchId, origCcyFee_percBips_ExFee);
    }

    // 24k
    /**
     * @dev returns the security token total minted quantity
     * @return totalMintedQty
     * @param totalMintedQty returns the security token total burned quantity
     */
    function getSecToken_totalMintedQty()
    external view returns (uint256 totalMintedQty) { return ld._spot_totalMintedQty; }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./CcyCollateralizable.sol";
import "./StMintable.sol";
import "./StBurnable.sol";
import "./StTransferable.sol";
import "./StErc20.sol";
import "./StPayable.sol";
import "./DataLoadable.sol";
import "../Interfaces/StructLib.sol";

/** 
 *  node process_sol_js && truffle compile && grep \"bytecode\" build/contracts/* | awk '{print $1 " " length($3)/2}'
 *  22123: ... [upgrade sol 0.6.6: removed ctor setup, removed WL deprecated, removed payable unused]
 *  23576: ... FTs v0 (paused) - baseline
 *  22830: ... [removed all global counters, except total minted & burned]
 *  22911: ... [removed isWL and getWLCount]
 *  24003: ... [restored cashflowArgs; optimizer runs down to 10]
 *  24380: ... [added stIds[] to burn & transferArgs; optimizer runs down to 1]
 *  24560: ... [split ledger - wip; at limit]
 *  24241: ... [refactor/remove SecTokenReturn in favour of LedgerSecTokenReturn]
 *  24478: ... [+ _tokens_base_id, getSecToken_BaseId()]
 *  23275: ... [+ _owners[], getOwners] 
 */

 /**
  * @title Security Token Master
  * @author Dominic Morris (7-of-9) and Ankur Daharwal (ankurdaharwal)
  * @notice STMaster is configured at the deployment time to one of:<br/>
  * <pre>   - commodity token (CT): a semi-fungible (multi-batch), multi-type & single-version commodity underlying; or</pre>
  * <pre>   - cashflow token (CFT): a fully-fungible, multi-type & multi-version (recursive/linked contract deployments) cashflow-generating underlyings.</pre>
  * <pre>   - cashflow controller (CFC): singleton cashflow token governance contract; keeps track of global ledger and states across n CFTs</pre>
  * It is an EVM-compatible set of smart contracts written in Solidity, comprising:<br/><br/>
  * <pre>   (a) asset-backed, multi token/collateral-type atomic spot cash collateral trading & on-chain settlement;</pre>
  * <pre>   (b) scalable, semi-fungible & metadata-backed extendible type-system;</pre>
  * <pre>   (c) upgradable contracts: cryptographic checksumming of v+0 and v+1 contract data fields;</pre>
  * <pre>   (d) full ERC20 implementation (inc. transferFrom, allowance, approve) for self-custody;</pre>
  * <pre>   (e) multiple reserved contract owner/operator addresses, for concurrent parallel/batched operations via independent account-nonce sequencing;</pre>
  * <pre>   (f) split ledger: hybrid permission semantics - owner-controller ("whitelisted") addresses for centralised spot trade execution,<br/>
  *       alongside third-party controlled ("graylisted") addresses for self-custody;</pre>
  * <pre>   (g) generic metadata batch minting via extendible (append-only, immutable) KVP collection;</pre>
  * <pre>   (h) hybrid on/off chain futures settlement engine (take & pay period processing, via central clearing account),<br/>
  *       with on-chain position management & position-level P&L;</pre>
  * <pre>   (i) decentralized issuance of cashflow tokens & corporate actions: subscriber cashflow (e.g. ETH/BNB) <br/>
  *       processing of (USD-priced or ETH/BNB-priced) token issuances, and (inversely) issuer cashflow processing of CFT-equity or CFT-loan payments.</pre>
  * @dev All function calls are currently implemented without side effects
  */

contract StMaster
    is
    StMintable, StBurnable, Collateralizable, StTransferable, DataLoadable //, StFutures (excluded/paused for v1) - 24k limit
{
    // === STM (AC COMMODITY) ===
    // TODO: type-rename...
    // todo: drop fee_fixed completely (it's == fee_min)
    // todo: etherscan -> verify contract interfaces? -- needs ctor bytecode
    // todo: change internalTransfer so it can operate on *any* stTypeId

    // contract properties
    string public name;
    string public version;
    string public unit; // the smallest (integer, non-divisible) security token unit, e.g. "KGs" or "TONS"

    /**
     * @dev returns the contract type
     * @return contractType
     * @param contractType returns the contract type<br/>0: commodity token<br/>1: cashflow token<br/>2: cashflow controller
     */
    function getContractType() external view returns(StructLib.ContractType contractType) { return ld.contractType; }
    
    /**
     * @dev returns the contract seal status
     * @return isSealed
     * @param isSealed returns the contract seal status : true or false
     */
    function getContractSeal() external view returns (bool isSealed) { return ld._contractSealed; }
    
    /**
     * @dev permanenty seals the contract; once sealed, no further addresses can be whitelisted
     */
    function sealContract() external { ld._contractSealed = true; }

    // events -- (hack: see: https://ethereum.stackexchange.com/questions/11137/watching-events-defined-in-libraries)
    // need to be defined (duplicated) here - web3 can't see event signatures in libraries
    // CcyLib events
    event AddedCcyType(uint256 id, string name, string unit);
    event CcyFundedLedger(uint256 ccyTypeId, address indexed to, int256 amount, string desc);
    event CcyWithdrewLedger(uint256 ccyTypeId, address indexed from, int256 amount, string desc);
    // TokenLib events
    event AddedSecTokenType(uint256 id, string name, StructLib.SettlementType settlementType, uint64 expiryTimestamp, uint256 underlyerTypeId, uint256 refCcyId, uint16 initMarginBips, uint16 varMarginBips);
    event SetFutureVariationMargin(uint256 tokTypeId, uint16 varMarginBips);
    event SetFutureFeePerContract(uint256 tokTypeId, uint256 feePerContract);
    event Burned(uint256 tokTypeId, address indexed from, uint256 burnedQty);
    event BurnedFullSecToken(uint256 indexed stId, uint256 tokTypeId, address indexed from, uint256 burnedQty);
    event BurnedPartialSecToken(uint256 indexed stId, uint256 tokTypeId, address indexed from, uint256 burnedQty);
    event Minted(uint256 indexed batchId, uint256 tokTypeId, address indexed to, uint256 mintQty, uint256 mintSecTokenCount);
    event MintedSecToken(uint256 indexed stId, uint256 indexed batchId, uint256 tokTypeId, address indexed to, uint256 mintedQty);
    event AddedBatchMetadata(uint256 indexed batchId, string key, string value);
    event SetBatchOriginatorFee_Token(uint256 indexed batchId, StructLib.SetFeeArgs originatorFee);
    event SetBatchOriginatorFee_Currency(uint256 indexed batchId, uint16 origCcyFee_percBips_ExFee);
    // TransferLib events
    event TransferedFullSecToken(address indexed from, address indexed to, uint256 indexed stId, uint256 mergedToSecTokenId, uint256 qty, TransferType transferType);
    event TransferedPartialSecToken(address indexed from, address indexed to, uint256 indexed splitFromSecTokenId, uint256 newSecTokenId, uint256 mergedToSecTokenId, uint256 qty, TransferType transferType);
    event TradedCcyTok(uint256 ccyTypeId, uint256 ccyAmount, uint256 tokTypeId, address indexed /*tokens*/from, address indexed /*tokens*/to, uint256 tokQty, uint256 ccyFeeFrom, uint256 ccyFeeTo);
    // StructLib events
    enum TransferType { Undefined, User, ExchangeFee, OriginatorFee, TakePayFee, SettleTake, SettlePay, MintFee, BurnFee, WithdrawFee, DepositFee, DataFee, OtherFee1, OtherFee2,OtherFee3, OtherFee4, OtherFee5, RelatedTransfer, Adjustment, ERC20, Subscription }
    event TransferedLedgerCcy(address indexed from, address indexed to, uint256 ccyTypeId, uint256 amount, TransferType transferType);
    event ReservedLedgerCcy(address indexed ledgerOwner, uint256 ccyTypeId, uint256 amount);
    // SpotFeeLib events
    event SetFeeTokFix(uint256 tokTypeId, address indexed ledgerOwner, uint256 fee_tokenQty_Fixed);
    event SetFeeCcyFix(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_Fixed);
    event SetFeeTokBps(uint256 tokTypeId, address indexed ledgerOwner, uint256 fee_token_PercBips);
    event SetFeeCcyBps(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_PercBips);
    event SetFeeTokMin(uint256 tokTypeId, address indexed ledgerOwner, uint256 fee_token_Min);
    event SetFeeCcyMin(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_Min);
    event SetFeeTokMax(uint256 tokTypeId, address indexed ledgerOwner, uint256 fee_token_Max);
    event SetFeeCcyMax(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_Max);
    event SetFeeCcyPerMillion(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_perMillion);
    // Erc20Lib 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // PayableLib events
    event IssuanceSubscribed(address indexed subscriber, address indexed issuer, uint256 weiSent, uint256 weiChange, uint256 tokensSubscribed, uint256 weiPrice);
    // Issuer Payment events
    event IssuerPaymentProcessed(uint32 indexed paymentId, address indexed issuer, uint256 totalAmount, uint32 totalBatchCount);
    event IssuerPaymentBatchProcessed(uint32 indexed paymentId, uint32 indexed paymentBatchId, address indexed issuer, uint256 weiSent, uint256 weiChange);
    event SubscriberPaid(uint32 indexed paymentId, uint32 indexed paymentBatchId, address indexed issuer, address subscriber, uint256 amount);
    // FuturesLib events
    event FutureOpenInterest(address indexed long, address indexed short, uint256 shortStId, uint256 tokTypeId, uint256 qty, uint256 price, uint256 feeLong, uint256 feeShort);
    event SetInitialMarginOverride(uint256 tokTypeId, address indexed ledgerOwner, uint16 initMarginBips);
    //event TakePay(address indexed from, address indexed to, uint256 delta, uint256 done, address indexed feeTo, uint256 otmFee, uint256 itmFee, uint256 feeCcyId);
    event TakePay2(address indexed from, address indexed to, uint256 ccyId, uint256 delta, uint256 done, uint256 fee);
    event Combine(address indexed to, uint256 masterStId, uint256 countTokensCombined);

    // DBG
    // event dbg1(uint256 id, uint256 typeId);
    // event dbg2(uint256 postIdShifted);
    
    /**
    * @dev deploys the STMaster contract as a commodity token (CT) or cashflow token (CFT)
    * @param _owners array of addresses to identify the deployment owners
    * @param _contractType 0: commodity token<br/>1: cashflow token<br/>2: cashflow controller
    * @param _custodyType 0: self custody<br/>1: 3rd party custody
    * @param _contractName smart contract name
    * @param _contractVer smart contract version
    * @param _contractUnit measuring unit for commodity types (ex: KG, tons or N/A)
    */
    constructor(
        address[] memory              _owners,
        StructLib.ContractType        _contractType,
        Owned.CustodyType             _custodyType,
//#if process.env.CONTRACT_TYPE === 'CASHFLOW_BASE'
        StructLib.CashflowArgs memory _cashflowArgs,
//#endif
        string memory                 _contractName,
        string memory                 _contractVer,
        string memory                 _contractUnit
//#if process.env.CONTRACT_TYPE === 'CASHFLOW_BASE' || process.env.CONTRACT_TYPE === 'COMMODITY'
        ,
        string memory                 _contractSymbol,
        uint8                         _contractDecimals
//#endif
//#if process.env.CONTRACT_TYPE === 'CASHFLOW_BASE'
    ,
  //address                       _chainlinkAggregator_btcUsd,
    address                       _chainlinkAggregator_ethUsd,
    address                       _chainlinkAggregator_bnbUsd
//#endif
    ) 
//#if process.env.CONTRACT_TYPE === 'CASHFLOW_BASE' || process.env.CONTRACT_TYPE === 'COMMODITY'
        StErc20(_contractSymbol, _contractDecimals)
//#endif
        Owned(_owners, _custodyType)
    {

//#if process.env.CONTRACT_TYPE === 'CASHFLOW_BASE'
        cashflowData.args = _cashflowArgs;
        //chainlinkAggregator_btcUsd = _chainlinkAggregator_btcUsd;
        chainlinkAggregator_ethUsd = _chainlinkAggregator_ethUsd;
        chainlinkAggregator_bnbUsd = _chainlinkAggregator_bnbUsd;
//#endif

        // set common properties
        name = _contractName;
        version = _contractVer;
        unit = _contractUnit;

        // contract type
        ld.contractType = _contractType;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./Owned.sol";

import "../Interfaces/StructLib.sol";
import "../Libs/LedgerLib.sol";
import "../Libs/TokenLib.sol";

 /**
  * @title Security Token Ledger
  * @author Dominic Morris (7-of-9) and Ankur Daharwal (ankurdaharwal)
  * @notice casflow controller and commodity: maintains the global ledger for all security tokens<br/>
  * cashflow token: maintains the ledger for the security tokens in the CFT base
  * <pre>   - inherits Owned ownership smart contract</pre>
  * <pre>   - uses StructLib interface library</pre>
  * <pre>   - uses TokenLib runtime library</pre>
  * <pre>   - uses LedgerLib runtime library</pre>
  */
  
abstract contract StLedger is
    Owned {

    StructLib.LedgerStruct ld;
    StructLib.StTypesStruct std;
    StructLib.CcyTypesStruct ctd;

    //
    // MUTATE LEDGER
    //

    // add token type: direct (by name) or cashflow base (by address)
    /**
     * @dev add a new security token type
     * @param name security token name
     * @param settlementType 0: undefined<br/>1: spot<br/>2: future
     * @param ft future token
     * @param cashflowBaseAddr account address of the cashflow base token (CFT)
     */
    function addSecTokenType(string memory name, StructLib.SettlementType settlementType, StructLib.FutureTokenTypeArgs memory ft, address payable cashflowBaseAddr)
        public onlyOwner() onlyWhenReadWrite() { TokenLib.addSecTokenType(ld, std, ctd, name, settlementType, ft, cashflowBaseAddr); }

    //
    // VIEW LEDGER
    //
    /**
     * @dev returns all security token types
     * @return secTokenTypes
     * @param secTokenTypes returns all security token types
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getSecTokenTypes() external view returns (StructLib.GetSecTokenTypesReturn memory secTokenTypes) { secTokenTypes = TokenLib.getSecTokenTypes(std); }

    /**
     * @dev returns all ledger owners
     * @return ledgerOwners
     * @param ledgerOwners returns all ledger owners
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getLedgerOwners() external view returns (address[] memory ledgerOwners) { ledgerOwners = ld._ledgerOwners; }

    // 24k??
    /**
     * @dev returns the total count of all ledger owners
     * @return ledgerOwnerCount
     * @param ledgerOwnerCount returns the total count of all ledger owners
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getLedgerOwnerCount() external view returns (uint256 ledgerOwnerCount) { ledgerOwnerCount = ld._ledgerOwners.length; }

    /**
     * @dev returns the ledger owner based on HD wallet derived index
     * @param index HD wallet derived index 
     * @return ledgerOwner
     * @param ledgerOwner returns the ledger owner based on HD wallet derived index 
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getLedgerOwner(uint256 index) external view returns (address ledgerOwner) { ledgerOwner = ld._ledgerOwners[index]; }
    
    /**
     * @dev returns the ledger entry for the account provided
     * @param account account address of the ledger owner whose holding needs to be queried from the ledger
     * @return ledgerEntry
     * @param ledgerEntry returns the ledger entry for the account provided
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getLedgerEntry(address account) external view returns (StructLib.LedgerReturn memory ledgerEntry) { ledgerEntry = LedgerLib.getLedgerEntry(ld, std, ctd, account); }

    // get batch(es)
    /**
     * @dev helps keep track of the maximum security token batch ID
     * @return secTokenBatch_MaxId
     * @param secTokenBatch_MaxId returns the maximum identifier of 1-based security token batches IDs
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getSecTokenBatch_MaxId() external view returns (uint256 secTokenBatch_MaxId) { secTokenBatch_MaxId = ld._batches_currentMax_id; } // 1-based
    
    /**
     * @dev returns a security token batch
     * @param batchId security token batch unique identifier
     * @return secTokenBatch
     * @param secTokenBatch returns a security token batch
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getSecTokenBatch(uint256 batchId) external view returns (StructLib.SecTokenBatch memory secTokenBatch) {
        secTokenBatch = ld._batches[batchId];
    }

    // get token(s)
    /**
     * @dev returns the security token base id
     * @return secTokenBaseId
     * @param secTokenBaseId returns the security token base id
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getSecToken_BaseId() external view returns (uint256 secTokenBaseId) { secTokenBaseId = ld._tokens_base_id; } // 1-based
    
    /**
     * @dev returns the maximum count for security token types
     * @return secTokenMaxId
     * @param secTokenMaxId returns the maximum count for security token types
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getSecToken_MaxId() external view returns (uint256 secTokenMaxId) { secTokenMaxId = ld._tokens_currentMax_id; } // 1-based
    
    /**
     * @dev returns a security token
     * @param id unique security token identifier
     * @return secToken
     * @param secToken returns a security token for the identifier provided
     */
    // Certik: SLS-02 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getSecToken(uint256 id) external view returns (StructLib.LedgerSecTokenReturn memory secToken) { secToken = TokenLib.getSecToken(ld, std, id); }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./StLedger.sol";

import "../Interfaces/StructLib.sol";
import "../Libs/SpotFeeLib.sol";

//
// NOTE: fees are applied ON TOP OF the supplied transfer amounts to the transfer() fn.
//       i.e. transfer amounts are not inclusive of fees, they are additional
//

 /**
  * @title Security Token Fee Management
  * @author Dominic Morris (7-of-9)
  * @notice contract for on-chain fee management
  * <pre>   - inherits Owned ownership smart contract</pre>
  * <pre>   - inherits StLedger security token ledger contract</pre>
  * <pre>   - uses StructLib interface library</pre>
  * <pre>   - uses SpotFeeLib runtime library</pre>
  */
  
abstract contract StFees is
    StLedger {

    enum GetFeeType { CCY, TOK }

    // GLOBAL FEES
    StructLib.FeeStruct globalFees;

    /**
     * @dev returns fee structure
     * @param feeType 0: currency fee<br/>1: token fee
     * @param typeId fee type unique identifier
     * @param ledgerOwner account address of the ledger owner
     * @return fee
     * @param fee returns the fees structure based on fee type selection args
     */
    function getFee(GetFeeType feeType, uint256 typeId, address ledgerOwner)
    external view onlyOwner() returns(StructLib.SetFeeArgs memory fee) {
        StructLib.FeeStruct storage fs = ledgerOwner == address(0x0) ? globalFees : ld._ledger[ledgerOwner].spot_customFees;
        mapping(uint256 => StructLib.SetFeeArgs) storage fa = feeType == GetFeeType.CCY ? fs.ccy : fs.tok;
        return StructLib.SetFeeArgs( {
               fee_fixed: uint256(fa[typeId].fee_fixed),
            fee_percBips: uint256(fa[typeId].fee_percBips),
                 fee_min: uint256(fa[typeId].fee_min),
                 fee_max: uint256(fa[typeId].fee_max),
          ccy_perMillion: uint256(fa[typeId].ccy_perMillion),
           ccy_mirrorFee: fa[typeId].ccy_mirrorFee
        });
    }

    /**
     * @dev set fee for a token type
     * @param tokTypeId token type identifier
     * @param ledgerOwner account address of the ledger owner
     * @param feeArgs fee_fixed: fixed fee on transfer or trade</br>
     * fee_percBips: fixed fee % on transfer or trade</br>
     * fee_min: minimum fee on transfer or trade - collar/br>
     * fee_max: maximum fee on transfer or trade - cap</br>
     * ccy_perMillion: N/A</br>
     * ccy_mirrorFee: N/A
     */
    function setFee_TokType(uint256 tokTypeId, address ledgerOwner, StructLib.SetFeeArgs memory feeArgs)
    public onlyOwner() onlyWhenReadWrite() {
        SpotFeeLib.setFee_TokType(ld, std, globalFees, tokTypeId, ledgerOwner, feeArgs);
    }

//#if process.env.CONTRACT_TYPE !== 'CASHFLOW_BASE'
//#     /**
//#      * @dev set fee for a currency type
//#      * @param ccyTypeId currency type identifier
//#      * @param ledgerOwner account address of the ledger owner
//#      * @param feeArgs fee_fixed: fixed fee on transfer or trade</br>
//#      * fee_percBips: fixed fee % on transfer or trade</br>
//#      * fee_min: minimum fee on transfer or trade - collar/br>
//#      * fee_max: maximum fee on transfer or trade - cap</br>
//#      * ccy_perMillion: trade - fixed ccy fee per million of trade counterparty's consideration token qty</br>
//#      * ccy_mirrorFee: trade - apply this ccy fee structure to counterparty's ccy balance, post trade
//#      */
//#     function setFee_CcyType(uint256 ccyTypeId, address ledgerOwner, StructLib.SetFeeArgs memory feeArgs)
//#     public onlyOwner() onlyWhenReadWrite() {
//#         SpotFeeLib.setFee_CcyType(ld, ctd, globalFees, ccyTypeId, ledgerOwner, feeArgs);
//#     }
//#endif
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./StFees.sol";

import "../Interfaces/StructLib.sol";
import "../Libs/TransferLib.sol";
import "../Libs/LedgerLib.sol";
import "../Libs/Erc20Lib.sol";

/**
  * Manages ERC20 operations & data
  * @title ERC20 Compatibility for Security Token Master
  * @author Dominic Morris (7-of-9) and Ankur Daharwal (ankurdaharwal)
  * @notice a standard ERC20 implementation
  * @dev 
  * <pre>   - inherits Owned ownership smart contract</pre>
  * <pre>   - inherits StLedger security token ledger contract</pre>
  * <pre>   - inherits StFees fee management contract</pre>
  * <pre>   - inherits StructLib interface library</pre>
  * <pre>   - inherits Erc20Lib runtime library</pre>
  * <pre>   - inherits LedgerLib runtime library</pre>
  * <pre>   - inherits TransferLib runtime library</pre>
  */

abstract contract StErc20 is StFees
{
    StructLib.Erc20Struct erc20d;

    // TODO: move WL stuff out of erc20
    // WHITELIST - add entry & retreive full whitelist
    // function whitelist(address addr) public onlyOwner() {
    //     Erc20Lib.whitelist(ld, erc20d, addr);
    // }
    
    /**
     * @dev add multiple whitelist account addresses by deployment owners only
     * @param addr list of account addresses to be whitelisted
     */

    // Certik: SES-02 | Function Visibility Optimization
    // Review: Replaced public with external and memory with calldata for gas optimization
    function whitelistMany(address[] calldata addr) external onlyOwner() {
        for (uint256 i = 0; i < addr.length; i++) {
            Erc20Lib.whitelist(ld, erc20d, addr[i]);
        }
    }
    
    /**
     * @dev return whitelist addresses count
     * @return whitelistAddressCount
     * @param whitelistAddressCount count of whitelisted account addresses
     */
    function getWhitelistCount() external view returns (uint256 whitelistAddressCount) {
        whitelistAddressCount = erc20d._whitelist.length;
    }

    /**
     * @dev return all whitelist addresses
     * @return whitelistAddresses
     * @param whitelistAddresses list of all whitelisted account addresses
     */
    // Certik: SES-03 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function getWhitelist() external view returns (address[] memory whitelistAddresses) {
        whitelistAddresses = erc20d._whitelist;
    }

    /**
     * @dev return all whitelist addresses (extended functionality to overcome gas constraint for a larger whitelist set)
     * @return whitelistAddresses
     * @param whitelistAddresses list of all whitelisted account addresses
     */
    function getWhitelist(uint256 pageNo, uint256 pageSize) external view returns (address[] memory whitelistAddresses) {
        require(pageSize > 0 && pageSize < 2000, 'Bad page size: must be > 0 and < 2000');
        whitelistAddresses = Erc20Lib.getWhitelist(erc20d._whitelist,pageNo,pageSize);
    }
 
//#if process.env.CONTRACT_TYPE === 'CASHFLOW_BASE' || process.env.CONTRACT_TYPE === 'COMMODITY'
    /// @notice symbol standard ERC20 token symbol
    string public symbol;
    /// @notice decimals standard ERC20 token decimal for level of precision of issued tokens
    uint8 public decimals;

    /**
     * @dev standard ERC20 token
     * @param _symbol token symbol
     * @param _decimals level of precision of the tokens
     */
    constructor(string memory _symbol, uint8 _decimals) {
        symbol = _symbol;
        decimals = _decimals;

        // this index is used for allocating whitelist addresses to users (getWhitelistNext()))
        // we skip/reserve the first ten whitelisted address (0 = owner, 1-9 for expansion)
        //erc20d._nextWhitelistNdx = 10;
    }

    // ERC20 - core
    
    /**
     * @dev standard ERC20 token total supply
     * @return availableQty
     * @param availableQty returns total available quantity (minted quantity - burned quantitypublic
     */
    // Certik: SES-03 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function totalSupply() public view returns (uint256 availableQty) {
        availableQty = ld._spot_totalMintedQty - ld._spot_totalBurnedQty;
    }
    
    /**
     * @dev standard ERC20 token balanceOf
     * @param account account address to check the balance of
     * @return balance
     * @param balance returns balance of the account address provided
     */
    // Certik: SES-03 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function balanceOf(address account) public view returns (uint256 balance) {
        StructLib.LedgerReturn memory ret = LedgerLib.getLedgerEntry(ld, std, ctd, account);
        balance = ret.spot_sumQty;
    }
    
    /**
     * @dev standard ERC20 token transfer
     * @param recipient receiver's account address
     * @param amount to be transferred to the recipient
     * @return transferStatus
     * @param transferStatus returns status of transfer: true or false 
     */
    // Certik: SES-03 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function transfer(address recipient, uint256 amount) public returns (bool transferStatus) {
        require(balanceOf(msg.sender) >= amount, "Insufficient tokens");

        transferStatus = Erc20Lib.transfer(ld, std, ctd, globalFees, Erc20Lib.transferErc20Args({
      deploymentOwner: deploymentOwner,
            recipient: recipient,
               amount: amount
        }));
    }

    // ERC20 - approvals
    
    /**
     * @dev standard ERC20 token allowance
     * @param sender (owner) of the erc20 tokens
     * @param spender of the erc20 tokens
     * @return spendAllowance 
     * @param spendAllowance returns the erc20 allowance as per approval by owner
     */
    // Certik: SES-03 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function allowance(address sender, address spender) public view returns (uint256 spendAllowance) { 
        spendAllowance = erc20d._allowances[sender][spender];
    }
    
    /**
     * @dev standard ERC20 token approve
     * @param spender spender of the erc20 tokens to be give approval for allowance
     * @param amount amount to be approved for allowance for spending on behalf of the owner
     * @return approvalStatus 
     * @param approvalStatus returns approval status
     */
    // Certik: SES-03 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function approve(address spender, uint256 amount) public returns (bool approvalStatus) { 
        approvalStatus = Erc20Lib.approve(ld, erc20d, spender, amount);
    }
    
    /**
     * @dev standard ERC20 token transferFrom
     * @param sender ERC20 token sender
     * @param recipient ERC20 tkoen receiver
     * @param amount amount to be transferred
     * @return transferFromStatus
     * @param transferFromStatus returns status of transfer: true or false 
     */
    // Certik: SES-03 | Return Variable Utilization
    // Resolved (AD): Utilized return variable for gas optimization
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool transferFromStatus) { 
        transferFromStatus = Erc20Lib.transferFrom(ld, std, ctd, globalFees, erc20d, sender, Erc20Lib.transferErc20Args({
      deploymentOwner: deploymentOwner,
            recipient: recipient,
               amount: amount
        }));
    }
//#endif
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./StLedger.sol";

import "../Interfaces/StructLib.sol";
import "../Libs/TokenLib.sol";

 /**
  * @title Burnable Security Tokens
  * @author Dominic Morris (7-of-9)
  * @notice retirement of security tokens
  * <pre>   - inherits Owned ownership smart contract</pre>
  * <pre>   - inherits StLedger security token ledger contract</pre>
  * <pre>   - uses StructLib interface library</pre>
  * <pre>   - uses TokenLib runtime library</pre>
  */
abstract contract StBurnable is StLedger {

    /**
     * @dev burning of security tokens
     * @param ledgerOwner account address of the ledger owner of the security token batch
     * @param tokTypeId token type of the token batch
     * @param burnQty amount to be burned
     * @param stIds sum of supplied STs current qty must equal supplied burnQty
     */
    function burnTokens(
        address          ledgerOwner,
        uint256          tokTypeId,
        int256           burnQty,
        uint256[] memory stIds      // IFF supplied (len > 0): sum of supplied STs current qty must == supplied burnQty
    )
    public onlyOwner() onlyWhenReadWrite() {
        TokenLib.burnTokens(ld, std, TokenLib.BurnTokenArgs({
               ledgerOwner: ledgerOwner,
                 tokTypeId: tokTypeId,
                   burnQty: burnQty,
                   k_stIds: stIds
        }));
    }

    // 24k
    /**
     * @dev returns the security token total burned quantity
     * @return totalBurnedQty
     * @param totalBurnedQty returns the security token total burned quantity
     */
    function getSecToken_totalBurnedQty()
    external view returns (uint256 totalBurnedQty) { return ld._spot_totalBurnedQty; }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

/**
  * @title Owned
  * @author Dominic Morris (7-of-9)
  * @notice governance contract to manage access control
  */
contract Owned
{
    // CUSTODY TYPE
    enum CustodyType { SELF_CUSTODY, THIRD_PARTY_CUSTODY }

    // Certik: OSM-02 | Inefficient storage layout
    // Resolved (AD): Variables placed next to each other to tight pack them in a single storage slot
    address payable deploymentOwner;
    bool readOnlyState;
    // Certik: (Minor) OSM-07 | Inexistent Management Functionality The Owned contract implementation should be self-sufficient and possess adding and removing owners within it.
    // Resolved: Passing owners list from StMaster to Owned ctor
    address[] owners;

    CustodyType public custodyType;
    uint8 constant THIRDPARTY_CUSTODY_NDX = 1;

    
    /**
     * @dev returns the read only state of the deployement
     * @return isReadOnly
     * @param isReadOnly returns the read only state of the deployement
     */
    // Certik: OSM-03 | Return Variable Utilization
    // Resolved (AD): Utilizing Return Variable
    function readOnly() external view returns (bool isReadOnly) { isReadOnly = readOnlyState; }
    constructor(address[] memory _owners, CustodyType _custodyType) {
        owners = _owners;
        custodyType = _custodyType;
        deploymentOwner = payable(msg.sender); // payable used in solidity version 0.8.0 onwards
        // Certik: OSM-04 | Redundant Variable Initialization
        // Resolved (AD): Default READ-ONLY state is false
    }

    /**
     * @dev returns the deployment owner addresses
     * @return deploymentOwners
     * @param deploymentOwners owner's account addresses of deployment owners
     */
    // Certik: OSM-03 | Return Variable Utilization
    // Resolved (AD): Utilizing Return Variable
    function getOwners() external view returns (address[] memory deploymentOwners) { deploymentOwners = owners; }
    
    /**
     * @dev modifier to limit access to deployment owners onlyOwner
     */
    modifier onlyOwner() {
        // Certik: OSM-05 | Inefficient storage read
        // Resolved (AD): Utilizing local variable to save storage read gas cost
        uint ownersCount = owners.length;
        for (uint i = 0; i < ownersCount; i++) {
            // Certik: (Minor) OSM-08 | Usage of tx.origin The use of tx.origin should be avoided for ownership-based systems given that firstly it can be tricked on-chain and secondly it will change its functionality once EIP-3074 is integrated.
            // Review: (Minor) OSM-08 | changed tx.origin to msg.sender - tested ok for cashflow base.
            if (owners[i] == msg.sender) {  _; return; }
        }
        revert("Restricted");
        _;
    }

    modifier onlyCustodian() {
        // Certik: OSM-05 | Inefficient storage read
        // Resolved (AD): Utilizing local variable to save storage read gas cost
        uint ownersCount = owners.length;
        if (custodyType == CustodyType.SELF_CUSTODY) {
            for (uint i = 0; i < ownersCount; i++) {
                if (owners[i] == msg.sender) {  _; return; }
            }
            revert("Restricted");
        }
        else {
            if (custodyType == CustodyType.THIRD_PARTY_CUSTODY) {
                if (owners[THIRDPARTY_CUSTODY_NDX] == msg.sender) {  _; return; } // fixed reserved addresses index for custodian address
                else { revert("Restricted"); }
            }
            revert("Bad custody type");
        }
        _;
    }
    
    /**
     * @dev access modifier to allow read-write only when the READ-ONLY mode is off
     */
    modifier onlyWhenReadWrite() {
        // Certik: OSM-06 | Comparison with literal false
        // Resolved (AD): replaced literal false comparison with !readOnlyState
        require(!readOnlyState, "Read-only");
        _;
    }

    /**
     * @dev change the control state to READ-ONLY [in case of emergencies or security threats as part of disaster recovery] 
     * @param readOnlyNewState only state: true or false
     */
    function setReadOnly(bool readOnlyNewState) external onlyOwner() {
        readOnlyState = readOnlyNewState;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./StErc20.sol";

import "../Interfaces/StructLib.sol";
import "../Libs/LoadLib.sol";

abstract // solc 0.6

 /**
  * @title Loadable Data
  * @author Dominic Morris (7-of-9)
  * @notice loads security token batches and adds a ledger entry
  * <pre>   - inherits Owned ownership smart contract</pre>
  * <pre>   - inherits StLedger security token ledger contract</pre>
  * <pre>   - inherits StErc20 standard ERC20 token contract </pre>
  * <pre>   - inherits StFees fee management contract </pre>
  * <pre>   - uses StructLib interface library</pre>
  * <pre>   - uses LoadLib runtime library</pre>
  */
  
contract DataLoadable is
    StErc20 {

    /**
    * @dev load a single or multiple security token batch(es)
    * @param batches takes an array of security token batches
    * @param _batches_currentMax_id total count of existing batches
    */
    function loadSecTokenBatch(
        StructLib.SecTokenBatch[] memory batches,
        uint64 _batches_currentMax_id
    ) public onlyOwner() {
        LoadLib.loadSecTokenBatch(ld, batches, _batches_currentMax_id);
    }

    /**
    * @dev add an entry to the ledger
    * @param ledgerEntryOwner account address of the ledger owner for the entry
    * @param ccys ledger entries for currency types structure that includes currency identifier, name, unit, balance, reserved
    * @param spot_sumQtyMinted spot exchange total assets minted quantity
    * @param spot_sumQtyBurned spot exchange total assets burned quantity 
    */
    function createLedgerEntry(
        address ledgerEntryOwner,
        StructLib.LedgerCcyReturn[] memory ccys,
        uint256 spot_sumQtyMinted,
        uint256 spot_sumQtyBurned
    ) public onlyOwner() {
        LoadLib.createLedgerEntry(ld, ledgerEntryOwner, ccys, spot_sumQtyMinted, spot_sumQtyBurned);
    }

    /**
    * @dev add a new security token
    * @param ledgerEntryOwner account address of the ledger entry owner
    * @param batchId unique batch identifier for each security token type
    * @param stId security token identifier of the batch
    * @param tokTypeId token type of the batch
    * @param mintedQty existence check field: should never be non-zero
    * @param currentQty current (variable) unit qty in the ST (i.e. burned = currentQty - mintedQty)
    * @param ft_price becomes average price after combining [futures only]
    * @param ft_lastMarkPrice last mark price [futures only]
    * @param ft_ledgerOwner for takePay() lookup of ledger owner by ST [futures only]
    * @param ft_PL running total P&L [futures only]
    */
    function addSecToken(
        address ledgerEntryOwner,
        uint64 batchId, uint256 stId, uint256 tokTypeId, int64 mintedQty, int64 currentQty,
        int128 ft_price, int128 ft_lastMarkPrice, address ft_ledgerOwner, int128 ft_PL
    ) public onlyOwner() {
        LoadLib.addSecToken(ld,
            ledgerEntryOwner, batchId, stId, tokTypeId, mintedQty, currentQty, ft_price, ft_lastMarkPrice, ft_ledgerOwner, ft_PL
        );
    }

    /**
     * @dev setting totals for security token
     * @param base_id 1-based - assigned (once, when set to initial zero value) by Mint()
     * @param currentMax_id 1-based identifiers updated by Mint() and by transferSplitSecTokens()
     * @param totalMintedQty total burned quantity in the spot exchange
     * @param totalBurnedQty total burned quantity in the spot exchange
     */
    function setTokenTotals(
        //uint80 packed_ExchangeFeesPaidQty, uint80 packed_OriginatorFeesPaidQty, uint80 packed_TransferedQty,
        uint256 base_id,
        uint256 currentMax_id, uint256 totalMintedQty, uint256 totalBurnedQty
    ) public onlyOwner() {
        LoadLib.setTokenTotals(ld,
            //packed_ExchangeFeesPaidQty, packed_OriginatorFeesPaidQty, packed_TransferedQty,
            base_id,
            currentMax_id, totalMintedQty, totalBurnedQty
        );
    }

    // function setCcyTotals(
    //     //LoadLib.SetCcyTotalArgs memory a
    //     uint256 ccyTypeId,
    //     uint256 totalFunded,
    //     uint256 totalWithdrawn,
    //     uint256 totalTransfered,
    //     uint256 totalFeesPaid
    // ) public onlyOwner() {
    //     LoadLib.setCcyTotals(ld, ccyTypeId, totalFunded, totalWithdrawn, totalTransfered, totalFeesPaid);
    // }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "./StLedger.sol";

import "../Interfaces/StructLib.sol";
import "../Libs/CcyLib.sol";

 /**
  * @title Collateralizable Currencies
  * @author Dominic Morris (7-of-9)
  * @notice Collateralizable is configured for fiat and other collateralizable currencies
  * @dev contains all operations related to fiat and other currency type collateral management
  * <pre>   - inherits StLedger security token ledger contract</pre>
  * <pre>   - inherits Owned ownership smart contract</pre>
  * <pre>   - uses StructLib interface library</pre>
  * <pre>   - uses CcyLib runtime library</pre>
  */
abstract contract Collateralizable is
    StLedger {

//#if process.env.CONTRACT_TYPE !== 'CASHFLOW_BASE'
//#     /**
//#     * @dev add supporting currency types
//#     * @param name name of the currency
//#     * @param unit unit of the currency
//#     * @param decimals level of precision of the currency
//#     */
//#     function addCcyType(string memory name, string memory unit, uint16 decimals)
//#     public onlyOwner() onlyWhenReadWrite() {
//#         CcyLib.addCcyType(ld, ctd, name, unit, decimals);
//#     }
//# 
//#     /**
//#     * @dev returns the current supporting currencies
//#     * @return ccyTypes
//#     * @param ccyTypes array of supporting currency types struct
//#     */
//#     function getCcyTypes() external view returns (StructLib.GetCcyTypesReturn memory ccyTypes) {
//#         return CcyLib.getCcyTypes(ctd);
//#     }
//# 
//#     /**
//#     * @dev fund or withdraw currency type collaterised tokens from a ledger owner address
//#     * @param direction 0: FUND<br/>1: WITHDRAW
//#     * @param ccyTypeId currency type identifier
//#     * @param amount amount to be funded or withdrawn
//#     * @param ledgerOwner account address to be funded or withdrawn from
//#     * @param desc supporting evidence like bank wire reference or comments
//#     */
//#     function fundOrWithdraw(
//#         StructLib.FundWithdrawType direction,
//#         uint256 ccyTypeId,
//#         int256  amount,
//#         address ledgerOwner,
//#         string  calldata desc)
//#     public onlyOwner() onlyWhenReadWrite() {
//#         CcyLib.fundOrWithdraw(ld, ctd, direction, ccyTypeId, amount, ledgerOwner, desc);
//#     }
//# 
//#     // 24k
//#     // function getTotalCcyFunded(uint256 ccyTypeId)
//#     // external view returns (uint256) {
//#     //     return ld._ccyType_totalFunded[ccyTypeId];
//#     // }
//#     // function getTotalCcyWithdrawn(uint256 ccyTypeId)
//#     // external view returns (uint256) {
//#     //     return ld._ccyType_totalWithdrawn[ccyTypeId];
//#     // }
//#endif
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../Interfaces/StructLib.sol";

import "../StMaster/StMaster.sol";

library TransferLib {
    event TransferedFullSecToken(address indexed from, address indexed to, uint256 indexed stId, uint256 mergedToSecTokenId, uint256 qty, StructLib.TransferType transferType);
    event TransferedPartialSecToken(address indexed from, address indexed to, uint256 indexed splitFromSecTokenId, uint256 newSecTokenId, uint256 mergedToSecTokenId, uint256 qty, StructLib.TransferType transferType);
    event TradedCcyTok(uint256 ccyTypeId, uint256 ccyAmount, uint256 tokTypeId, address indexed /*tokens*/from, address indexed /*tokens*/to, uint256 tokQty, uint256 ccyFeeFrom, uint256 ccyFeeTo);

    uint256 constant MAX_BATCHES_PREVIEW = 128; // for fee previews: max distinct batch IDs that can participate in one side of a trade fee preview

    //
    // PUBLIC - transfer/trade
    //
    struct TransferVars { // misc. working vars for transfer() fn - struct packed to preserve stack slots
        TransferSplitPreviewReturn[2] ts_previews; // [0] = A->B, [1] = B->A
        TransferSplitArgs[2]          ts_args;
        uint256[2]                    totalOrigFee;
        uint80                        transferedQty;
        uint80                        exchangeFeesPaidQty;
        uint80                        originatorFeesPaidQty;
    }
    // Certik: (Minor) TRA-01 | Equal ID Transfers The transfers of equal IDs are not prohibited in the transferOrTrade function
    // Review: TODO - (Minor) TRA-01 | Check with Certik as this might break critical transfer / trading functionality
    function transferOrTrade(
        StructLib.LedgerStruct storage   ld,
        StructLib.StTypesStruct storage  std,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.FeeStruct storage      globalFees,
        StructLib.TransferArgs memory    a
    )
    public {
        // split-ledger: controller runs same method on base type (i.e. re-entrant)...
        //               each run is segmented by switches on controller vs. base types...
        //                  >> controller only updates/reads/validates ccy
        //                  >> base only updates/reads/validates tok's

        // TODO: for one-sided (ccy && token) transfers, output the supplied transferType in event... (space for this, for token events?!)

        TransferVars memory v;
        uint256 maxStId = ld._tokens_currentMax_id;

        require(ld._contractSealed, "Contract is not sealed");
        require(a.qty_A > 0 || a.qty_B > 0 || a.ccy_amount_A > 0 || a.ccy_amount_B > 0, "Bad null transfer");
        require(a.qty_A <= 0x7FFFFFFFFFFFFFFF, "Bad qty_A"); //* (2^64 /2: max signed int64) [was: 0xffffffffffffffff]
        require(a.qty_B <= 0x7FFFFFFFFFFFFFFF, "Bad qty_B"); //*

        // disallow single origin multiple asset type transfers
        require(!((a.qty_A > 0 && a.ccy_amount_A > 0) || (a.qty_B > 0 && a.ccy_amount_B > 0)), "Bad transfer types");

        // disallow currency swaps - we need single consistent ccy type on each side for ccy-fee mirroring
        // i.e. disallow swaps of two different currency-types (note: do allow: swaps of two different token-types)
        require(a.ccyTypeId_A == 0 || a.ccyTypeId_B == 0, "Bad ccy swap");

        // validate currency/token types
        if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) {
            if (a.ccy_amount_A > 0) require(a.ccyTypeId_A > 0 && a.ccyTypeId_A <= ctd._ct_Count, "Bad ccyTypeId A");
            if (a.ccy_amount_B > 0) require(a.ccyTypeId_B > 0 && a.ccyTypeId_B <= ctd._ct_Count, "Bad ccyTypeId B");
        }
        if (a.qty_A > 0) require(a.tokTypeId_A > 0, "Bad tokTypeId_A");
        if (a.qty_B > 0) require(a.tokTypeId_B > 0, "Bad tokTypeId_B");

        // require a transferType for one-sided transfers;
        // disallow transferType on two-sided trades (both ccy-tok trades, and [edgecase] tok-tok trades)
        if ((a.ccyTypeId_A > 0 && a.tokTypeId_B == 0) || (a.ccyTypeId_B > 0 && a.tokTypeId_A == 0) ||
            (a.tokTypeId_A > 0 && a.ccyTypeId_B == 0 && a.tokTypeId_B == 0) || (a.tokTypeId_B > 0 && a.ccyTypeId_A == 0 && a.tokTypeId_A == 0)
        ) {
             //require(a.transferType >= StructLib.TransferType.MintFee && a.transferType <= StructLib.TransferType.Adjustment, "Bad transferType");
            require(a.transferType >= StructLib.TransferType.SettlePay, "Bad transferType");
        }
        else require(a.transferType == StructLib.TransferType.Undefined, "Invalid transfer type");

        // cashflow controller: delegate token actions to base type
        if (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER) { //**
            if (a.qty_A > 0) {
                StMaster base_A = StMaster(std._tt_addr[a.tokTypeId_A]);
                base_A.transferOrTrade(StructLib.TransferArgs({ 
                     ledger_A: a.ledger_A,
                     ledger_B: a.ledger_B,
                        qty_A: a.qty_A,
                    k_stIds_A: a.k_stIds_A,
                  tokTypeId_A: 1/*a.tokTypeId_A*/, // base: UNI_TOKEN (controller does type ID mapping for clients)
                        qty_B: a.qty_B,
                    k_stIds_B: a.k_stIds_B,
                  tokTypeId_B: a.tokTypeId_B,
                 ccy_amount_A: a.ccy_amount_A,
                  ccyTypeId_A: a.ccyTypeId_A,
                 ccy_amount_B: a.ccy_amount_B,
                  ccyTypeId_B: a.ccyTypeId_B,
                    applyFees: a.applyFees,
                 feeAddrOwner: a.feeAddrOwner,
                 transferType: a.transferType
                }));
            }
            if (a.qty_B > 0) {
                StMaster base_B = StMaster(std._tt_addr[a.tokTypeId_B]);
                base_B.transferOrTrade(StructLib.TransferArgs({ 
                     ledger_A: a.ledger_A,
                     ledger_B: a.ledger_B,
                        qty_A: a.qty_A,
                    k_stIds_A: a.k_stIds_A,
                  tokTypeId_A: a.tokTypeId_A,
                        qty_B: a.qty_B,
                    k_stIds_B: a.k_stIds_B,
                  tokTypeId_B: 1/*a.tokTypeId_B*/, // base: UNI_TOKEN (controller does type ID mapping for clients)
                 ccy_amount_A: a.ccy_amount_A,
                  ccyTypeId_A: a.ccyTypeId_A,
                 ccy_amount_B: a.ccy_amount_B,
                  ccyTypeId_B: a.ccyTypeId_B,
                    applyFees: a.applyFees,
                 feeAddrOwner: a.feeAddrOwner,
                 transferType: a.transferType
                }));
            }
        }

        // transfer by ST ID: check supplied STs belong to supplied owner(s), and implied quantities match supplied quantities
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) { //**
            checkStIds(ld, a);
        }

        // erc20 support - initialize ledger entry if not known
        StructLib.initLedgerIfNew(ld, a.ledger_A);
        StructLib.initLedgerIfNew(ld, a.ledger_B);

        //
        // exchange fees (global or ledger override) (disabled if fee-reciever[contract owner] == fee-payer)
        // calc total payable (fixed + basis points), cap & collar
        //
        StructLib.FeeStruct storage exFeeStruct_ccy_A = ld._ledger[a.ledger_A].spot_customFees.ccyType_Set[a.ccyTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_tok_A = ld._ledger[a.ledger_A].spot_customFees.tokType_Set[a.tokTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_ccy_B = ld._ledger[a.ledger_B].spot_customFees.ccyType_Set[a.ccyTypeId_B] ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_tok_B = ld._ledger[a.ledger_B].spot_customFees.tokType_Set[a.tokTypeId_B] ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
        StructLib.FeesCalc memory exFees = StructLib.FeesCalc({ // exchange fees (disabled if fee-reciever == fee-payer)
            fee_ccy_A: a.ledger_A != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_ccy_A.ccy[a.ccyTypeId_A], uint256(a.ccy_amount_A), a.qty_B) : 0,
            fee_ccy_B: a.ledger_B != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_ccy_B.ccy[a.ccyTypeId_B], uint256(a.ccy_amount_B), a.qty_A) : 0,
            fee_tok_A: a.ledger_A != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_tok_A.tok[a.tokTypeId_A], a.qty_A,                 0)       : 0,
            fee_tok_B: a.ledger_B != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_tok_B.tok[a.tokTypeId_B], a.qty_B,                 0)       : 0,
               fee_to: a.feeAddrOwner,
       origTokFee_qty: 0,
   origTokFee_batchId: 0,
    origTokFee_struct: StructLib.SetFeeArgs({
            fee_fixed: 0,
         fee_percBips: 0,
              fee_min: 0,
              fee_max: 0,
       ccy_perMillion: 0,
        ccy_mirrorFee: false
        })
        });

        // apply exchange ccy fee mirroring - only ever from one side to the other
        if (exFees.fee_ccy_A > 0 && exFees.fee_ccy_B == 0) {
            if (exFeeStruct_ccy_A.ccy[a.ccyTypeId_A].ccy_mirrorFee == true) {
                a.ccyTypeId_B = a.ccyTypeId_A;
                //exFees.fee_ccy_B = exFees.fee_ccy_A; // symmetric mirror

                // asymmetric mirror
                exFeeStruct_ccy_B = ld._ledger[a.ledger_B].spot_customFees.ccyType_Set[a.ccyTypeId_B]   ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
                exFees.fee_ccy_B = a.ledger_B != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_ccy_B.ccy[a.ccyTypeId_B], uint256(a.ccy_amount_A), a.qty_B) : 0; // ??!
            }
        }
        else if (exFees.fee_ccy_B > 0 && exFees.fee_ccy_A == 0) {
            if (exFeeStruct_ccy_B.ccy[a.ccyTypeId_B].ccy_mirrorFee == true) {
                a.ccyTypeId_A = a.ccyTypeId_B;
                //exFees.fee_ccy_A = exFees.fee_ccy_B; // symmetric mirror

                // asymmetric mirror
                exFeeStruct_ccy_A = ld._ledger[a.ledger_A].spot_customFees.ccyType_Set[a.ccyTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
                exFees.fee_ccy_A = a.ledger_A != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_ccy_A.ccy[a.ccyTypeId_A], uint256(a.ccy_amount_B), a.qty_A) : 0; // ??!
            }
        }

        //
        // originator token fees (disabled if fee-reciever[batch originator] == fee-payer)
        // potentially multiple: up to one originator token fee per distinct token batch
        //
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) { //**
            if (a.qty_A > 0) {
                v.ts_args[0] = TransferSplitArgs({ from: a.ledger_A, to: a.ledger_B, tokTypeId: a.tokTypeId_A, qtyUnit: a.qty_A, transferType: a.transferType == StructLib.TransferType.Undefined ? StructLib.TransferType.User : a.transferType, maxStId: maxStId, k_stIds_take: a.k_stIds_A/*, k_stIds_skip: new uint256[](0)*/ });
                v.ts_previews[0] = transferSplitSecTokens_Preview(ld, v.ts_args[0]);
                for (uint i = 0; i < v.ts_previews[0].batchCount ; i++) {
                    StructLib.SecTokenBatch storage batch = ld._batches[v.ts_previews[0].batchIds[i]];
                    uint256 tokFee = a.ledger_A != batch.originator ? calcFeeWithCapCollar(batch.origTokFee, v.ts_previews[0].transferQty[i], 0) : 0;
                    v.totalOrigFee[0] += tokFee;
                }
            }
            if (a.qty_B > 0) {
                v.ts_args[1] = TransferSplitArgs({ from: a.ledger_B, to: a.ledger_A, tokTypeId: a.tokTypeId_B, qtyUnit: a.qty_B, transferType: a.transferType == StructLib.TransferType.Undefined ? StructLib.TransferType.User : a.transferType, maxStId: maxStId, k_stIds_take: a.k_stIds_B/*, k_stIds_skip: new uint256[](0)*/ });
                v.ts_previews[1] = transferSplitSecTokens_Preview(ld, v.ts_args[1]);
                for (uint i = 0; i < v.ts_previews[1].batchCount ; i++) {
                    StructLib.SecTokenBatch storage batch = ld._batches[v.ts_previews[1].batchIds[i]];
                    uint256 tokFee = a.ledger_B != batch.originator ? calcFeeWithCapCollar(batch.origTokFee, v.ts_previews[1].transferQty[i], 0) : 0;
                    v.totalOrigFee[1] += tokFee;
                }
            }
        }

        // validate currency balances - transfer amount & fees
        if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) { //**
            require(StructLib.sufficientCcy(ld, a.ledger_A, a.ccyTypeId_A, a.ccy_amount_A/*amount sending*/, a.ccy_amount_B/*amount receiving*/, int256(exFees.fee_ccy_A * uint256(a.applyFees /*&& a.ccy_amount_A > 0 */? 1 : 0))), "Insufficient currency A");
            require(StructLib.sufficientCcy(ld, a.ledger_B, a.ccyTypeId_B, a.ccy_amount_B/*amount sending*/, a.ccy_amount_A/*amount receiving*/, int256(exFees.fee_ccy_B * uint256(a.applyFees /*&& a.ccy_amount_B > 0 */? 1 : 0))), "Insufficient currency B");
        }

        // validate token balances - sum exchange token fee + originator token fee(s)
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) { //**
            require(StructLib.sufficientTokens(ld, a.ledger_A, a.tokTypeId_A, int256(a.qty_A), int256((exFees.fee_tok_A + v.totalOrigFee[0]) * (a.applyFees && a.qty_A > 0 ? 1 : 0))), "Insufficient tokens A");
            require(StructLib.sufficientTokens(ld, a.ledger_B, a.tokTypeId_B, int256(a.qty_B), int256((exFees.fee_tok_B + v.totalOrigFee[1]) * (a.applyFees && a.qty_B > 0 ? 1 : 0))), "Insufficient tokens B");
        }

        //
        // transfer currencies
        //
        if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) { //**
            if (a.ccy_amount_A > 0) { // user transfer from A
                StructLib.transferCcy(ld, StructLib.TransferCcyArgs({ from: a.ledger_A, to: a.ledger_B, ccyTypeId: a.ccyTypeId_A, amount: uint256(a.ccy_amount_A), transferType: a.transferType == StructLib.TransferType.Undefined ? StructLib.TransferType.User : a.transferType }));
            }
            if (a.applyFees && exFees.fee_ccy_A > 0) { // exchange fee transfer from A
                StructLib.transferCcy(ld, StructLib.TransferCcyArgs({ from: a.ledger_A, to: a.feeAddrOwner, ccyTypeId: a.ccyTypeId_A, amount: exFees.fee_ccy_A, transferType: StructLib.TransferType.ExchangeFee }));
            }

            if (a.ccy_amount_B > 0) { // user transfer from B
                StructLib.transferCcy(ld, StructLib.TransferCcyArgs({ from: a.ledger_B, to: a.ledger_A, ccyTypeId: a.ccyTypeId_B, amount: uint256(a.ccy_amount_B), transferType: a.transferType == StructLib.TransferType.Undefined ? StructLib.TransferType.User : a.transferType }));
            }
            if (a.applyFees && exFees.fee_ccy_B > 0) { // exchange fee transfer from B
                StructLib.transferCcy(ld, StructLib.TransferCcyArgs({ from: a.ledger_B, to: a.feeAddrOwner, ccyTypeId: a.ccyTypeId_B, amount: exFees.fee_ccy_B, transferType: StructLib.TransferType.ExchangeFee }));
            }
        }

        //
        // apply originator currency fees per batch (capped % of total exchange currency fee)
        //
        if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) { //**
            if (a.applyFees) {
                uint256 tot_exFee_ccy = exFees.fee_ccy_A + exFees.fee_ccy_B;

                if (tot_exFee_ccy > 0) {
                    require(a.ccyTypeId_A != 0 || a.ccyTypeId_B != 0, "Unexpected: undefined currency types");
                    if (a.ccyTypeId_A != 0 && a.ccyTypeId_B != 0) {
                        require(a.ccyTypeId_A == a.ccyTypeId_B, "Unexpected: mirrored currency type mismatch");
                    }
                    uint256 ccyTypeId = a.ccyTypeId_A != 0 ? a.ccyTypeId_A : a.ccyTypeId_B;

                    // apply for A->B token batches
                    applyOriginatorCcyFees(ld, v.ts_previews[0], tot_exFee_ccy, a.qty_A, a.feeAddrOwner, ccyTypeId);

                    // apply for B->A token batches
                    applyOriginatorCcyFees(ld, v.ts_previews[1], tot_exFee_ccy, a.qty_B, a.feeAddrOwner, ccyTypeId);
                }
            }
        }

        //
        // transfer tokens
        //
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) { //**
            if (a.qty_A > 0) {
                if (a.applyFees) {
                    // exchange token fee transfer from A
                    if (exFees.fee_tok_A > 0) {
                        maxStId = transferSplitSecTokens(ld, TransferSplitArgs({ from: a.ledger_A, to: a.feeAddrOwner, tokTypeId: a.tokTypeId_A, qtyUnit: exFees.fee_tok_A, transferType: StructLib.TransferType.ExchangeFee, maxStId: maxStId, k_stIds_take: a.k_stIds_A/*, k_stIds_skip: new uint256[](0)*/ }));
                        v.exchangeFeesPaidQty += uint80(exFees.fee_tok_A);
                    }

                    // batch originator token fee transfer(s) from A
                    for (uint i = 0; i < v.ts_previews[0].batchCount ; i++) { // originator token fees
                        StructLib.SecTokenBatch storage batch = ld._batches[v.ts_previews[0].batchIds[i]];
                        uint256 tokFee = a.ledger_A != batch.originator ? calcFeeWithCapCollar(batch.origTokFee, v.ts_previews[0].transferQty[i], 0) : 0;
                        if (tokFee > 0) {
                            maxStId = transferSplitSecTokens(ld, TransferSplitArgs({ from: a.ledger_A, to: batch.originator, tokTypeId: a.tokTypeId_A, qtyUnit: tokFee, transferType: StructLib.TransferType.OriginatorFee, maxStId: maxStId, k_stIds_take: a.k_stIds_A/*, k_stIds_skip: new uint256[](0)*/ }));
                            v.originatorFeesPaidQty += uint80(tokFee);
                        }
                    }
                }
                // user transfer from A
                maxStId = transferSplitSecTokens(ld,
                    TransferSplitArgs({ from: v.ts_args[0].from, to: v.ts_args[0].to, tokTypeId: v.ts_args[0].tokTypeId, qtyUnit: v.ts_args[0].qtyUnit, transferType: v.ts_args[0].transferType, maxStId: maxStId, k_stIds_take: a.k_stIds_A/*, k_stIds_skip: new uint256[](0)*/ })
                );
                v.transferedQty += uint80(v.ts_args[0].qtyUnit);
            }
            if (a.qty_B > 0) {
                if (a.applyFees) {
                    // exchange token fee transfer from B
                    if (exFees.fee_tok_B > 0) {
                        maxStId = transferSplitSecTokens(ld, TransferSplitArgs({ from: a.ledger_B, to: a.feeAddrOwner, tokTypeId: a.tokTypeId_B, qtyUnit: exFees.fee_tok_B, transferType: StructLib.TransferType.ExchangeFee, maxStId: maxStId, k_stIds_take: a.k_stIds_B/*, k_stIds_skip: new uint256[](0)*/ }));
                        v.exchangeFeesPaidQty += uint80(exFees.fee_tok_B);
                    }

                    // batch originator token fee transfer(s) from B
                    for (uint i = 0; i < v.ts_previews[1].batchCount ; i++) { // originator token fees
                        StructLib.SecTokenBatch storage batch = ld._batches[v.ts_previews[1].batchIds[i]];
                        uint256 tokFee = a.ledger_B != batch.originator ? calcFeeWithCapCollar(batch.origTokFee, v.ts_previews[1].transferQty[i], 0) : 0;
                        if (tokFee > 0) {
                            maxStId = transferSplitSecTokens(ld, TransferSplitArgs({ from: a.ledger_B, to: batch.originator, tokTypeId: a.tokTypeId_B, qtyUnit: tokFee, transferType: StructLib.TransferType.OriginatorFee, maxStId: maxStId, k_stIds_take: a.k_stIds_B/*, k_stIds_skip: new uint256[](0)*/ }));
                            v.originatorFeesPaidQty += uint80(tokFee);
                        }
                    }
                }
                // user transfer from B
                maxStId = transferSplitSecTokens(ld,
                    TransferSplitArgs({ from: v.ts_args[1].from, to: v.ts_args[1].to, tokTypeId: v.ts_args[1].tokTypeId, qtyUnit: v.ts_args[1].qtyUnit, transferType: v.ts_args[1].transferType, maxStId: maxStId, k_stIds_take: a.k_stIds_B/*, k_stIds_skip: new uint256[](0)*/ })
                );
                v.transferedQty += uint80(v.ts_args[1].qtyUnit);
            }

            // set globals to final values
            ld._tokens_currentMax_id = maxStId; // packing this as a uint64 (and the fields below) into _spot_total struct *increases* gas cost! no idea why - reverted
        }

        // 24k
        //if (v.exchangeFeesPaidQty > 0) ld._spot_total.exchangeFeesPaidQty += v.exchangeFeesPaidQty;
        //if (v.originatorFeesPaidQty > 0) ld._spot_total.originatorFeesPaidQty += v.originatorFeesPaidQty;
        //ld._spot_total.transferedQty += v.transferedQty + v.exchangeFeesPaidQty + v.originatorFeesPaidQty;

        // emit trade events
        if (ld.contractType != StructLib.ContractType.CASHFLOW_BASE) { //**
            if (a.ccy_amount_A > 0 && a.qty_B > 0) {
                emit TradedCcyTok(a.ccyTypeId_A, uint256(a.ccy_amount_A), a.tokTypeId_B, a.ledger_B, a.ledger_A, a.qty_B, a.applyFees ? exFees.fee_ccy_B : 0, a.applyFees ? exFees.fee_ccy_A : 0);
            }
            if (a.ccy_amount_B > 0 && a.qty_A > 0) {
                emit TradedCcyTok(a.ccyTypeId_B, uint256(a.ccy_amount_B), a.tokTypeId_A, a.ledger_A, a.ledger_B, a.qty_A, a.applyFees ? exFees.fee_ccy_A : 0, a.applyFees ? exFees.fee_ccy_B : 0);
            }
        }
    }

    //
    // PUBLIC - fee preview (FULL - includes originator token fees)
    //
    function transfer_feePreview(
        StructLib.LedgerStruct storage  ld,
        StructLib.StTypesStruct storage std,
        StructLib.FeeStruct storage     globalFees,
        address                         feeAddrOwner,
        StructLib.TransferArgs memory   a
    )
    public view
    // 1 exchange fee (single destination) + maximum of MAX_BATCHES_PREVIEW of originator fees on each side (x2) of the transfer
    returns (
        StructLib.FeesCalc[1 + MAX_BATCHES_PREVIEW * 2] memory feesAll
        //
        // SPLITTING
        // want to *also* return the # of full & partial ST transfers, involved in *ALL* the transfer actions (not just fees)
        // each set of { partialCount, fullCount } should be grouped by transfer-type: USER, EX_FEE, ORIG_FEE
        // transfer could then take params: { StructLib.TransferType: partialStart, partialEnd, fullStart, fullEnd } -- basically pagination of the sub-transfers
        //
        // TEST SETUP COULD BE: ~100 minted batches 1 ton each, and move 99 tons A-B (type USER, multi-batch)
        //       try to make orchestrator that batches by (eg.) 10...
        //       (exactly the same for type ORIG_FEE multi-batch)
        //
    ) {
        uint ndx = 0;

        // transfer by ST ID: check supplied STs belong to supplied owner(s), and implied quantities match supplied quantities
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) { //**
            checkStIds(ld, a);
        }

        // exchange fee
        StructLib.FeeStruct storage exFeeStruct_ccy_A = ld._ledger[a.ledger_A].spot_customFees.ccyType_Set[a.ccyTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_tok_A = ld._ledger[a.ledger_A].spot_customFees.tokType_Set[a.tokTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_ccy_B = ld._ledger[a.ledger_B].spot_customFees.ccyType_Set[a.ccyTypeId_B] ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_tok_B = ld._ledger[a.ledger_B].spot_customFees.tokType_Set[a.tokTypeId_B] ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
        feesAll[ndx++] = StructLib.FeesCalc({
            fee_ccy_A: a.ledger_A != a.feeAddrOwner && a.ccy_amount_A > 0 ? calcFeeWithCapCollar(exFeeStruct_ccy_A.ccy[a.ccyTypeId_A], uint256(a.ccy_amount_A), a.qty_B) : 0,
            fee_ccy_B: a.ledger_B != a.feeAddrOwner && a.ccy_amount_B > 0 ? calcFeeWithCapCollar(exFeeStruct_ccy_B.ccy[a.ccyTypeId_B], uint256(a.ccy_amount_B), a.qty_A) : 0,
            fee_tok_A: a.ledger_A != a.feeAddrOwner && a.qty_A > 0        ? calcFeeWithCapCollar(exFeeStruct_tok_A.tok[a.tokTypeId_A], a.qty_A,                 0)       : 0,
            fee_tok_B: a.ledger_B != a.feeAddrOwner && a.qty_B > 0        ? calcFeeWithCapCollar(exFeeStruct_tok_B.tok[a.tokTypeId_B], a.qty_B,                 0)       : 0,
               fee_to: feeAddrOwner,
       origTokFee_qty: 0,
   origTokFee_batchId: 0,
    origTokFee_struct: StructLib.SetFeeArgs({
               fee_fixed: 0,
            fee_percBips: 0,
                 fee_min: 0,
                 fee_max: 0,
          ccy_perMillion: 0,
           ccy_mirrorFee: false
        })
        });

        // apply exchange ccy fee mirroring - only ever from one side to the other
        if (feesAll[0].fee_ccy_A > 0 && feesAll[0].fee_ccy_B == 0) {
            if (exFeeStruct_ccy_A.ccy[a.ccyTypeId_A].ccy_mirrorFee == true) {
                a.ccyTypeId_B = a.ccyTypeId_A;
                //feesAll[0].fee_ccy_B = feesAll[0].fee_ccy_A; // symmetric mirror

                // asymmetric mirror
                exFeeStruct_ccy_B = ld._ledger[a.ledger_B].spot_customFees.ccyType_Set[a.ccyTypeId_B] ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
                feesAll[0].fee_ccy_B = a.ledger_B != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_ccy_B.ccy[a.ccyTypeId_B], uint256(a.ccy_amount_A), a.qty_B) : 0; // ??!
            }
        }
        else if (feesAll[0].fee_ccy_B > 0 && feesAll[0].fee_ccy_A == 0) {
            if (exFeeStruct_ccy_B.ccy[a.ccyTypeId_B].ccy_mirrorFee == true) {
                a.ccyTypeId_A = a.ccyTypeId_B;
                //feesAll[0].fee_ccy_A = feesAll[0].fee_ccy_B; // symmetric mirror

                // asymmetric mirror
                exFeeStruct_ccy_A = ld._ledger[a.ledger_A].spot_customFees.ccyType_Set[a.ccyTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
                feesAll[0].fee_ccy_A = a.ledger_A != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_ccy_A.ccy[a.ccyTypeId_A], uint256(a.ccy_amount_B), a.qty_A) : 0; // ??!
            }
        }

        // originator token fee(s) - per batch
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) { //**
            uint256 maxStId = ld._tokens_currentMax_id;
            if (a.qty_A > 0) {
                TransferSplitPreviewReturn memory preview = transferSplitSecTokens_Preview(ld, TransferSplitArgs({ from: a.ledger_A, to: a.ledger_B, tokTypeId: a.tokTypeId_A, qtyUnit: a.qty_A, transferType: StructLib.TransferType.User, maxStId: maxStId, k_stIds_take: a.k_stIds_A/*, k_stIds_skip: new uint256[](0)*/ }));
                for (uint i = 0; i < preview.batchCount ; i++) {
                    StructLib.SecTokenBatch storage batch = ld._batches[preview.batchIds[i]];
                    if (a.ledger_A != batch.originator) {
                        feesAll[ndx++] = StructLib.FeesCalc({
                            fee_ccy_A: 0,
                            fee_ccy_B: 0,
                            fee_tok_A: calcFeeWithCapCollar(batch.origTokFee, preview.transferQty[i], 0),
                            fee_tok_B: 0,
                               fee_to: batch.originator,
                       origTokFee_qty: preview.transferQty[i],
                   origTokFee_batchId: preview.batchIds[i],
                    origTokFee_struct: batch.origTokFee
                        });
                    }
                }
            }
            if (a.qty_B > 0) {
                TransferSplitPreviewReturn memory preview = transferSplitSecTokens_Preview(ld, TransferSplitArgs({ from: a.ledger_B, to: a.ledger_A, tokTypeId: a.tokTypeId_B, qtyUnit: a.qty_B, transferType: StructLib.TransferType.User, maxStId: maxStId, k_stIds_take: a.k_stIds_B/*, k_stIds_skip: new uint256[](0)*/ }));
                for (uint i = 0; i < preview.batchCount ; i++) {
                    StructLib.SecTokenBatch storage batch = ld._batches[preview.batchIds[i]];
                    if (a.ledger_B != batch.originator) {
                        feesAll[ndx++] = StructLib.FeesCalc({
                            fee_ccy_A: 0,
                            fee_ccy_B: 0,
                            fee_tok_A: 0,
                            fee_tok_B: calcFeeWithCapCollar(batch.origTokFee, preview.transferQty[i], 0),
                               fee_to: batch.originator,
                       origTokFee_qty: preview.transferQty[i],
                   origTokFee_batchId: preview.batchIds[i],
                    origTokFee_struct: batch.origTokFee
                        });
                    }
                }
            }
        }
        else { // controller - delegate token fee previews to base type(s) & merge results
            if (a.qty_A > 0) {
                StMaster base_A = StMaster(std._tt_addr[a.tokTypeId_A]);
                StructLib.FeesCalc[1 + MAX_BATCHES_PREVIEW * 2] memory feesBase = base_A.transfer_feePreview(StructLib.TransferArgs({ 
                     ledger_A: a.ledger_A,
                     ledger_B: a.ledger_B,
                        qty_A: a.qty_A,
                    k_stIds_A: a.k_stIds_A,
                  tokTypeId_A: 1/*a.tokTypeId_A*/, // base: UNI_TOKEN (controller does type ID mapping for clients)
                        qty_B: a.qty_B,
                    k_stIds_B: a.k_stIds_B,
                  tokTypeId_B: a.tokTypeId_B,
                 ccy_amount_A: a.ccy_amount_A,
                  ccyTypeId_A: a.ccyTypeId_A,
                 ccy_amount_B: a.ccy_amount_B,
                  ccyTypeId_B: a.ccyTypeId_B,
                    applyFees: a.applyFees,
                 feeAddrOwner: a.feeAddrOwner,
                 transferType: a.transferType
                }));
                for (uint i = 1 ; i < feesBase.length ; i++) {
                    if (feesBase[i].fee_tok_A > 0) {
                        feesAll[i] = feesBase[i];
                    }
                }
            }
            if (a.qty_B > 0) {
                StMaster base_B = StMaster(std._tt_addr[a.tokTypeId_B]);
                StructLib.FeesCalc[1 + MAX_BATCHES_PREVIEW * 2] memory feesBase = base_B.transfer_feePreview(StructLib.TransferArgs({ 
                     ledger_A: a.ledger_A,
                     ledger_B: a.ledger_B,
                        qty_A: a.qty_A,
                    k_stIds_A: a.k_stIds_A,
                  tokTypeId_A: a.tokTypeId_A,
                        qty_B: a.qty_B,
                    k_stIds_B: a.k_stIds_B,
                  tokTypeId_B: 1/*a.tokTypeId_B*/, // base: UNI_TOKEN (controller does type ID mapping for clients)
                 ccy_amount_A: a.ccy_amount_A,
                  ccyTypeId_A: a.ccyTypeId_A,
                 ccy_amount_B: a.ccy_amount_B,
                  ccyTypeId_B: a.ccyTypeId_B,
                    applyFees: a.applyFees,
                 feeAddrOwner: a.feeAddrOwner,
                 transferType: a.transferType
                }));
                for (uint i = 1 ; i < feesBase.length ; i++) {
                    if (feesBase[i].fee_tok_B > 0) {
                        feesAll[i] = feesBase[i];
                    }
                }
            }
        }
    }

    //
    // PUBLIC - fee preview (FAST - returns only the exchange fee[s])
    //
    function transfer_feePreview_ExchangeOnly(
        StructLib.LedgerStruct storage ld,
        StructLib.FeeStruct storage    globalFees,
        address                        feeAddrOwner,
        StructLib.TransferArgs memory  a
    )
    public view returns (StructLib.FeesCalc[1] memory feesAll) { // 1 exchange fee only (single destination)
        uint ndx = 0;

        // transfer by ST ID: check supplied STs belong to supplied owner(s), and implied quantities match supplied quantities
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) { //**
            checkStIds(ld, a);
        }

        // TODO: refactor - this is common/identical to transfer_feePreview...

        // exchange fee
        StructLib.FeeStruct storage exFeeStruct_ccy_A = ld._ledger[a.ledger_A].spot_customFees.ccyType_Set[a.ccyTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_tok_A = ld._ledger[a.ledger_A].spot_customFees.tokType_Set[a.tokTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_ccy_B = ld._ledger[a.ledger_B].spot_customFees.ccyType_Set[a.ccyTypeId_B] ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
        StructLib.FeeStruct storage exFeeStruct_tok_B = ld._ledger[a.ledger_B].spot_customFees.tokType_Set[a.tokTypeId_B] ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
        feesAll[ndx++] = StructLib.FeesCalc({
            fee_ccy_A: a.ledger_A != a.feeAddrOwner && a.ccy_amount_A > 0 ? calcFeeWithCapCollar(exFeeStruct_ccy_A.ccy[a.ccyTypeId_A], uint256(a.ccy_amount_A), a.qty_B) : 0,
            fee_ccy_B: a.ledger_B != a.feeAddrOwner && a.ccy_amount_B > 0 ? calcFeeWithCapCollar(exFeeStruct_ccy_B.ccy[a.ccyTypeId_B], uint256(a.ccy_amount_B), a.qty_A) : 0,
            fee_tok_A: a.ledger_A != a.feeAddrOwner && a.qty_A > 0        ? calcFeeWithCapCollar(exFeeStruct_tok_A.tok[a.tokTypeId_A], a.qty_A,                 0)       : 0,
            fee_tok_B: a.ledger_B != a.feeAddrOwner && a.qty_B > 0        ? calcFeeWithCapCollar(exFeeStruct_tok_B.tok[a.tokTypeId_B], a.qty_B,                 0)       : 0,
               fee_to: feeAddrOwner,
       origTokFee_qty: 0,
   origTokFee_batchId: 0,
    origTokFee_struct: StructLib.SetFeeArgs({
               fee_fixed: 0,
            fee_percBips: 0,
                 fee_min: 0,
                 fee_max: 0,
          ccy_perMillion: 0,
           ccy_mirrorFee: false
        })
        });

        // apply exchange ccy fee mirroring - only ever from one side to the other
        if (feesAll[0].fee_ccy_A > 0 && feesAll[0].fee_ccy_B == 0) {
            if (exFeeStruct_ccy_A.ccy[a.ccyTypeId_A].ccy_mirrorFee == true) {
                a.ccyTypeId_B = a.ccyTypeId_A;
                //feesAll[0].fee_ccy_B = feesAll[0].fee_ccy_A; // symmetric mirror

                // asymmetric mirror
                exFeeStruct_ccy_B = ld._ledger[a.ledger_B].spot_customFees.ccyType_Set[a.ccyTypeId_B] ? ld._ledger[a.ledger_B].spot_customFees : globalFees;
                feesAll[0].fee_ccy_B = a.ledger_B != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_ccy_B.ccy[a.ccyTypeId_B], uint256(a.ccy_amount_A), a.qty_B) : 0;
            }
        }
        else if (feesAll[0].fee_ccy_B > 0 && feesAll[0].fee_ccy_A == 0) {
            if (exFeeStruct_ccy_B.ccy[a.ccyTypeId_B].ccy_mirrorFee == true) {
                a.ccyTypeId_A = a.ccyTypeId_B;
                //feesAll[0].fee_ccy_A = feesAll[0].fee_ccy_B; // symmetric mirror

                // asymmetric mirror
                exFeeStruct_ccy_A = ld._ledger[a.ledger_A].spot_customFees.ccyType_Set[a.ccyTypeId_A] ? ld._ledger[a.ledger_A].spot_customFees : globalFees;
                feesAll[0].fee_ccy_A = a.ledger_A != a.feeAddrOwner ? calcFeeWithCapCollar(exFeeStruct_ccy_A.ccy[a.ccyTypeId_A], uint256(a.ccy_amount_B), a.qty_A) : 0;
            }
        }
    }

    //
    // INTERNAL - calculate & send batch originator ccy fees (shares of exchange ccy fee)
    //
    function applyOriginatorCcyFees(
        StructLib.LedgerStruct storage    ld,
        TransferSplitPreviewReturn memory ts_preview,
        uint256                           tot_exFee_ccy,
        uint256                           tot_qty,
        address                           feeAddrOwner,
        uint256                           ccyTypeId
    )
    private {
        // batch originator ccy fee - get total bips across all batches
        for (uint i = 0; i < ts_preview.batchCount ; i++) {
            StructLib.SecTokenBatch storage batch = ld._batches[ts_preview.batchIds[i]];
            ts_preview.TC += uint256(batch.origCcyFee_percBips_ExFee);
        }
        ts_preview.TC_capped = ts_preview.TC;
        if (ts_preview.TC_capped > 10000) ts_preview.TC_capped = 10000; // cap

        // calc each batch's share of total bips and of capped bips
        for (uint i = 0; i < ts_preview.batchCount ; i++) {
            StructLib.SecTokenBatch storage batch = ld._batches[ts_preview.batchIds[i]];

            // batch share of total qty sent - pro-rata with qty sent
            uint256 batch_exFee_ccy = (((ts_preview.transferQty[i] * 1000000/*increase precision*/) / tot_qty) * tot_exFee_ccy) / 1000000/*decrease precision*/;

            // batch fee - capped share of exchange ccy fee
            uint256 BFEE = (((uint256(batch.origCcyFee_percBips_ExFee) * 1000000/*increase precision*/) / 10000/*basis points*/) * batch_exFee_ccy) / 1000000/*decrease precision*/;

            // currency fee transfer: from exchange owner account to batch originator
            StructLib.transferCcy(ld, StructLib.TransferCcyArgs({ from: feeAddrOwner, to: batch.originator, ccyTypeId: ccyTypeId, amount: BFEE, transferType: StructLib.TransferType.OriginatorFee }));
        }
    }

    //
    // INTERNAL - transfer (split/merge) tokens
    //
    struct TransferSplitArgs {
        address                from;
        address                to;
        uint256                tokTypeId;
        uint256                qtyUnit;
        StructLib.TransferType transferType;
        uint256                maxStId;
        uint256[]              k_stIds_take; // IFF len>0: only use these specific tokens (skip any others)
      //uint256[]              k_stIds_skip; // IFF len>0: don't use these specific tokens (use any others) -- UNUSED, CAN REMOVE
    }
    struct TransferSpltVars {
        uint256 ndx;
        int64   remainingToTransfer;
        bool    mergedExisting;
        int64   stQty;
    }
    function transferSplitSecTokens(
        StructLib.LedgerStruct storage ld,
        TransferSplitArgs memory       a
    )
    private returns (uint256 updatedMaxStId) {

        uint256[] storage from_stIds = ld._ledger[a.from].tokenType_stIds[a.tokTypeId];
        uint256[] storage to_stIds = ld._ledger[a.to].tokenType_stIds[a.tokTypeId];

        // walk tokens - transfer sufficient STs (last one may get split)
        TransferSpltVars memory v;
        require(a.qtyUnit >= 0 && a.qtyUnit <= 0x7FFFFFFFFFFFFFFF, "Bad qtyUnit"); // max signed int64
        v.remainingToTransfer = int64(uint64(a.qtyUnit));

        uint256 maxStId = a.maxStId;
        while (v.remainingToTransfer > 0) {
            uint256 stId = from_stIds[v.ndx];
            v.stQty = ld._sts[stId].currentQty;
            // Certik: (Minor) TRA-02 | Potentially Negative Quantity The v.stQty value may be negative within the transferSplitSecTokens function
            // Resolved: (Minor) TRA-02 | Added a check to ensure only non-negative values of v.stQty
            require(v.stQty >= 0, "Unexpected stQty");

            // if specific avoid (skip) tokens are specified, then skip them;
            // and inverse - if specific use (take) tokens are specified, then skip over others
            bool skip = false;
            // if (a.k_stIds_skip.length > 0) {
            //     for (uint256 i = 0; i < a.k_stIds_skip.length; i++) {
            //         if (a.k_stIds_skip[i] == stId) { skip = true; break; }
            //     }
            // }
            if (a.k_stIds_take.length > 0) {
                skip = true;
                for (uint256 i = 0; i < a.k_stIds_take.length; i++) {
                    if (a.k_stIds_take[i] == stId) { skip = false; break; } // i.e. take wins over skip (if same STID is specified in both take and skip list)
                }
            }
            if (skip) {
                v.ndx++;
            }
            else {
                if (v.remainingToTransfer >= v.stQty) { // reassign the FULL ST across the ledger entries

                    // remove from origin ledger - replace hot index 0 with value at last (ndx++, in effect)
                    from_stIds[v.ndx] = from_stIds[from_stIds.length - 1];
                    from_stIds.pop(); // solc 0.6

                    // assign to destination
                    //  IFF minting >1 ST is disallowed AND
                    //  IFF validation of available qty's is already performed,
                    //  THEN the merge condition below *** wrt. batchId can *never* be true:
                        
                    // MERGE - if any existing destination ST is from same batch
                    v.mergedExisting = false;
                    for (uint i = 0; i < to_stIds.length; i++) {
                        if (ld._sts[to_stIds[i]].batchId == ld._sts[stId].batchId) {
                            // resize (grow) the destination global ST
                            ld._sts[to_stIds[i]].currentQty += v.stQty; // PACKED
                            ld._sts[to_stIds[i]].mintedQty += v.stQty; // PACKED

                            // v1.1b - FIX: resize (shrink) the source global ST
                            ld._sts[stId].currentQty -= v.stQty;
                            ld._sts[stId].mintedQty -= v.stQty;
                            
                            v.mergedExisting = true;
                            emit TransferedFullSecToken(a.from, a.to, stId, to_stIds[i], uint256(uint64(v.stQty)), a.transferType);
                            break;
                        }
                    }
                    // TRANSFER - if no existing destination ST from same batch
                    if (!v.mergedExisting) {
                        to_stIds.push(stId);
                        emit TransferedFullSecToken(a.from, a.to, stId, 0, uint256(uint64(v.stQty)), a.transferType);
                    }

                    v.remainingToTransfer -= v.stQty;
                    if (v.remainingToTransfer > 0) {
                        require(from_stIds.length > 0, "Insufficient tokens");
                    }
                }
                else { // move PART of an ST across the ledger entries

                    // SPLIT the ST across the ledger entries, soft-minting a new ST in the destination
                    // note: the parent (origin) ST's minted qty also gets split across the two STs;
                    //         this is so the total minted in the system is unchanged,
                    //           (and also so the total burned amount in the ST can still be calculated by mintedQty[x] - currentQty[x])

                    // assign new ST to destination

                        // MERGE - if any existing destination ST is from same batch
                        v.mergedExisting = false;
                        for (uint i = 0; i < to_stIds.length; i++) {
                            if (ld._sts[to_stIds[i]].batchId == ld._sts[stId].batchId) {

                                // resize (grow) the destination ST
                                ld._sts[to_stIds[i]].currentQty += v.remainingToTransfer; // PACKED
                                ld._sts[to_stIds[i]].mintedQty += v.remainingToTransfer; // PACKED

                                v.mergedExisting = true;
                                emit TransferedPartialSecToken(a.from, a.to, stId, 0, to_stIds[i], uint256(uint64(v.remainingToTransfer)), a.transferType);
                                break;
                            }
                        }
                        // SOFT-MINT - if no existing destination ST from same batch; inherit batch ID from parent ST
                        if (!v.mergedExisting) {
                            ld._sts[maxStId + 1].batchId = ld._sts[stId].batchId; // PACKED
                            ld._sts[maxStId + 1].currentQty = v.remainingToTransfer; // PACKED
                            ld._sts[maxStId + 1].mintedQty = v.remainingToTransfer; // PACKED

                            to_stIds.push(maxStId + 1); // gas: 94k
                            emit TransferedPartialSecToken(a.from, a.to, stId, maxStId + 1, 0, uint256(uint64(v.remainingToTransfer)), a.transferType); // gas: 11k
                            maxStId++;
                        }

                    // resize (shrink) the origin ST
                    ld._sts[stId].currentQty -= v.remainingToTransfer; // PACKED
                    ld._sts[stId].mintedQty -= v.remainingToTransfer; // PACKED

                    v.remainingToTransfer = 0;
                }
            } // !skip
        } // while
        return maxStId;
    }

    //
    // INTERNAL - token transfer preview
    //
    /**
     * @dev Previews token transfer across ledger owners
     * @param a TransferSplitArgs args
     * @return The distinct transfer-from batch IDs and the total quantity of tokens that would be transfered from each batch
     */
    struct TransferSplitPreviewReturn {
        uint64[MAX_BATCHES_PREVIEW]  batchIds; // todo: pack these - quadratic gas cost for fixed memory
        uint256[MAX_BATCHES_PREVIEW] transferQty;
        uint256                      batchCount;

        // calc fields for batch originator ccy fee - % of exchange currency fee
        uint256                      TC;        // total cut        - sum originator batch origCcyFee_percBips_ExFee for all batches
        uint256                      TC_capped; // total cut capped - capped (10000 bps) total cut
    }
    function transferSplitSecTokens_Preview(
        StructLib.LedgerStruct storage ld,
        TransferSplitArgs memory       a
    )
    private view returns(TransferSplitPreviewReturn memory ret)
    {
        // init ret - grotesque, but can't return (or have as local var) a dynamic array
        uint64[MAX_BATCHES_PREVIEW] memory batchIds;
        uint256[MAX_BATCHES_PREVIEW] memory transferQty;
        ret = TransferSplitPreviewReturn({
               batchIds: batchIds,
            transferQty: transferQty,
             batchCount: 0,
                     TC: 0,
              TC_capped: 0
        });

        // get distinct batches affected - needed for fixed-size return array declaration
        uint256[] memory from_stIds = ld._ledger[a.from].tokenType_stIds[a.tokTypeId]; // assignment of storage[] to memory[] is a copy
        require(from_stIds.length > 0, "No tokens");

        uint256 ndx = 0;
        uint256 from_stIds_length = from_stIds.length;
        require(a.qtyUnit >= 0 && a.qtyUnit <= 0x7FFFFFFFFFFFFFFF, "Bad qtyUnit"); // max signed int64
        int64 remainingToTransfer = int64(uint64(a.qtyUnit));
        while (remainingToTransfer > 0) {
            uint256 stId = from_stIds[ndx];
            int64 stQty = ld._sts[stId].currentQty;
            uint64 fromBatchId = ld._sts[stId].batchId;

            bool skip = false;
            // if (a.k_stIds_skip.length > 0) {
            //     for (uint256 i = 0; i < a.k_stIds_skip.length; i++) {
            //         if (a.k_stIds_skip[i] == stId) { skip = true; break; }
            //     }
            // }
            if (a.k_stIds_take.length > 0) {
                skip = true;
                for (uint256 i = 0; i < a.k_stIds_take.length; i++) {
                    if (a.k_stIds_take[i] == stId) { skip = false; break; }
                }
            }
            if (skip) {
                ndx++;
            }
            else {
                // add to list of distinct batches, maintain transfer quantity from each batch
                bool knownBatch = false;
                for (uint i = 0; i < ret.batchCount; i++) {
                    if (ret.batchIds[i] == fromBatchId) {
                        ret.transferQty[i] += uint256(remainingToTransfer >= stQty ? uint64(stQty) : uint64(remainingToTransfer));
                        knownBatch = true;
                        break;
                    }
                }
                if (!knownBatch) {
                    require(ret.batchCount < MAX_BATCHES_PREVIEW, "Too many batches: try sending a smaller amount");
                    ret.batchIds[ret.batchCount] = fromBatchId;
                    ret.transferQty[ret.batchCount] = uint256(remainingToTransfer >= stQty ? uint64(stQty) : uint64(remainingToTransfer));
                    ret.batchCount++;
                }
                if (remainingToTransfer >= stQty) { // full ST transfer, and more needed

                    from_stIds[ndx] = from_stIds[from_stIds_length - 1]; // replace in origin copy (ndx++, in effect)
                    //from_stIds.length--;  // memory array can't be resized
                    from_stIds_length--;    // so instead

                    remainingToTransfer -= stQty;
                    if (remainingToTransfer > 0) {
                        require(from_stIds_length > 0, "Insufficient tokens");
                    }
                }
                else { // partial ST transfer, and no more needed
                    remainingToTransfer = 0;
                }
            }
        }
        return ret;
    }

    //
    // INTERNAL - fee calculations
    //
    /**
     * @notice Calculates capped & collared { fixed + basis points + fixed per Million consideration = total fee } based on the supplied fee structure
     * @param feeStructure Token or currency type fee structure mapping
     * @param sendAmount Amount being sent (token quantity or currency value)
     * @param receiveAmount Consideration value (tokens or currency) being received in return (if any)
     * @return totalFee Capped or collared fee
     */
    function calcFeeWithCapCollar(
        StructLib.SetFeeArgs storage feeStructure,
        uint256 sendAmount,
        uint256 receiveAmount
    )
    private view returns(uint256 totalFee) {
        uint256 feeA = applyFeeStruct(feeStructure, sendAmount, receiveAmount);
        return feeA;
    }

    function applyFeeStruct(
        StructLib.SetFeeArgs storage fs,
        uint256 sendAmount,
        uint256 receiveAmount
    )
    private view returns(uint256 totalFee) {
        uint256 feeAmount = fs.fee_fixed +
                    (((receiveAmount * 1000000000/*increase precision*/ / 1000000/*per million*/) * fs.ccy_perMillion) / 1000000000/*decrease precision*/) +
                    (((sendAmount * 1000000/*increase precision*/ / 10000/*basis points*/) * fs.fee_percBips) / 1000000/*decrease precision*/);
        if (sendAmount > 0) {
            if (feeAmount > fs.fee_max && fs.fee_max > 0) return fs.fee_max;
            if (feeAmount < fs.fee_min && fs.fee_min > 0) return fs.fee_min;
        }
        return feeAmount;
    }

    //
    // INTERNAL - param validation: security token IDs
    //
    function checkStIds(StructLib.LedgerStruct storage ld, StructLib.TransferArgs memory a) private view {
        if (a.k_stIds_A.length > 0) {
            uint256 stQty;
            for (uint256 i = 0; i < a.k_stIds_A.length; i++) {
                require(StructLib.tokenExistsOnLedger(ld, a.tokTypeId_A, a.ledger_A, a.k_stIds_A[i]), "Bad stId A");
                stQty += uint256(uint64(ld._sts[a.k_stIds_A[i]].currentQty));
            }
            //require(stQty == a.qty_A, "qty_A / k_stIds_A mismatch");
        }
        if (a.k_stIds_B.length > 0) {
            uint256 stQty;
            for (uint256 i = 0; i < a.k_stIds_B.length; i++) {
                require(StructLib.tokenExistsOnLedger(ld, a.tokTypeId_B, a.ledger_B, a.k_stIds_B[i]), "Bad stId B");
                stQty += uint256(uint64(ld._sts[a.k_stIds_B[i]].currentQty));
            }
            //require(stQty == a.qty_B, "qty_B / k_stIds_B mismatch");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// https://github.com/Arachnid/solidity-stringutils
// https://github.com/tokencard/contracts/blob/master/contracts/externals/strings.sol

/*
 * Copyright 2016 Nick Johnson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

// SPDX-License-Identifier: ApacheV2

pragma solidity >=0.5.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint length) internal pure {
        // Copy word-length chunks while possible
        for(; length >= 32; length -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - length) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = type(uint256).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++) {
            length += parts[i]._len;
        }

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for (uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../Interfaces/StructLib.sol";

import "../StMaster/StMaster.sol";

library SpotFeeLib {
    event SetFeeTokFix(uint256 tokTypeId, address indexed ledgerOwner, uint256 fee_tokenQty_Fixed);
    event SetFeeCcyFix(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_Fixed);
    event SetFeeTokBps(uint256 tokTypeId, address indexed ledgerOwner, uint256 fee_token_PercBips);
    event SetFeeCcyBps(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_PercBips);
    event SetFeeTokMin(uint256 tokTypeId, address indexed ledgerOwner, uint256 fee_token_Min);
    event SetFeeCcyMin(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_Min);
    event SetFeeTokMax(uint256 tokTypeId, address indexed ledgerOwner, uint256 fee_token_Max);
    event SetFeeCcyMax(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_Max);
    event SetFeeCcyPerMillion(uint256 ccyTypeId, address indexed ledgerOwner, uint256 fee_ccy_perMillion);

    function setFee_TokType(
        StructLib.LedgerStruct storage ld,
        StructLib.StTypesStruct storage std,
        StructLib.FeeStruct storage globalFees,
        uint256 tokTypeId,
        address ledgerOwner,
        StructLib.SetFeeArgs memory a)
    public {
        require(tokTypeId >= 1 && tokTypeId <= std._tt_Count, "Bad tokTypeId");
        require(std._tt_settle[tokTypeId] == StructLib.SettlementType.SPOT, "Bad token settlement type");
        require(a.ccy_perMillion == 0, "ccy_perMillion unsupported for token-type fee");
        require(a.ccy_mirrorFee == false, "ccy_mirrorFee unsupported for token-type fee");

        StructLib.FeeStruct storage feeStruct = globalFees;
        if (ledgerOwner != address(0x0)) {
            StructLib.initLedgerIfNew(ld, ledgerOwner);

            feeStruct = ld._ledger[ledgerOwner].spot_customFees;
        }

        feeStruct.tokType_Set[tokTypeId] = a.fee_fixed != 0 || a.fee_percBips != 0 || a.fee_min != 0 || a.fee_max != 0;

        // Certik: (Minor) SFL-01 | Potentially Incorrect Clauses The linked if clauses emit an event when the value is being set, however, they do so when the value is simply non-zero rendering the first conditional questionable.
        // The original intent here was: to emit event if a fee is SET, or UNSET, *or if it's SET repeatedly* to the same value
        // But, maybe that's not a good idea. So instead, let's emit only if the fee value *changes*
        if (feeStruct.tok[tokTypeId].fee_fixed != a.fee_fixed)// || a.fee_fixed != 0)
            emit SetFeeTokFix(tokTypeId, ledgerOwner, a.fee_fixed);
        feeStruct.tok[tokTypeId].fee_fixed = a.fee_fixed;

        if (feeStruct.tok[tokTypeId].fee_percBips != a.fee_percBips)// || a.fee_percBips != 0)
            emit SetFeeTokBps(tokTypeId, ledgerOwner, a.fee_percBips);
        feeStruct.tok[tokTypeId].fee_percBips = a.fee_percBips;

        if (feeStruct.tok[tokTypeId].fee_min != a.fee_min)// || a.fee_min != 0)
            emit SetFeeTokMin(tokTypeId, ledgerOwner, a.fee_min);
        feeStruct.tok[tokTypeId].fee_min = a.fee_min;

        if (feeStruct.tok[tokTypeId].fee_max != a.fee_max)// || a.fee_max != 0)
            emit SetFeeTokMax(tokTypeId, ledgerOwner, a.fee_max);
        feeStruct.tok[tokTypeId].fee_max = a.fee_max;

        if (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER) {
            StMaster base = StMaster(std._tt_addr[tokTypeId]);
            base.setFee_TokType(tokTypeId,ledgerOwner, a);
        }
    }

    function setFee_CcyType(
        StructLib.LedgerStruct storage ld,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.FeeStruct storage globalFees,
        uint256 ccyTypeId,
        address ledgerOwner,
        StructLib.SetFeeArgs memory a)
    public {
        require(ccyTypeId >= 1 && ccyTypeId <= ctd._ct_Count, "Bad ccyTypeId");

        StructLib.FeeStruct storage feeStruct = globalFees;
        if (ledgerOwner != address(0x0)) {
            StructLib.initLedgerIfNew(ld, ledgerOwner);

            feeStruct = ld._ledger[ledgerOwner].spot_customFees;
        }

        feeStruct.ccyType_Set[ccyTypeId] = a.fee_fixed != 0 || a.fee_percBips != 0 || a.fee_min != 0 || a.fee_max != 0 || a.ccy_perMillion != 0;

        if (feeStruct.ccy[ccyTypeId].fee_fixed != a.fee_fixed)// || a.fee_fixed != 0)
            emit SetFeeCcyFix(ccyTypeId, ledgerOwner, a.fee_fixed);
        feeStruct.ccy[ccyTypeId].fee_fixed = a.fee_fixed;

        if (feeStruct.ccy[ccyTypeId].fee_percBips != a.fee_percBips)// || a.fee_percBips != 0)
            emit SetFeeCcyBps(ccyTypeId, ledgerOwner, a.fee_percBips);
        feeStruct.ccy[ccyTypeId].fee_percBips = a.fee_percBips;

        if (feeStruct.ccy[ccyTypeId].fee_min != a.fee_min)// || a.fee_min != 0)
            emit SetFeeCcyMin(ccyTypeId, ledgerOwner, a.fee_min);
        feeStruct.ccy[ccyTypeId].fee_min = a.fee_min;

        if (feeStruct.ccy[ccyTypeId].fee_max != a.fee_max)// || a.fee_max != 0)
            emit SetFeeCcyMax(ccyTypeId, ledgerOwner, a.fee_max);
        feeStruct.ccy[ccyTypeId].fee_max = a.fee_max;

        if (feeStruct.ccy[ccyTypeId].ccy_perMillion != a.ccy_perMillion)// || a.ccy_perMillion != 0)
            emit SetFeeCcyPerMillion(ccyTypeId, ledgerOwner, a.ccy_perMillion);
        feeStruct.ccy[ccyTypeId].ccy_perMillion = a.ccy_perMillion;

        // urgh ^2
        feeStruct.ccy[ccyTypeId].ccy_mirrorFee = a.ccy_mirrorFee;
    }
}

// Author: https://github.com/7-of-9
// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../Interfaces/StructLib.sol";
import "../Interfaces/IChainlinkAggregator.sol";

import "./TransferLib.sol";

library PayableLib {


    event IssuanceSubscribed(address indexed subscriber, address indexed issuer, uint256 weiSent, uint256 weiChange, uint256 tokensSubscribed, uint256 weiPrice);

    event IssuerPaymentProcessed(uint32 indexed paymentId, address indexed issuer, uint256 totalAmount, uint32 totalBatchCount);
    event IssuerPaymentBatchProcessed(uint32 indexed paymentId, uint32 indexed paymentBatchId, address indexed issuer, uint256 weiSent, uint256 weiChange);
    event SubscriberPaid(uint32 indexed paymentId, uint32 indexed paymentBatchId, address indexed issuer, address subscriber, uint256 amount);

    function get_chainlinkRefPrice(address chainlinkAggAddr) public view returns(int256 price) {
        //if (chainlinkAggAddr == address(0x0)) return 100000000; // $1 - cents*satoshis
        if (chainlinkAggAddr == address(0x0)) return -1;
        // Certik: (Major) ICA-01 | Incorrect Chainlink Interface
        // Resolved: (Major) ICA-01 | Upgraded Chainlink Aggregator Interface to V3
        
        // Updated: checking staleness values coming back from latestRoundData() based on a timer
        uint256 updatedAt;
        uint256 delayInSeconds = 120 * 60; // 2 hours
        IChainlinkAggregator ref = IChainlinkAggregator(chainlinkAggAddr);
        ( , price, , updatedAt, ) = ref.latestRoundData();
        require(updatedAt > (block.timestamp - delayInSeconds), "Chainlink: stale price");
    }

    function setIssuerValues(
        StructLib.LedgerStruct storage ld,
        StructLib.CashflowStruct storage cashflowData,
        uint256 wei_currentPrice,
        uint256 cents_currentPrice,
        uint256 qty_saleAllocation,
        address owner
    ) public {
        require(ld._contractSealed, "Contract is not sealed");

        require(ld._batches_currentMax_id == 1, "Bad cashflow request: no minted batch");
        StructLib.SecTokenBatch storage issueBatch = ld._batches[1]; // CFT: uni-batch

        require(msg.sender == issueBatch.originator || msg.sender == owner, "Bad cashflow request: access denied");

        // qty_saleAllocation is the *cummulative* amount allowable for sale;
        // i.e. it can't be set < the currently sold amount, and it can't be set > the total issuance uni-batch size
        StructLib.CashflowStruct memory current = getCashflowData(ld, cashflowData);
        require(qty_saleAllocation <= current.qty_issuanceMax, "Bad cashflow request: qty_saleAllocation too large");
        require(qty_saleAllocation >= current.qty_issuanceSold, "Bad cashflow request: qty_saleAllocation too small");

        // price is either in eth or in usd
        require(cents_currentPrice == 0 && wei_currentPrice > 0 || cents_currentPrice > 0 && wei_currentPrice == 0, "Bad cashflow request: price either in USD or ETH");

        // we require a fixed price for bonds, because price paid is used to determine the interest due;
        // (we could have variable pricing, but only at the cost of copying the price paid into the token structure)
        if (cashflowData.args.cashflowType == StructLib.CashflowType.BOND) {
            if (wei_currentPrice > 0 &&
                ((cashflowData.wei_currentPrice != wei_currentPrice && cashflowData.wei_currentPrice != 0) ||
                 cashflowData.cents_currentPrice > 0)) {
                revert("Bad cashflow request: cannot change price for bond once set");
            }
            if (cents_currentPrice > 0 &&
                (cashflowData.wei_currentPrice > 0 ||
                 (cashflowData.cents_currentPrice != cents_currentPrice && cashflowData.cents_currentPrice != 0))) {
                revert("Bad cashflow request: cannot change price for bond once set");
            }
        }

        cashflowData.qty_saleAllocation = qty_saleAllocation;
        cashflowData.wei_currentPrice = wei_currentPrice;
        cashflowData.cents_currentPrice = cents_currentPrice;
    }

    // v1: multi-sub
    function pay(
        StructLib.LedgerStruct storage ld,
        StructLib.StTypesStruct storage std,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.CashflowStruct storage cashflowData,
        StructLib.FeeStruct storage globalFees, address owner,
        int256 ethSat_UsdCents,
        int256 bnbSat_UsdCents
    )
    public {
        require(ld.contractType == StructLib.ContractType.CASHFLOW_BASE, "Bad commodity request");
        require(ld._contractSealed, "Contract is not sealed");
        require(ld._batches_currentMax_id == 1, "Bad cashflow request: no minted batch");
        require(cashflowData.wei_currentPrice > 0 || cashflowData.cents_currentPrice > 0, "Bad cashflow request: no price set");
        require(cashflowData.wei_currentPrice == 0 || cashflowData.cents_currentPrice == 0, "Bad cashflow request: ambiguous price set");
        if (cashflowData.cents_currentPrice > 0) {
            require(ethSat_UsdCents != -1 || bnbSat_UsdCents != -1, "Bad usd/{eth|bnb} rate");
        }
        // get issuer
        StructLib.SecTokenBatch storage issueBatch = ld._batches[1];
        require(msg.sender != issueBatch.originator, "Issuer cannot subscribe");
        
        processSubscriberPayment(ld, std, ctd, cashflowData, issueBatch, globalFees, owner, ethSat_UsdCents, bnbSat_UsdCents);
    }

    struct ProcessPaymentVars {
        uint256 weiPrice;
        uint256 qtyTokens;
        uint256[] issuer_stIds; //storage
        StructLib.PackedSt issuerSt; //storage
        //uint256 qtyIssuanceSold;
        uint256 weiChange;
    }

    // Certik: (Medium) PLL-02 | Inexistent Reentrancy Guard - A detailed analysis on the vulnerability required from Certik
    // Review: Use a standard modifier to prevent re-entrancy; 
    // Ankur: Added an OpenZeppelin ReentrancyGuard on StPayable with a standard nonReentrant() modifier
    function processSubscriberPayment(
        StructLib.LedgerStruct storage ld,
        StructLib.StTypesStruct storage std,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.CashflowStruct storage cashflowData,
        StructLib.SecTokenBatch storage issueBatch,
        StructLib.FeeStruct storage globalFees,
        address owner,
        int256 ethSat_UsdCents,
        int256 bnbSat_UsdCents
    )
    private {
        ProcessPaymentVars memory v;

        require(cashflowData.qty_saleAllocation > 0, "Nothing for sale");

        require(msg.value > 0 && msg.value <= type(uint256).max, "Bad msg.value");

        if (cashflowData.wei_currentPrice > 0) {
            v.weiPrice = cashflowData.wei_currentPrice;
        }
        else {
            require(ethSat_UsdCents != -1 || bnbSat_UsdCents != -1, "Bad usd/{eth|bnb} rate");
            if (ethSat_UsdCents != -1) { // use uth/usd rate (ETH Ropsten, mainnet)
                v.weiPrice = (cashflowData.cents_currentPrice * 10 ** 24) / (uint256(ethSat_UsdCents));
            }
            else if (bnbSat_UsdCents != -1) { // use bnb/usd rate (BSC Mainnet 56 & Testnet 97)
                v.weiPrice = (cashflowData.cents_currentPrice * 10 ** 24) / (uint256(bnbSat_UsdCents));
            }
        }

        // check if weiPrice is set
        require(v.weiPrice > 0, "Bad computed v.weiPrice");

        // calculate subscription size
        v.qtyTokens = msg.value / v.weiPrice; // ## explicit round DOWN

        // check sale allowance is not exceeded
        v.issuer_stIds = ld._ledger[issueBatch.originator].tokenType_stIds[1]; // CFT: uni-type
        v.issuerSt = ld._sts[v.issuer_stIds[0]];
        //v.qtyIssuanceSold = uint256(issueBatch.mintedQty).sub(uint256(v.issuerSt.currentQty)); // ##
        require(cashflowData.qty_saleAllocation >= 
            cashflowData.qty_issuanceSold //v.qtyIssuanceSold 
            + v.qtyTokens, "Bad cashflow request: insufficient quantity for sale");

        // send change back to payer
        v.weiChange = msg.value % v.weiPrice; // explicit remainder -- keep 10 Wei in the contract, tryfix...
        if (v.weiChange > 0) {
            payable(msg.sender).transfer(v.weiChange); // payable used in solidity version 0.8.0 onwards
        }

        // fwd payment to issuer
        issueBatch.originator.transfer(msg.value - v.weiChange);

        // transfer tokens to payer
        if (v.qtyTokens > 0) {
            StructLib.TransferArgs memory a = StructLib.TransferArgs({
                    ledger_A: issueBatch.originator,
                    ledger_B: msg.sender,
                       qty_A: v.qtyTokens,
                   k_stIds_A: new uint256[](0),
                 tokTypeId_A: 1,
                       qty_B: 0,
                   k_stIds_B: new uint256[](0),
                 tokTypeId_B: 0,
                ccy_amount_A: 0,
                 ccyTypeId_A: 0,
                ccy_amount_B: 0,
                 ccyTypeId_B: 0,
                   applyFees: false,
                feeAddrOwner: owner,
                transferType: StructLib.TransferType.Subscription
            });
            TransferLib.transferOrTrade(ld, std, ctd, globalFees, a);
            cashflowData.qty_issuanceSold += v.qtyTokens;
        }

        // todo: issuance fees (set then clear ledgerFee?)
        // todo: record subscribers? or no need - only care about holders? (ledgers != issuer)

        emit IssuanceSubscribed(msg.sender, issueBatch.originator, msg.value, v.weiChange, v.qtyTokens, v.weiPrice);
    }

    /*
        FIXED ISSUANCE / ONGOING SALE MODEL

        I = Issuer - minted to I's account initially
        B# = amount minted in batch; total is fixed - no subsequent issuances
            S# = amount currently sold (subscribed) from B#
            I# = amount of B# remaining with issuer (B# - S#)

        args: P = price [EQUITY can edit, write-once for BOND]
              R = rate [only for BOND]
             SQ = sale quantity [EQUITY and BOND can edit]

        Issuer can at any time set SQ to 0 to stop ongoing sale.
        Issuer can at any time set SQ to any value <= I# - offers some or all of his holdings to the market.
        EQUITY Issuer can at any time set P to a higher or lower value - equivalent to a valuation up or down round.

        if (BOND) { // interest payments... (todo - principal repayments...)
            reject if Qty < required
                (required = S# * P * R) // P is fixed for BOND for this reason
            pro rata over S# // i.e. only paid-up bond holders receive
        }
        if (EQUITY) { // dividend payments...
            accept any amount!
            pro rata over S# && I# // i.e. equity issuer receives pro-rata on the unsold portion of B#
        }
    */

    struct ProcessIssuerPaymentBatchVars {
        uint256 amountSubscribed;
        uint32 initAddrNdx;
        uint32 addrNdx;
        uint32 stNdx;
        uint256 sharePercentage;
        uint256 shareWei;
        uint256 batchProcessedAmount;
        uint256 weiChange;
    }

    // TODO: ### caller needs to be able to specify a batch / offset (~5m gas / ~23k transfer per holder ~= 250 max holders!!)

    function issuerPay(
        uint32 count,
        StructLib.IssuerPaymentBatchStruct storage ipbd,
        StructLib.LedgerStruct storage ld,
        StructLib.CashflowStruct storage cashflowData
    )
    public {

        require(ld.contractType == StructLib.ContractType.CASHFLOW_BASE, 'Bad commodity request');
        require(ld._contractSealed, 'Contract is not sealed');
        require(ld._batches_currentMax_id == 1, 'Bad cashflow request: no minted batch');
        // Certik: (Medium) PLL-03 | Incorrect Limit Evaluation
        // Resolved: (Medium) PLL-03 | Corrected the overflow check
        require(msg.value <= uint256(type(uint128).max), 'Amount must be less than 2^128'); // stop any overflows
        require(count > 0, 'Invalid count');
        
        // get issuer
        StructLib.SecTokenBatch storage issueBatch = ld._batches[1];  // CFT: uni-batch
        require(msg.sender == issueBatch.originator, 'Issuer payments: only by issuer');

        // validate subscribers
        require(ld._ledgerOwners.length > 1, 'No Subscribers found for the Cashflow Token'); // > 1 to exclude issuer

        // validate count
        require(ipbd.curNdx + count <= ld._ledgerOwners.length, 'Count must be < remaining token holders in the payment batch');

        // disallow extra payments
        require(ipbd.curPaymentProcessedAmount <= ipbd.curPaymentTotalAmount, 'Extra payment(s) have been processed');

        // initialize new payment
        if (ipbd.curNdx == 0) {
            require(ipbd.curPaymentTotalAmount == 0, 'New payment initialization error: Reset Payment Total Amount');
            ipbd.curPaymentId++;                    // initiate paymentId for a new payment (1-based)
            ipbd.curPaymentTotalAmount = msg.value; // caller should pass the entire payment amount on the first batch of a new payment
        }

        ProcessIssuerPaymentBatchVars memory ipv;

        uint256[] storage issuer_stIds = ld._ledger[issueBatch.originator].tokenType_stIds[1];
        StructLib.PackedSt storage issuerSt = ld._sts[issuer_stIds[0]];

        ipv.amountSubscribed = uint256(issueBatch.mintedQty) - uint256(uint64(issuerSt.currentQty)); // ## breaks when we do transfers from the issuer ??

        if (cashflowData.args.cashflowType == StructLib.CashflowType.BOND) {
            
            ipv.initAddrNdx = ipbd.curNdx;

            for (ipv.addrNdx = ipv.initAddrNdx; ipv.addrNdx < ipv.initAddrNdx + count ; ipv.addrNdx++) {
                address payable addr = payable(address(uint160(ld._ledgerOwners[ipv.addrNdx]))); // payable used in solidity version 0.8.0 onwards
                
                if (addr != issueBatch.originator) { // exclude issuer from payments
                    uint256[] storage stIds = ld._ledger[addr].tokenType_stIds[1];

                    for (ipv.stNdx = 0; ipv.stNdx < stIds.length; ipv.stNdx++) {
                        ipv.sharePercentage = ipv.amountSubscribed * 10 ** 36 / uint256(uint64(ld._sts[stIds[ipv.stNdx]].currentQty));
                        ipv.shareWei = ipbd.curPaymentTotalAmount * 10 ** 36 / ipv.sharePercentage;

                        // TODO: re-entrancy guards, and .call instead of .transfer
                        if (ipv.shareWei > 0) {
                            payable(addr).transfer(ipv.shareWei); // payable used in solidity version 0.8.0 onwards
                        }
                        // save payment history
                        ipv.batchProcessedAmount += ipv.shareWei;
                        ipbd.curPaymentProcessedAmount += ipv.shareWei;
                        emit SubscriberPaid(ipbd.curPaymentId, ipbd.curBatchNdx, issueBatch.originator, addr, ipv.shareWei);
                    }
                }
                ipbd.curNdx++;
            }
            ipv.weiChange = msg.value - uint256(ipv.batchProcessedAmount);
            if (ipv.weiChange > 0) {
                payable(msg.sender).transfer(ipv.weiChange); // payable used in solidity version 0.8.0 onwards
            }
            emit IssuerPaymentBatchProcessed(ipbd.curPaymentId, ipbd.curBatchNdx, msg.sender, msg.value, ipv.weiChange);
            ipbd.curBatchNdx++;
            if (ipbd.curPaymentProcessedAmount == ipbd.curPaymentTotalAmount){
                emit IssuerPaymentProcessed(ipbd.curPaymentId, msg.sender, ipbd.curPaymentTotalAmount, ipbd.curBatchNdx);
                resetIssuerPaymentBatch(ipbd);
            }
        }
        else if (cashflowData.args.cashflowType == StructLib.CashflowType.EQUITY) {
            // TODO: Dividend Payments
        }
        else revert("Unexpected cashflow type");
    }

    function resetIssuerPaymentBatch(StructLib.IssuerPaymentBatchStruct storage ipbd) internal {
        ipbd.curBatchNdx = 0;
        ipbd.curNdx = 0;
        ipbd.curPaymentTotalAmount = 0;
        ipbd.curPaymentProcessedAmount = 0;
    }

    function getCashflowData(
        StructLib.LedgerStruct storage ld,
        StructLib.CashflowStruct storage cashflowData
    )
    public view returns(StructLib.CashflowStruct memory) {
        StructLib.CashflowStruct memory ret = cashflowData;

        if (ld.contractType == StructLib.ContractType.CASHFLOW_BASE) {
            if (ld._batches_currentMax_id == 1) {
                StructLib.SecTokenBatch storage issueBatch = ld._batches[1]; // CFT: uni-batch
                uint256[] storage issuer_stIds = ld._ledger[issueBatch.originator].tokenType_stIds[1]; // CFT: uni-type
                StructLib.PackedSt storage issuerSt = ld._sts[issuer_stIds[0]];
                ret.qty_issuanceMax = issueBatch.mintedQty;

                ret.qty_issuanceRemaining = uint256(uint64(issuerSt.currentQty)); 

                // ## this fails if tokens are transferred out from the issuer (demo flow)
                // instead, we udpate this field directly on each issuance sale
                //ret.qty_issuanceSold = uint256(issueBatch.mintedQty) - uint256(issuerSt.currentQty); 

                ret.issuer = issueBatch.originator;
            }
        }
        return ret;
    }

    function getIssuerPaymentBatch(
        StructLib.IssuerPaymentBatchStruct storage issuerPaymentBatchData
    )
    public pure returns(StructLib.IssuerPaymentBatchStruct memory) {
        StructLib.IssuerPaymentBatchStruct memory ipbd = issuerPaymentBatchData;
        return ipbd;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../Interfaces/StructLib.sol";

library LoadLib {

    // Certik: (Minor) LOA-01 | Potentially Disjoint Variable The _batches_currentMax_id variable is set as an argument instead of calculated within the for loop that loads the tokens and is not sanitized
    // Resolved: (Minor) LOA-01 | Logically consistent with architectural design for contract upgrade
    function loadSecTokenBatch(
        StructLib.LedgerStruct storage ld,
        StructLib.SecTokenBatch[] memory batches,
        uint64 _batches_currentMax_id
    )
    public {
        // Certik: (Minor) LOA-07 | Inexistent Entry Check The loadSecTokenBatch performs no input sanitization in the batch assignments it performs
        // Resolved: (Minor) LOA-07 | Logically consistent with architectural design for contract upgrade
        require(!ld._contractSealed, "Contract is sealed");
        for (uint256 i = 0; i < batches.length; i++) {
            ld._batches[batches[i].id] = batches[i];
        }
        ld._batches_currentMax_id = _batches_currentMax_id;
    }

    function createLedgerEntry(
        StructLib.LedgerStruct storage ld,
        address ledgerEntryOwner,
        StructLib.LedgerCcyReturn[] memory ccys,
        uint256 spot_sumQtyMinted,
        uint256 spot_sumQtyBurned
    )
    public {
        require(!ld._contractSealed, "Contract is sealed");

        if (!ld._ledger[ledgerEntryOwner].exists) {
            ld._ledgerOwners.push(ledgerEntryOwner);
        }

        StructLib.Ledger storage entry = ld._ledger[ledgerEntryOwner];

        // Certik: (Minor) LOA-06 | Inexistent Initializaiton Check The ledger that is initialized within createLedgerEntry isn't validated to not exist already, potentially allowing previously set spot_sumQtyMinted and spot_sumQtyBurned values to be overwritten.
        // Resolved: (Minor) LOA-06 | Logically consistent with architectural design for contract upgrade
        entry.exists = true;
        entry.spot_sumQtyMinted = spot_sumQtyMinted;
        entry.spot_sumQtyBurned = spot_sumQtyBurned;

        // Certik: (Minor) LOA-03 | Inexistent Balance Sanitization The linked for loop does not sanitize the reserve member of ccys[i] to be less-than-or-equal-to the balance member.
        // Resolved: (Minor) LOA-03 | Logically consistent with architectural design for contract upgrade
        // Certik: LOA-04 | Lookup Optimization
        // Resolved (AD): Utilizing local variable to save gas cost in lookup
        for (uint256 i = 0 ; i < ccys.length ; i++) {
            uint256 ccyTypeId = ccys[i].ccyTypeId;
            ld._ledger[ledgerEntryOwner].ccyType_balance[ccyTypeId] = ccys[i].balance;
            ld._ledger[ledgerEntryOwner].ccyType_reserved[ccyTypeId] = ccys[i].reserved;
        }
    }
    // Certik: (Minor) LOA-05 | Inexistent Duplicate Check The addSecToken can overwrite over a currently present security token ID as no sanitization is performed to ensure the security token hasn't already been added.
    // Resolved: (Minor) LOA-05 | Logically consistent with architectural design for contract upgrade
    function addSecToken(
        StructLib.LedgerStruct storage ld,
        address ledgerEntryOwner,
        uint64 batchId, uint256 stId, uint256 tokTypeId, int64 mintedQty, int64 currentQty,
        int128 ft_price, int128 ft_lastMarkPrice, address ft_ledgerOwner, int128 ft_PL
    )
    public {
        require(!ld._contractSealed, "Contract is sealed");
        ld._sts[stId].batchId = batchId;
        ld._sts[stId].mintedQty = mintedQty;
        ld._sts[stId].currentQty = currentQty;
        ld._sts[stId].ft_price = ft_price;
        ld._sts[stId].ft_ledgerOwner = ft_ledgerOwner;
        ld._sts[stId].ft_lastMarkPrice = ft_lastMarkPrice;
        ld._sts[stId].ft_PL = ft_PL;

        // v1.1 bugfix
        // burned tokens don't exist against any ledger entry, (but do exist
        // on the master _sts global list); this conditional allows us to use the
        // null-address to correctly represent these burned tokens in the target contract
        if (ledgerEntryOwner != 0x0000000000000000000000000000000000000000) {  // v1.1 bugfix
            ld._ledger[ledgerEntryOwner].tokenType_stIds[tokTypeId].push(stId);
        }
    }

    function setTokenTotals(
        StructLib.LedgerStruct storage ld,
        //uint80 packed_ExchangeFeesPaidQty, uint80 packed_OriginatorFeesPaidQty, uint80 packed_TransferedQty,
        uint256 base_id,
        uint256 currentMax_id, uint256 totalMintedQty, uint256 totalBurnedQty
    )
    public {
        require(!ld._contractSealed, "Contract is sealed");

        ld._tokens_base_id = base_id;
        ld._tokens_currentMax_id = currentMax_id;
        ld._spot_totalMintedQty = totalMintedQty;
        ld._spot_totalBurnedQty = totalBurnedQty;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../Interfaces/StructLib.sol";

import "../StMaster/StMaster.sol";

library LedgerLib {

    //
    // PUBLIC - GET LEDGER ENTRY
    //
    // returns full ledger information for the suppled account;
    //  (in cashflow controller, delegates to cashflow base contracts' split ledgers for token counts)
    //
    struct GetLedgerEntryVars {
        StructLib.LedgerSecTokenReturn[] tokens;
        StructLib.LedgerCcyReturn[]      ccys;
        uint256                          spot_sumQty;
    }
    function getLedgerEntry(
        StructLib.LedgerStruct storage   ld,
        StructLib.StTypesStruct storage  std,
        StructLib.CcyTypesStruct storage ctd,
        address                          account
    )
    // Certik : LLL-06 | Explicitly returning local variable
    // Resolved (AD): Use of named return variables to reduce overall gas cost
    public view returns (StructLib.LedgerReturn memory ledgerEntry) {

        GetLedgerEntryVars memory v;

        // count total # of tokens (i.e. token count distinct by batch,type) across all types
        // Certik: LLL-02 | Redundant Variable Initialization
        // Resolved (AD): Removed redundant 0 initialization
        uint256 countAllSecTokens;
        StructLib.LedgerReturn[] memory baseLedgers;
        if (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER) { // controller: save/resuse base types' ledgers
            baseLedgers = new StructLib.LedgerReturn[](std._tt_Count);
        }
        for (uint256 tokTypeId = 1; tokTypeId <= std._tt_Count; tokTypeId++) {
            if (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER) { // controller: passthrough to base type
                StMaster base = StMaster(std._tt_addr[tokTypeId]);
                baseLedgers[tokTypeId - 1] = base.getLedgerEntry(account);
                // Certik: LLL-03 | Inefficient use of for loop
                // Resolved (AD): Replaced inefficient for loop by incrementing countAllSecTokens by baseLedgers[tokTypeId - 1].tokens.length
                countAllSecTokens += baseLedgers[tokTypeId - 1].tokens.length;
            }
            else {
                countAllSecTokens += ld._ledger[account].tokenType_stIds[tokTypeId].length;
            }
        }
        v.tokens = new StructLib.LedgerSecTokenReturn[](countAllSecTokens);

        // core & base: flatten STs (and sum total spot size)
        // Certik: LLL-02 | Redundant Variable Initialization
        // Resolved (AD): Removed redundant 0 initialization
        uint256 flatSecTokenNdx;
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) {
            for (uint256 tokTypeId = 1; tokTypeId <= std._tt_Count; tokTypeId++) { // get ST IDs & data from local storage
                uint256[] memory tokenType_stIds = ld._ledger[account].tokenType_stIds[tokTypeId];

                for (uint256 ndx = 0; ndx < tokenType_stIds.length; ndx++) {
                    uint256 stId = tokenType_stIds[ndx];

                    // sum ST sizes - convenience for caller - only applicable for spot (guaranteed +ve qty) token types
                    if (std._tt_settle[tokTypeId] == StructLib.SettlementType.SPOT) {
                        v.spot_sumQty += uint256(uint64(ld._sts[stId].currentQty));
                    }

                    // STs by type
                    v.tokens[flatSecTokenNdx] = StructLib.LedgerSecTokenReturn({
                             exists: ld._sts[stId].mintedQty != 0,
                               stId: stId,
                          tokTypeId: tokTypeId,
                        tokTypeName: std._tt_name[tokTypeId],
                            batchId: ld._sts[stId].batchId,
                          mintedQty: ld._sts[stId].mintedQty,
                         currentQty: ld._sts[stId].currentQty,
                           ft_price: ld._sts[stId].ft_price,
                     ft_ledgerOwner: ld._sts[stId].ft_ledgerOwner,
                   ft_lastMarkPrice: ld._sts[stId].ft_lastMarkPrice,
                              ft_PL: ld._sts[stId].ft_PL
                    });
                    flatSecTokenNdx++;
                }
            }
        }
        // controller: get STs from base ledger types (and sum total spot sizes across all types)
        else {
            for (uint256 tokTypeId = 1; tokTypeId <= std._tt_Count; tokTypeId++) { // get ST IDs & data from base types' storage
                StructLib.LedgerReturn memory baseLedger = baseLedgers[tokTypeId - 1];
                for (uint256 i = 0; i < baseLedger.tokens.length; i++) {
                    uint256 stId = baseLedger.tokens[i].stId;

                    if (std._tt_settle[tokTypeId] == StructLib.SettlementType.SPOT) {
                        v.spot_sumQty += uint256(uint64(baseLedger.tokens[i].currentQty));
                    }

                    v.tokens[flatSecTokenNdx] = StructLib.LedgerSecTokenReturn({
                             exists: baseLedger.tokens[i].exists,
                               stId: stId,                                  // controller/base value (common)
                          tokTypeId: tokTypeId,                             // controller value
                        tokTypeName: std._tt_name[tokTypeId],               // controller value
                            batchId: 0,                                     // controller value lookup below
                          mintedQty: baseLedger.tokens[i].mintedQty,        // base type value
                         currentQty: baseLedger.tokens[i].currentQty,       // "
                           ft_price: baseLedger.tokens[i].ft_price,         // "
                     ft_ledgerOwner: baseLedger.tokens[i].ft_ledgerOwner,   // "
                   ft_lastMarkPrice: baseLedger.tokens[i].ft_lastMarkPrice, // "
                              ft_PL: baseLedger.tokens[i].ft_PL             // "
                    });

                    // map/lookup return field: batchId - ASSUMES: only one batch per type in the controller (uni-batch/uni-mint model)
                    // Certik: LLL-05 | Inefficient storage read
                    // Resolved (AD): Utilized local variable to avoid multiple storage reads and save gas cost
                    uint256 currentMaxBatchId = uint256(ld._batches_currentMax_id);
                    for (uint256 batchId = 1; batchId <= currentMaxBatchId; batchId++) {
                        if (ld._batches[batchId].tokTypeId == tokTypeId) {
                            v.tokens[flatSecTokenNdx].batchId = uint64(batchId);
                            break;
                        }
                    }

                    flatSecTokenNdx++;
                }
            }
        }

        // common: populate balances for each currency type
        v.ccys = new StructLib.LedgerCcyReturn[](ctd._ct_Count);
        for (uint256 ccyTypeId = 1; ccyTypeId <= ctd._ct_Count; ccyTypeId++) {
            v.ccys[ccyTypeId - 1] = StructLib.LedgerCcyReturn({
                   ccyTypeId: ccyTypeId,
                        name: ctd._ct_Ccy[ccyTypeId].name,
                        unit: ctd._ct_Ccy[ccyTypeId].unit,
                     balance: ld._ledger[account].ccyType_balance[ccyTypeId],
                    reserved: ld._ledger[account].ccyType_reserved[ccyTypeId]
            });
        }

        ledgerEntry = StructLib.LedgerReturn({
             exists: ld._ledger[account].exists,
             tokens: v.tokens,
        spot_sumQty: v.spot_sumQty,
               ccys: v.ccys,
  spot_sumQtyMinted: ld._ledger[account].spot_sumQtyMinted,
  spot_sumQtyBurned: ld._ledger[account].spot_sumQtyBurned
        });
    }

    //
    // PUBLIC - GET LEDGER HASH
    //
    struct ConsistencyCheck {
        uint256 totalCur;
        uint256 totalMinted;
        uint256 totalTokensOnLedger;
    }
    function getLedgerHashcode(
        StructLib.LedgerStruct storage ld,
        StructLib.StTypesStruct storage std,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.Erc20Struct storage erc20d,
        //StructLib.CashflowStruct storage cashflowData,
        StructLib.FeeStruct storage globalFees,
        uint mod, uint n
    )
    // Certik : LLL-06 | Explicitly returning local variable
    // Resolved (AD): Use of named return variables to reduce overall gas cost
    public view returns (bytes32 ledgerHash) {

        // hash currency types & exchange currency fees
        for (uint256 ccyTypeId = 1; ccyTypeId <= ctd._ct_Count; ccyTypeId++) {
            if (ccyTypeId % mod != n) continue;
            
            StructLib.Ccy storage ccy = ctd._ct_Ccy[ccyTypeId];
            ledgerHash = keccak256(abi.encodePacked(ledgerHash,
                ccy.id, ccy.name, ccy.unit, ccy.decimals
            ));

            if (globalFees.ccyType_Set[ccyTypeId]) {
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, hashSetFeeArgs(globalFees.ccy[ccyTypeId])));
            }
        }

        // hash token types & exchange token fees
        // Certik: LLL-08 | Inefficient storage read
        // Resolved (AD): Utilized local variable to avoid multiple storage reads and save gas cost
        uint256 currentMaxTokenTypeId = std._tt_Count;
        for (uint256 stTypeId = 1; stTypeId <= currentMaxTokenTypeId; stTypeId++) {
            if (stTypeId % mod != n) continue;

            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_name[stTypeId]));
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_settle[stTypeId]));

            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_ft[stTypeId].expiryTimestamp));
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_ft[stTypeId].underlyerTypeId));
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_ft[stTypeId].refCcyId));
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_ft[stTypeId].initMarginBips));
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_ft[stTypeId].varMarginBips));
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_ft[stTypeId].contractSize));
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_ft[stTypeId].feePerContract));

            ledgerHash = keccak256(abi.encodePacked(ledgerHash, std._tt_addr[stTypeId])); // ? should exclude, to allow CFT-C to upgrade and point to upgraded base types?!

            if (globalFees.tokType_Set[stTypeId]) {
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, hashSetFeeArgs(globalFees.tok[stTypeId])));
            }
        }

        // hash whitelist
        // Certik: LLL-09 | Inefficient storage read
        // Resolved (AD): Utilized local variable to avoid multiple storage reads and save gas cost
        uint256 whiteListLength = erc20d._whitelist.length;
        for (uint256 whitelistNdx = 1; // exclude contract owner @ndx 0
            whitelistNdx < whiteListLength; whitelistNdx++) {

            if (whitelistNdx % mod != n) continue;

            if (erc20d._whitelist[whitelistNdx] != msg.sender // exclude caller, contract owner
            ) {
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, erc20d._whitelist[whitelistNdx]));
            }
        }

        // hash batches
        // Certik: LLL-10 | Inefficient storage read
        // Resolved (AD): Utilized local variable to avoid multiple storage reads and save gas cost
        uint256 maxCurrentBatchId = ld._batches_currentMax_id;
        for (uint256 batchId = 1; batchId <= maxCurrentBatchId; batchId++) {
            if (batchId % mod != n) continue;

            StructLib.SecTokenBatch storage batch = ld._batches[batchId];

            if (batch.originator != msg.sender) { // exclude contract owner
                ledgerHash = keccak256(abi.encodePacked(ledgerHash,
                    batch.id,
                    batch.mintedTimestamp, batch.tokTypeId,
                    batch.mintedQty, batch.burnedQty,

                    // NOTE: string hashes are quickly exceeding block/view gas limits - ref: https://aircarbon.slack.com/archives/G0112BRQ0TG/p1600831061023700
                    // re-instating; scaleable solution is segmenting GLH() w/ {mod,n}
                    hashStringArray(batch.metaKeys),
                    hashStringArray(batch.metaValues),

                    hashSetFeeArgs(batch.origTokFee),
                    batch.origCcyFee_percBips_ExFee,
                    batch.originator
                ));
            }
        }

        // walk ledger -- exclude contract owner from hashes
        // Certik: LLL-11 | Inefficient storage read
        // Resolved (AD): Utilized local variable to avoid multiple storage reads and save gas cost
        uint256 ledgerOwnersCount = ld._ledgerOwners.length;
        for (uint256 ledgerNdx = 0; ledgerNdx < ledgerOwnersCount; ledgerNdx++) {
            if (ledgerNdx % mod != n) continue;

            address entryOwner = ld._ledgerOwners[ledgerNdx];
            StructLib.Ledger storage entry = ld._ledger[entryOwner];

            // hash ledger entry owner -- exclude contract owner from this hash (it's could change on contract upgrade)
            if (ledgerNdx != 0)
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, entryOwner));

            // hash ledger token types: token IDs, custom spot fees & FT type data
            // Certik: LLL-12 and LLL-16 | Inefficient storage read
            // Resolved (AD): Utilized local variable to avoid multiple storage reads and save gas cost
            for (uint256 stTypeId = 1; stTypeId <= currentMaxTokenTypeId; stTypeId++) {

                // ### TODO? ## switch -- delegate-base types for CFT-C... ##
                // ### ??? IDs themselves are not material, can skip this hashing?
                uint256[] storage stIds = entry.tokenType_stIds[stTypeId];
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, stIds));

                // ### then left only with FT types & spot custom fees per type -- can read direct from controller???
                if (entry.spot_customFees.tokType_Set[stTypeId]) {
                    ledgerHash = keccak256(abi.encodePacked(ledgerHash, hashSetFeeArgs(entry.spot_customFees.tok[stTypeId])));
                }
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, entry.ft_initMarginBips[stTypeId]));
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, entry.ft_feePerContract[stTypeId]));

                // ### i.e. no delegation required at all?
            }

            // hash balances & custom ccy fees
            // Certik: LLL-14 | Inefficient storage read
            // Resolved (AD): Utilized local variable to avoid multiple storage reads and save gas cost
            uint256 currentMaxCcyTypeId = ctd._ct_Count;
            for (uint256 ccyTypeId = 1; ccyTypeId <= currentMaxCcyTypeId; ccyTypeId++) {
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, entry.ccyType_balance[ccyTypeId]));
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, entry.ccyType_reserved[ccyTypeId]));
                if (entry.spot_customFees.ccyType_Set[ccyTypeId]) {
                    ledgerHash = keccak256(abi.encodePacked(ledgerHash, hashSetFeeArgs(entry.spot_customFees.ccy[ccyTypeId])));
                }
            }

            // hash entry total minted & burned counts
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, entry.spot_sumQtyMinted));
            ledgerHash = keccak256(abi.encodePacked(ledgerHash, entry.spot_sumQtyBurned));
        }

        // walk all tokens (including those fully deleted from the ledger by burn()), hash
        ConsistencyCheck memory chk;
        if (ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER) {
            // controller - passthrough delegate-base call to getLedgerHashcode() to each base type
            for (uint256 tokTypeId = 1; tokTypeId <= currentMaxTokenTypeId; tokTypeId++) {
                StMaster base = StMaster(std._tt_addr[tokTypeId]);
                bytes32 baseTypeHashcode = base.getLedgerHashcode(mod, n);
                ledgerHash = keccak256(abi.encodePacked(ledgerHash, baseTypeHashcode));
            }
        }
        else {
            // base & commodity - walk & hash individual tokens, and apply consistency check on totals
            // Certik: LLL-17 | Inefficient storage read
            // Resolved (AD): Utilized local variable to avoid multiple storage reads and save gas cost
            uint256 currentMaxStId = ld._tokens_currentMax_id;
            for (uint256 stId = ld._tokens_base_id; stId <= currentMaxStId; stId++) {
                StructLib.PackedSt memory st = ld._sts[stId];
                chk.totalCur += uint256(uint64(st.currentQty)); // consistency check (base & commodity)
                chk.totalMinted += uint256(uint64(st.mintedQty));

                if (stId % mod != n) continue;

                ledgerHash = keccak256(abi.encodePacked(ledgerHash,
                    st.batchId,
                    st.mintedQty,
                    st.currentQty,
                    st.ft_price,
                    st.ft_ledgerOwner,
                    st.ft_lastMarkPrice,
                    st.ft_PL
                ));
            }
        }

        // base & commodity - apply consistency check: global totals vs. sum ST totals
        // v1.1b fix on TransferLib: transferSplitSecTokens
        if (ld.contractType != StructLib.ContractType.CASHFLOW_CONTROLLER) {
            require(chk.totalMinted == ld._spot_totalMintedQty, "Consistency check failed (1)"); 
            require(chk.totalMinted - chk.totalCur == ld._spot_totalBurnedQty, "Consistency check failed (2)");
        }

        // hash totals & counters
        ledgerHash = keccak256(abi.encodePacked(ledgerHash, ld._tokens_currentMax_id));
        ledgerHash = keccak256(abi.encodePacked(ledgerHash, ld._spot_totalMintedQty));
        ledgerHash = keccak256(abi.encodePacked(ledgerHash, ld._spot_totalBurnedQty));

    }

    //
    // INTERNAL
    //

    // Certik: LLL-06 | Explicitly returning local variable
    // Resolved (AD): Use of named return variables to reduce overall gas cost
    function hashStringArray(string[] memory strings) private pure returns (bytes32 arrayHash) {
        for (uint256 i = 0 ; i < strings.length ; i++) {
            arrayHash = keccak256(abi.encodePacked(arrayHash, strings[i]));
        }
    }

    // Certik: LLL-06 | Explicitly returning local variable
    // Resolved (AD): Use of named return variables to reduce overall gas cost
    function hashSetFeeArgs(StructLib.SetFeeArgs memory setFeeArgs) private pure returns (bytes32 setFeeArgsHash) {
        setFeeArgsHash = keccak256(abi.encodePacked(
            setFeeArgs.fee_fixed,
            setFeeArgs.fee_percBips,
            setFeeArgs.fee_min,
            setFeeArgs.fee_max
        ));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../Interfaces/StructLib.sol";
import "./TransferLib.sol";

library Erc20Lib {
    uint256 constant private MAX_UINT256 = 2**256 - 1; // for infinite approval

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // WHITELIST - add [single]
    function whitelist(StructLib.LedgerStruct storage ld, StructLib.Erc20Struct storage erc20d, address addr) public {
        require(!erc20d._whitelisted[addr], "Already whitelisted");
        require(!ld._contractSealed, "Contract is sealed");
        erc20d._whitelist.push(addr);
        erc20d._whitelisted[addr] = true;
    }

    function getWhitelist(address[] calldata wld, uint256 pageNo, uint256 pageSize) pure external returns (address[] memory whitelistAddresses) {
        require(pageSize > 0 && pageSize < 2000, 'Bad page size: must be > 0 and < 8750');
        whitelistAddresses = wld[pageNo*pageSize:pageNo*pageSize+pageSize];
    }

    // TRANSFER
    struct transferErc20Args {
        address deploymentOwner;
        address recipient;
        uint256 amount;
    }
    function transfer(
        StructLib.LedgerStruct storage ld,
        StructLib.StTypesStruct storage std,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.FeeStruct storage globalFees,
        transferErc20Args memory a
    ) public returns (bool) {
        require(ld._contractSealed, "Contract is not sealed");
        transferInternal(ld, std, ctd, globalFees, msg.sender, a);
        return true;
    }

    // APPROVE
    function approve(
        StructLib.LedgerStruct storage ld,
        StructLib.Erc20Struct storage erc20d, 
        address spender, uint256 amount
    ) public returns (bool) { // amount = MAX_UINT256: infinite approval
        require(ld._contractSealed, "Contract is not sealed");
        require(!erc20d._whitelisted[spender], "Spender is whitelisted");
        require(!erc20d._whitelisted[msg.sender], "Approver is whitelisted");

        erc20d._allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // TRANSFER-FROM
    function transferFrom(
        StructLib.LedgerStruct storage ld,
        StructLib.StTypesStruct storage std,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.FeeStruct storage globalFees,
        StructLib.Erc20Struct storage erc20d, 
        address sender,
        transferErc20Args memory a
    ) public returns (bool) { 
        uint256 allowance = erc20d._allowances[sender][msg.sender];
        require(ld._contractSealed, "Contract is not sealed");
        require(allowance >= a.amount, "No allowance"); //**

        transferInternal(ld, std, ctd, globalFees, sender, a);
        if (allowance < MAX_UINT256) {
            erc20d._allowances[sender][msg.sender] -= a.amount;
        }
        return true;
    }

    //
    // (internal) transfer: across types
    //
    function transferInternal(
        StructLib.LedgerStruct storage ld,
        StructLib.StTypesStruct storage std,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.FeeStruct storage globalFees,
        address sender,
        transferErc20Args memory a
    ) private {
        uint256 remainingToTransfer = a.amount;
        while (remainingToTransfer > 0) {
            // iterate ST types
            // Certik: ELL-02 | Inefficient storage read
            // Resolved (AD): Utilized a local variable to store std._tt_Count to save gas cost
            uint256 tokenTypeCount = std._tt_Count;
            for (uint256 tokTypeId = 1; tokTypeId <= tokenTypeCount; tokTypeId++) {

                // sum qty tokens of this type
                uint256[] memory tokenType_stIds = ld._ledger[sender].tokenType_stIds[tokTypeId];
                uint256 qtyType;
                for (uint256 ndx = 0; ndx < tokenType_stIds.length; ndx++) {
                    // Certik: ELL-03 | Inefficient storage read
                    // REsolved (AD): Utilized local variable to store ld._sts[tokenType_stIds[ndx]].currentQty to save gas cost
                    int64 currentQtyPerGlobalStId = ld._sts[tokenType_stIds[ndx]].currentQty;
                    require(currentQtyPerGlobalStId > 0, "Unexpected token quantity");
                    qtyType += uint256(uint64(currentQtyPerGlobalStId));
                }

                // transfer this type up to required amount
                uint256 qtyTransfer = remainingToTransfer >= qtyType ? qtyType : remainingToTransfer;

                if (qtyTransfer > 0) {
                    StructLib.TransferArgs memory transferOrTradeArgs = StructLib.TransferArgs({
                            ledger_A: sender,
                            ledger_B: a.recipient,
                               qty_A: qtyTransfer,
                           k_stIds_A: new uint256[](0),
                         tokTypeId_A: tokTypeId,
                               qty_B: 0,
                           k_stIds_B: new uint256[](0),
                         tokTypeId_B: 0,
                        ccy_amount_A: 0,
                         ccyTypeId_A: 0,
                        ccy_amount_B: 0,
                         ccyTypeId_B: 0,
                           applyFees: false,
                        feeAddrOwner: a.deploymentOwner, //address(0x0) // fees: disabled for erc20 - not used
                        transferType: StructLib.TransferType.ERC20
                    });
                    TransferLib.transferOrTrade(ld, std, ctd, globalFees, transferOrTradeArgs);
                    remainingToTransfer -= qtyTransfer;
                }
            }
        }
        emit Transfer(sender, a.recipient, a.amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: https://github.com/7-of-9
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../Interfaces/StructLib.sol";

library CcyLib {
    event AddedCcyType(uint256 id, string name, string unit);
    event CcyFundedLedger(uint256 ccyTypeId, address indexed to, int256 amount, string desc);
    event CcyWithdrewLedger(uint256 ccyTypeId, address indexed from, int256 amount, string desc);

    // CCY TYPES
    function addCcyType(
        StructLib.LedgerStruct storage ld,
        StructLib.CcyTypesStruct storage ctd,
        string memory name,
        string memory unit,
        uint16 decimals)
    public {
        require(ld.contractType == StructLib.ContractType.COMMODITY ||
                ld.contractType == StructLib.ContractType.CASHFLOW_CONTROLLER, "Bad cashflow request"); // disallow ccy's on base cashflow contract

        require(ctd._ct_Count < 32/*MAX_CCYS*/, "Too many currencies");
        // Certik: CLL-02 | Inefficient storage read
        // Resolved (AD): Utilized a local variable to store ctd._ct_Count to save gas cost
        uint256 ccyTypesCount = ctd._ct_Count;
        for (uint256 ccyTypeId = 1; ccyTypeId <= ccyTypesCount; ccyTypeId++) {
            require(keccak256(abi.encodePacked(ctd._ct_Ccy[ccyTypeId].name)) != keccak256(abi.encodePacked(name)), "Currency type name already exists");
        }

        ctd._ct_Count++;
        ctd._ct_Ccy[ctd._ct_Count] = StructLib.Ccy({
              id: ctd._ct_Count,
            name: name,
            unit: unit,
        decimals: decimals
        });
        emit AddedCcyType(ctd._ct_Count, name, unit);
    }

    function getCcyTypes(
        StructLib.CcyTypesStruct storage ctd)
    public view
    returns (StructLib.GetCcyTypesReturn memory ccys) {
        StructLib.Ccy[] memory ccyTypes;
        // Certik: CLL-05 | Inefficient storage read
        // Resolved (AD): Utilized a local variable to store ctd._ct_Count to save gas cost
        uint256 ccyTypesCount = ctd._ct_Count;
        ccyTypes = new StructLib.Ccy[](ccyTypesCount);

        for (uint256 ccyTypeId = 1; ccyTypeId <= ccyTypesCount; ccyTypeId++) {
            ccyTypes[ccyTypeId - 1] = StructLib.Ccy({
                    id: ctd._ct_Ccy[ccyTypeId].id,
                  name: ctd._ct_Ccy[ccyTypeId].name,
                  unit: ctd._ct_Ccy[ccyTypeId].unit,
              decimals: ctd._ct_Ccy[ccyTypeId].decimals
            });
        }
        // Certik: CLL-04 | Explicitly returning local variable
        // Resolved (AD): Refactored to remove the local variable declaration and explicit return statement in order to reduce the overall cost of gas
        ccys = StructLib.GetCcyTypesReturn({
            ccyTypes: ccyTypes
        });
    }

    // FUND & WITHDRAW
    function fundOrWithdraw(
        StructLib.LedgerStruct storage   ld,
        StructLib.CcyTypesStruct storage ctd,
        StructLib.FundWithdrawType       direction,
        uint256                          ccyTypeId,
        int256                           amount,
        address                          ledgerOwner,
        string                           calldata desc)
    public  {
        if (direction == StructLib.FundWithdrawType.FUND) {
            fund(ld, ctd, ccyTypeId, amount, ledgerOwner, desc);
        }
        else if (direction == StructLib.FundWithdrawType.WITHDRAW) {
            withdraw(ld, ctd, ccyTypeId, amount, ledgerOwner, desc);
        }
        else revert("Bad direction");
    }

    function fund(
        StructLib.LedgerStruct storage   ld,
        StructLib.CcyTypesStruct storage ctd,
        uint256                          ccyTypeId,
        int256                           amount, // signed value: ledger supports -ve balances
        address                          ledgerOwner,
        string                           calldata desc)
    private {
        // allow funding while not sealed - for initialization of owner ledger (see testSetupContract.js)
        //require(ld._contractSealed, "Contract is not sealed");
        require(ccyTypeId >= 1 && ccyTypeId <= ctd._ct_Count, "Bad ccyTypeId");
        require(amount >= 0, "Bad amount"); // allow funding zero (initializes empty ledger entry), disallow negative funding

        // we keep amount as signed value - ledger allows -ve balances (currently unused capability)
        //uint256 fundAmount = uint256(amount);

        // create ledger entry as required
        StructLib.initLedgerIfNew(ld, ledgerOwner);

        // update ledger balance
        ld._ledger[ledgerOwner].ccyType_balance[ccyTypeId] += amount;

        emit CcyFundedLedger(ccyTypeId, ledgerOwner, amount, desc);
    }

    function withdraw(
        StructLib.LedgerStruct storage   ld,
        StructLib.CcyTypesStruct storage ctd,
        uint256                          ccyTypeId,
        int256                           amount,
        address                          ledgerOwner,
        string                           calldata desc)
    private {
        require(ld._contractSealed, "Contract is not sealed");
        require(ccyTypeId >= 1 && ccyTypeId <= ctd._ct_Count, "Bad ccyTypeId");
        require(amount > 0, "Bad amount");
        // Certik: CLL-06 | Comparison with literal true
        // Resolved (AD): Substituted the literal true comparison with the expression itself
        require(ld._ledger[ledgerOwner].exists, "Bad ledgerOwner");

        require((ld._ledger[ledgerOwner].ccyType_balance[ccyTypeId] - ld._ledger[ledgerOwner].ccyType_reserved[ccyTypeId]) >= amount, "Insufficient balance");

        // update ledger balance
        ld._ledger[ledgerOwner].ccyType_balance[ccyTypeId] -= amount;

        // update global total withdrawn
        // 24k
        //ld._ccyType_totalWithdrawn[ccyTypeId] += uint256(amount);

        emit CcyWithdrewLedger(ccyTypeId, ledgerOwner, amount, desc);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only - see /LICENSE.md for Terms
// Author: @7-of-9 and @ankurdaharwal
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

import "../StMaster/StMaster.sol";

library StructLib {

    // TRANSFER (one-sided ccy/tok) TYPES
    enum TransferType {
        Undefined,

        // spot trades: user-requested trade transfers, and automated fees
        User,
        ExchangeFee,
        OriginatorFee,

        // futures: settlement transfers
        //TakePay,
        TakePayFee, SettleTake, SettlePay,

        // manual transfers: ccy fees
        MintFee,
        BurnFee,
        WithdrawFee,
        DepositFee,
        DataFee,
        OtherFee1, // AC: ONBOARDING FEE
        OtherFee2, // AC: FIAT/TOKEN WITHDRAW
        OtherFee3, // AC: RETIREMENT
        OtherFee4, // AC: REBATE
        OtherFee5, // AC: PHYSICAL_DELIVERY

        // transfer across related accounts (e.g. corp-admin transfer to corp-trader)
        RelatedTransfer,

        // generic adjustment
        Adjustment,

        // ERC20: token transfer
        ERC20,

        // CFT: token issuance/subscription
        Subscription,

        // AC: BLOCK_TRADE
        BlockTrade
    }

    // EVENTS - SHARED (FuturesLib & TransferLib)
    event TransferedLedgerCcy(address indexed from, address indexed to, uint256 ccyTypeId, uint256 amount, TransferType transferType);
    event ReservedLedgerCcy(address indexed ledgerOwner, uint256 ccyTypeId, uint256 amount);

    /**
     * @notice Transfers currency across ledger entries
     * @param a Transfer arguments
     */
    struct TransferCcyArgs {
        address                from;
        address                to;
        uint256                ccyTypeId;
        uint256                amount;
        StructLib.TransferType transferType;
    }
    function transferCcy(
        StructLib.LedgerStruct storage ld,
        TransferCcyArgs memory a)
    public {
        // Certik: (Major) SLI-05 | Unsafe Cast
        // Resolved: (Major) SLI-05 | Added bound evaluation for int256
        if(a.amount > 0) {
            require(a.amount <= uint256(type(int256).max) , "Bound check found overflow");
            ld._ledger[a.from].ccyType_balance[a.ccyTypeId] -= int256(a.amount);
            ld._ledger[a.to].ccyType_balance[a.ccyTypeId] += int256(a.amount);
            emitTransferedLedgerCcy(a);
        }
    }
    function emitTransferedLedgerCcy(
        TransferCcyArgs memory a)
    public {
        if (a.amount > 0) {
            emit StructLib.TransferedLedgerCcy(a.from, a.to, a.ccyTypeId, a.amount, a.transferType);
        }
    }

    /**
     * @notice Sets the reserved (unavailable/margined) currency amount for the specified ledger owner
     * @param ledger Ledger owner
     * @param ccyTypeId currency type
     * @param reservedAmount Reserved amount to set
     */
    function setReservedCcy(
        StructLib.LedgerStruct storage   ld,
        StructLib.CcyTypesStruct storage ctd,
        address ledger, uint256 ccyTypeId, int256 reservedAmount
    ) public {
        require(ccyTypeId >= 1 && ccyTypeId <= ctd._ct_Count, "Bad ccyTypeId");
        initLedgerIfNew(ld, ledger);
        require(ld._ledger[ledger].ccyType_balance[ccyTypeId] >= reservedAmount, "Reservation exceeds balance");
        require(reservedAmount >= 0, "Bad reservedAmount");

        if (ld._ledger[ledger].ccyType_reserved[ccyTypeId] != reservedAmount) {
            ld._ledger[ledger].ccyType_reserved[ccyTypeId] = reservedAmount;
            emit ReservedLedgerCcy(ledger, ccyTypeId, uint256(reservedAmount));
        }
    }

    // CONTRACT TYPE
    // Certik: (Minor) SLI-09 | State Representation Inconsistency The enum declarations of the contract are inconsistent with regards to the default state. While the ContractType and FundWithdrawType enums have an actionable default state, the SettlementType enum has an UNDEFINED default state.
    // Resolved: (Minor) SLI-09 | Removed UNDEFINED from ContractType for consistency
    enum ContractType { COMMODITY, CASHFLOW_BASE, CASHFLOW_CONTROLLER }

    // CCY TYPES
    // Certik: (Minor) SLI-09 | State Representation Inconsistency The enum declarations of the contract are inconsistent with regards to the default state. While the ContractType and FundWithdrawType enums have an actionable default state, the SettlementType enum has an UNDEFINED default state.
    // Resolved: (Minor) SLI-09 | Removed UNDEFINED from FundWithdrawType for consistency and capitalized Fund and Withdraw types
    enum FundWithdrawType { FUND, WITHDRAW }
    struct Ccy {
        uint256 id;
        string  name; // e.g. "USD", "BTC"
        string  unit; // e.g. "cents", "satoshi"
        uint16  decimals;
    }
    struct GetCcyTypesReturn {
        Ccy[] ccyTypes;
    }

    struct CcyTypesStruct { // ** DATA_DUMP: OK
        mapping(uint256 => Ccy) _ct_Ccy;                        // typeId (1-based) -> ccy
        uint256 _ct_Count;
    }

    // ST TOKEN-TYPES
    struct SecTokenTypeReturn {
        uint256             id;
        string              name;
        SettlementType      settlementType;
        FutureTokenTypeArgs ft;
        address             cashflowBaseAddr;
    }
    struct GetSecTokenTypesReturn {
        SecTokenTypeReturn[] tokenTypes;
    }

    // Certik: (Minor) SLI-09 | State Representation Inconsistency The enum declarations of the contract are inconsistent with regards to the default state. While the ContractType and FundWithdrawType enums have an actionable default state, the SettlementType enum has an UNDEFINED default state.
    // Resolved: (Minor) SLI-09 | Added UNDEFINED back to SettlementType to support getLedgerHashcode validation when upgrading/migrating a new smart contract
    enum SettlementType { UNDEFINED, SPOT, FUTURE }
    struct StTypesStruct { // ** DATA_DUMP: OK
        mapping(uint256 => string)              _tt_name;       // typeId (1-based) -> typeName
        mapping(uint256 => SettlementType)      _tt_settle;
        mapping(uint256 => FutureTokenTypeArgs) _tt_ft;
        mapping(uint256 => address payable)     _tt_addr;       // cashflow base
        uint256 _tt_Count;
    }
        struct FutureTokenTypeArgs {
            uint64  expiryTimestamp;
            uint256 underlyerTypeId;
            uint256 refCcyId;
            uint16  initMarginBips;                             // initial margin - set only once at future token-type creation
            uint16  varMarginBips;                              // variation margin - can be updated after token-type creation
            uint16  contractSize;                               // contract size - set only once at future token-type creation
            uint128 feePerContract;                             // paid by both sides in refCcyId - can be updated after token-type creation
        }

    // TOKEN BATCH
    struct SecTokenBatch { // ** DATA_DUMP: OK
        uint64     id;                                          // global sequential id: 1-based
        uint256    mintedTimestamp;                             // minting block.timestamp
        uint256    tokTypeId;                                   // token type of the batch
        uint256    mintedQty;                                   // total unit qty minted in the batch
        uint256    burnedQty;                                   // total unit qty burned from the batch
        string[]   metaKeys;                                    // metadata keys
        string[]   metaValues;                                  // metadata values
        SetFeeArgs origTokFee;                                  // batch originator token fee on all transfers of tokens from this batch
        uint16     origCcyFee_percBips_ExFee;                   // batch originator ccy fee on all transfers of tokens from this batch - % of exchange currency fee
        address payable originator;                             // original owner (minter) of the batch
    }

    struct Ledger {
        bool                          exists;                   // for existance check by address
        mapping(uint256 => uint256[]) tokenType_stIds;          // SectokTypeId -> stId[] of all owned STs

        mapping(uint256 => int256)    ccyType_balance;          // CcyTypeId -> spot/total cash balance -- signed, for potential -ve balances
        mapping(uint256 => int256)    ccyType_reserved;         // CcyTypeId -> total margin requirement [FUTURES] (available = balance - reserved)

        StructLib.FeeStruct           spot_customFees;          // global fee override - per ledger entry
        uint256                       spot_sumQtyMinted;
        uint256                       spot_sumQtyBurned;

        mapping(uint256 => uint16)    ft_initMarginBips;        // SectokTypeId -> custom initial margin override ("hedge exemption"); overrides FT-type value if set
        mapping(uint256 => uint128)   ft_feePerContract;        // SectokTypeId -> custom fee per contract override; overrides FT-type value if set
    }

    struct LedgerReturn {                                       // ledger return structure
        bool                   exists;
        LedgerSecTokenReturn[] tokens;                          // STs with types & sizes (in contract base unit) information - v2
        uint256                spot_sumQty;                     // retained for caller convenience - v1 [SPOT types only]
        LedgerCcyReturn[]      ccys;                            // currency balances
        uint256                spot_sumQtyMinted;               // [SPOT types only]
        uint256                spot_sumQtyBurned;               // [SPOT types only]
    }
        struct LedgerSecTokenReturn {
            bool    exists;
            uint256 stId;
            uint256 tokTypeId;
            string  tokTypeName;
            uint64  batchId;
            int64   mintedQty;
            int64   currentQty;
            int128  ft_price;
            address ft_ledgerOwner;
            int128  ft_lastMarkPrice;
            int128  ft_PL;
        }
        struct LedgerCcyReturn {
            uint256 ccyTypeId;
            string  name;
            string  unit;
            int256  balance;
            int256  reserved;
        }

    // *** PACKED SECURITY TOKEN ***
    struct PackedSt { // ** DATA_DUMP: OK
        uint64  batchId;                                        // can be zero for "batchless" future "auto-minted" tokens; non-zero for spot tok-types
        int64   mintedQty;                                      // existence check field: should never be non-zero
        int64   currentQty;                                     // current (variable) unit qty in the ST (i.e. burned = currentQty - mintedQty)
        int128  ft_price;                                       // [FUTURE types only] -- becomes average price after combining
        address ft_ledgerOwner;                                 // [FUTURE types only] -- for takePay() lookup of ledger owner by ST
        int128  ft_lastMarkPrice;                               // [FUTURE types only]
        int128  ft_PL;                                          // [FUTURE types only] -- running total P&L
    }
    // struct PackedStTotals {
    //     uint80 transferedQty;
    //     uint80 exchangeFeesPaidQty;
    //     uint80 originatorFeesPaidQty;
    // }

    struct LedgerStruct {
        StructLib.ContractType contractType;

        // *** Batch LIST
        mapping(uint256 => SecTokenBatch) _batches;             // main (spot) batch list: ST batches, by batch ID (future STs don't have batches)
        uint64 _batches_currentMax_id;                          // 1-based

        // *** SecTokens LIST
        mapping(uint256 => PackedSt) _sts;                      // stId => PackedSt
        uint256 _tokens_base_id;                                // 1-based - assigned (once, when set to initial zero value) by Mint()
        uint256 _tokens_currentMax_id;                          // 1-based - updated by Mint() and by transferSplitSecTokens()

        // *** LEDGER
        mapping(address => Ledger) _ledger;                     // main ledger list: all entries, by account
        address[] _ledgerOwners;                                // list of ledger owners (accounts)

        // global totals -- // 24k - exception/retain - needed for erc20 total supply
        uint256 _spot_totalMintedQty;                           // [SPOT types only] - todo: split by type?
        uint256 _spot_totalBurnedQty;                           // [SPOT types only] - todo: split by type?

        // 24k
        //PackedStTotals _spot_total;                             // [SPOT types only] - todo: split by type?

        // 24k
        //mapping(uint256 => uint256) _ccyType_totalFunded;
        //mapping(uint256 => uint256) _ccyType_totalWithdrawn;
        //mapping(uint256 => uint256) _ccyType_totalTransfered;
        //mapping(uint256 => uint256) _ccyType_totalFeesPaid;

        bool _contractSealed;
    }

    // SPOT FEE STRUCTURE -- (ledger or global) fees for all ccy's and token types
    struct FeeStruct {
        mapping(uint256 => bool) tokType_Set;    // bool - values are set for the token type
        mapping(uint256 => bool) ccyType_Set;    // bool - values are set for the currency type
        mapping(uint256 => SetFeeArgs) tok;      // fee structure by token type
        mapping(uint256 => SetFeeArgs) ccy;      // fee structure by currency type
    }
    struct SetFeeArgs { // fee for a specific ccy or token type
        uint256 fee_fixed;       // ccy & tok: transfer/trade - apply fixed a, if any
        uint256 fee_percBips;    // ccy & tok: transfer/trade - add a basis points a, if any - in basis points, i.e. minimum % = 1bp = 1/100 of 1% = 0.0001x
        uint256 fee_min;         // ccy & tok: transfer/trade - collar for a (if >0)
        uint256 fee_max;         // ccy & tok: transfer/trade - and cap for a (if >0)
        uint256 ccy_perMillion;  // ccy only: trade - fixed ccy fee per million of trade counterparty's consideration token qty
        bool    ccy_mirrorFee;   // ccy only: trade - apply this ccy fee structure to counterparty's ccy balance, post trade
    }

    // ERC20 TYPES
    struct Erc20Struct {
        address[] _whitelist;
        mapping(address => bool) _whitelisted;
        mapping (address => mapping (address => uint256)) _allowances; // account => [ { spender, allowance } ]
        //uint256 _nextWhitelistNdx;
    }

    // CASHFLOW STRUCTURE
    enum CashflowType { BOND, EQUITY }
    struct CashflowArgs { // v1: single-issuance, single-subscriber

        CashflowType cashflowType;          // issuance type
        uint256      term_Blks;             // total term/tenor, in blocks - (todo: 0 for perpetual?)
        uint256      bond_bps;              // rates: basis points per year on principal
        uint256      bond_int_EveryBlks;    // rates: interest due every n blocks
    }
    struct CashflowStruct {
        CashflowArgs args;
        uint256      wei_currentPrice;      // current subscription price, in wei per token; or
        uint256      cents_currentPrice;    // current subscription price, in USD cents per token
        uint256      qty_issuanceMax;       // the amount minted in the issuance uni-batch
        uint256      qty_issuanceRemaining; // the amount remaining unsold of the issuance uni-batch
        uint256      qty_issuanceSold;      // the amount sold of the issuance uni-batch
        uint256      qty_saleAllocation;    // the amount of the issuance uni-batch that is available for sale
        address      issuer;                // the uni-batch originator ("minter"), i.e. the issuer (or null address, if not yet minted)

        //uint256      issued_Blk;         // issuance (start) block no
        // --> wei_totIssued
        // --> mapping(address ==> )

        // TODO: payment history... (& bond_int_lastPaidBlk)
        //uint256 bond_int_payments;       // todo - { block_no, amount, }
        //uint256 bond_int_lastPaidBlk;    // rates: last paid interest block no

        // TODO: getCashflowStatus() ==> returns in default or not, based on block.number # and issuer payment history...
    }

    /**
     *  Issuer Payment - Struct for current issuer payment
     *  Reset all except curPaymentId after full payment cycle (i.e. after last batch payment)
     *  0 < curPaymentId < 65535
     *  0 < curBatchNdx < 4294967295
     *  0 < curNdx < 4294967295
    */
    struct IssuerPaymentBatchStruct { // ** DATA_DUMP: TODO
        uint32 curPaymentId;               // 1-based payment ID for each issuer payment: indicates current issuer payment
        uint32 curBatchNdx;                // 1-based batch index for the current issuer payment
        uint32 curNdx;                     // 0-based index into the ledger owners list for current issuer payment batch processing
        uint256 curPaymentTotalAmount;     // total payment due from issuer for the current issuer payment
        uint256 curPaymentProcessedAmount; // current processed payment amount
    }

    // SPOT TRANSFER ARGS
    struct TransferArgs {
        address ledger_A;
        address ledger_B;

        uint256 qty_A;           // ST quantity moving from A (excluding fees, if any)
        uint256[] k_stIds_A;     // if len>0: the constant/specified ST IDs to transfer (must correlate with qty_A, if supplied)
        uint256 tokTypeId_A;     // ST type moving from A

        uint256 qty_B;           // ST quantity moving from B (excluding fees, if any)
        uint256[] k_stIds_B;     // if len>0: the constant/specified ST IDs to transfer (must correlate with qty_B, if supplied)
        uint256 tokTypeId_B;     // ST type moving from B

        int256  ccy_amount_A;    // currency amount moving from A (excluding fees, if any)
                                 // (signed value: ledger supports -ve balances)
        uint256 ccyTypeId_A;     // currency type moving from A

        int256  ccy_amount_B;    // currency amount moving from B (excluding fees, if any)
                                 // (signed value: ledger supports -ve balances)
        uint256 ccyTypeId_B;     // currency type moving from B

        bool    applyFees;       // apply global fee structure to the transfer (both legs)
        address feeAddrOwner;    // exchange fees: receive address

        TransferType transferType; // reason/type code: applies only to one-sided transfers (not two-sided trades, which are coded automatically)
    }
    struct FeesCalc {
        uint256    fee_ccy_A;          // currency fee paid by A
        uint256    fee_ccy_B;          // currency fee paid by B
        uint256    fee_tok_A;          // token fee paid by A
        uint256    fee_tok_B;          // token fee paid by B
        address    fee_to;             // fees paid to
        uint256    origTokFee_qty;     // for originator token fees: token quantity from batch being sent by A or B
        uint64     origTokFee_batchId; // for originator token fees: batch ID supplying the sent token quantity
        SetFeeArgs origTokFee_struct;  // for originator token fees: batch originator token fee structure
    }

    // FUTURES OPEN POSITION ARGS
    struct FuturesPositionArgs {
        uint256  tokTypeId;
        address  ledger_A;
        address  ledger_B;
        int256   qty_A;
        int256   qty_B;
        int256   price; // signed, so we can explicitly test for <0 (otherwise -ve values are silently wrapped by web3 to unsigned values)
    }

    // FUTURES TAKE/PAY SETTLEMENT ARGS
    // struct TakePayArgs {
    //     uint256 tokTypeId;
    //     uint256 short_stId;
    //     int128  markPrice;
    //     int256  feePerSide;
    //     address feeAddrOwner;
    // }
    struct TakePayArgs2 {
        uint256 tokTypeId;
        uint256 stId;
        int128  markPrice;
        int256  feePerSide;
        address feeAddrOwner;
    }

    // FUTURES POSITION COMBINE ARGS
    struct CombinePositionArgs {
        uint256   tokTypeId;
        uint256   master_StId;
        uint256[] child_StIds;
    }

    /**
     * @notice Creates a new ledger entry, if not already existing
     * @param ld Ledger data
     * @param addr Ledger entry address
     */
    function initLedgerIfNew(
        StructLib.LedgerStruct storage ld,
        address addr
    )
    public {
        if (!ld._ledger[addr].exists) {

            StructLib.Ledger storage entry = ld._ledger[addr];
            entry.exists = true;
            // Certik: SLI-02 | Redundant Variable Initialization
            // Resolved (AD): Removed redundant variable intialization; default value = 0
            ld._ledgerOwners.push(addr);
        }
    }

    /**
     * @notice Checks if the supplied ledger owner holds at least the specified quantity of supplied ST type
     * @param ledger Ledger owner
     * @param tokTypeId ST type
     * @param qty Validation quantity in contract base unit
     */
    function sufficientTokens(
        StructLib.LedgerStruct storage ld,
        address ledger, uint256 tokTypeId, int256 qty, int256 fee
    ) public view returns (bool) {
        // Certik: SLI-02 | Redundant Variable Initialization
        // Resolved (AD): Removed redundant variable intialization; default value = 0
        int256 qtyAvailable;
        // Certik: (Minor) SLI-08 | Unsafe Mathematical Operations The linked statements perform unsafe mathematical operations between multiple arguments that would rely on caller sanitization, an ill-advised pattern
        // Resolved: (Minor) SLI-08 | Safe operations are in-built in Solidity version ^0.8.0
        require(ld._contractSealed, "Contract is not sealed");
        require(ld._ledger[ledger].exists == true, "Bad ledgerOwner");
        // Certik: SLI-03 and SLI-07 | Inefficient storage read & Loop Optimizations
        // Resolved (AD): Utilized local variable for gas optimization
        uint256[] memory tokenTypeStIds = ld._ledger[ledger].tokenType_stIds[tokTypeId];
        for (uint i = 0; i < tokenTypeStIds.length; i++) {
            qtyAvailable += ld._sts[tokenTypeStIds[i]].currentQty;
        }
        return qtyAvailable >= qty + fee;
    }

    /**
     * @notice Checks if the supplied ledger owner holds at least the specified amount of supplied currency type
     * @param ledger Ledger owner
     * @param ccyTypeId currency type
     * @param sending Amount to be sent
     * @param receiving Amount to be received
     * @param fee Fee to be paid
     */
    function sufficientCcy(
        StructLib.LedgerStruct storage ld,
        address ledger, uint256 ccyTypeId, int256 sending, int256 receiving, int256 fee
    ) public view returns (bool) {
        // Certik: (Minor) SLI-08 | Unsafe Mathematical Operations The linked statements perform unsafe mathematical operations between multiple arguments that would rely on caller sanitization, an ill-advised pattern
        // Resolved: (Minor) SLI-08 | Safe operations are in-built in Solidity version ^0.8.0
        require(ld._contractSealed, "Contract is not sealed");
        require(ld._ledger[ledger].exists == true, "Bad ledgerOwner");
        return (ld._ledger[ledger].ccyType_balance[ccyTypeId]
                + receiving - ld._ledger[ledger].ccyType_reserved[ccyTypeId]
               ) >= sending + fee;
    }

    /**
     * @notice Checks if the supplied token of supplied type is present on the supplied ledger entry
     * @param ledger Ledger owner
     * @param tokTypeId Token type ID
     * @param stId Security token ID
     */
    function tokenExistsOnLedger(
        StructLib.LedgerStruct storage ld,
        uint256 tokTypeId, address ledger, uint256 stId
    ) public view returns(bool) {
        // Certik: SLI-03 and SLI-07 | Inefficient storage read & Loop Optimizations
        // Resolved (AD): Utilized local variable for gas optimization
        uint256[] memory tokenTypeStIds = ld._ledger[ledger].tokenType_stIds[tokTypeId];
        for (uint256 x = 0; x < tokenTypeStIds.length ; x++) {
            if (tokenTypeStIds[x] == stId) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Author: @ankurdaharwal
// Certik (AD): locked compiler version
pragma solidity 0.8.5;

/**
 * @notice Chainlink Reference Data Contract
 * @dev https://docs.chain.link/docs/using-chainlink-reference-contracts
 */
// https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

// Certik: (Major) ICA-01 | Incorrect Chainlink Interface
// Resolved: (Major) ICA-01 | Upgraded Chainlink Aggregator Interface to V3


interface IChainlinkAggregator {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId) external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}