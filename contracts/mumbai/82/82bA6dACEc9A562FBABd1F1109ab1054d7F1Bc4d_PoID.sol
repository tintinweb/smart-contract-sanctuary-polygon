/************************************************************
 * 
 * Autor: TheForks
 * Version: 09-03-2022 07:00
 *
 * 446576656c6f7065723a20416e746f6e20506f6c656e79616b61 ****/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./IPoID.sol";

contract PoID is IPoID {

    // Attributies
    address private _owner;
    address private _contractAddress;
    
    mapping(address => bool) private _isSlotManager;
    
    uint16[] private _allowedDays;
    mapping(uint16 => bool) private _numDayToAllowed;
    
    uint256[] private _slotIds;
    // key slot id
    mapping(uint256 => Slot) private _slotIdToSlot;
    mapping(uint256 => bool) private _slotIdToEnabled;
    mapping(uint256 => bool) private _slotIdToExist;
    mapping(uint256 => bool) private _slotIdToWorcapedAnyTime;

    UserLockedTokens[] private _userLockedTokens;
    // key = user wallet
    mapping(address => UserLockedTokens[]) private _addressToUserLockedTokens;
    // key1 = user wallet, key2 = slot id, key 3 = block timestamp
    mapping(address => mapping(uint256 => mapping(uint256 => UserLockedTokens))) private _userTokens;
    // key1 = user wallet, key2 = slot id, key 3 = block timestamp. Value: true (already redemeed)
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) private _redemeed;

    address _tokensContractAddress;

    // Constructors
    constructor() {
        _owner = msg.sender;
        _contractAddress = address(this);

        // Managers of contract
        _isSlotManager[_owner] = true;
        emit SlotManagerAdded(_owner);
        address managerLev = 0xE52488d841e538192E8f55D5003E62ed904888C2; // Lev X
        _isSlotManager[managerLev] = true;
        emit SlotManagerAdded(managerLev);

        // Allowed number of days for workaping
        _allowedDays = [10, 30, 60, 90];
        for(uint256 i = 0; i < _allowedDays.length; i ++) {
            uint16 allowedDay = _allowedDays[i];
            _numDayToAllowed[allowedDay] = true;
        }

        // Tokens FORKS contract
        _tokensContractAddress = address(0);
    }

    // Modifiers
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERROR: caller is not the owner!");
        _;
    }

    modifier onlySlotManagers() {
        require(_isSlotManager[msg.sender] == true, "ERROR: caller is not the slot manager!");
        _;
    }

    // Methods: Tokens contract
    function TokensContractSetAddress(address tokensContract_) external override onlySlotManagers {
        // Check data
        require(tokensContract_ != address(0), "ERROR: tokens contract address need to be different 0!");
        // Work
        _tokensContractAddress = tokensContract_;
        // Emit events
        emit TokensContractAddressChanged(_tokensContractAddress);
    }

    function TokensContractGetAddress() external override view returns(address tokensContract) {
        return _tokensContractAddress;
    }

    // Methods: Slot Managers

    function SlotManagerAdd(address managerAddress_) external override onlySlotManagers {
        // Check data
        require(managerAddress_ != address(0), "ERROR: Is not allowed 0 address!");
        // Work
        _isSlotManager[managerAddress_] = true;
        // Emit events
        emit SlotManagerAdded(managerAddress_);
    }

    function SlotManagerDelete(address managerAddress_) external override onlySlotManagers {
        // Check data
        require(managerAddress_ != address(0), "ERROR: Is not allowed 0 address!");
        // Work
        _isSlotManager[managerAddress_] = false;
        // Emit events
        emit SlotManagerDeleted(managerAddress_);
    }

    function SlotManagerCheckRights(address managerAddress_) external override view returns(bool) {
        // Check data
        require(managerAddress_ != address(0), "ERROR: Is not allowed 0 address!");
        // Work
        return _isSlotManager[managerAddress_];
    }

    // Methods: Slots

    function SlotAllowedDays() external override view returns(uint16[] memory) {
        return _allowedDays;
    }

    function _slotInfoCheck(uint256 slotId_, uint16 daysToLock_, bool isFixedIncomePercentage_, uint8 fixedPercentage_, 
        uint256 minTokensAmount_, uint256 maxTokensAmount_, uint256 suscriptionPeriodStartTimestamp_,
        uint256 suscriptionPeriodEndTimestamp_) internal view {
        // Check data
        require(slotId_ > 0, "ERROR: slot id must be greater 0!");
        require(_numDayToAllowed[daysToLock_] == true, "ERROR: this number of days is not allowed!");
        if(isFixedIncomePercentage_) {
            require(fixedPercentage_ > 0, "ERROR: fixedPercentage must be greater 0 if we have isFixedIncomePercentage == true!");
        } else {
            require(fixedPercentage_ == 0, "ERROR: fixedPercentage must be 0 if we have isFixedIncomePercentage == false!");
        }
        if(minTokensAmount_ > 0) {
            require(maxTokensAmount_ == 0 || maxTokensAmount_ >= minTokensAmount_, "ERROR: with min, we need max >= min or max == 0 (undefined)!");
        }
        if(maxTokensAmount_ > 0) {
            require(minTokensAmount_ <= maxTokensAmount_, "ERROR: with max > 0, we need min <= max!");
        }
        if(suscriptionPeriodStartTimestamp_ > 0) {
            require(suscriptionPeriodEndTimestamp_ == 0 || suscriptionPeriodEndTimestamp_ > suscriptionPeriodStartTimestamp_, 
            "ERROR: if we use suscription period start date, we need end date greater start date or undefined (=0)!");
        }
        if(suscriptionPeriodEndTimestamp_ > 0) {
            require(suscriptionPeriodStartTimestamp_ == 0 || suscriptionPeriodStartTimestamp_ < suscriptionPeriodEndTimestamp_, 
            "ERROR: if we use suscription period end date, we need start date befor end date or undefined (=0)!");
        }
    }

    function SlotAdd(uint256 slotId_, uint16 daysToLock_, bool isFixedIncomePercentage_, uint8 fixedPercentage_, 
        uint256 minTokensAmount_, uint256 maxTokensAmount_, bool isEnabled_, uint256 suscriptionPeriodStartTimestamp_,
        uint256 suscriptionPeriodEndTimestamp_) external override { // onlySlotManagers
        // Check data
        _slotInfoCheck(slotId_, daysToLock_, isFixedIncomePercentage_, fixedPercentage_, minTokensAmount_,
            maxTokensAmount_, suscriptionPeriodStartTimestamp_, suscriptionPeriodEndTimestamp_);
        require(_slotIdToExist[slotId_] == false, "ERROR: this slot id is already used!");
        // Work
        Slot memory slot = Slot({
            slotId: slotId_,
            daysToLock: daysToLock_,
            isFixedIncomePercentage: isFixedIncomePercentage_,
            fixedPercentage: fixedPercentage_,
            minTokensAmount: minTokensAmount_,
            maxTokensAmount: maxTokensAmount_,
            slotManagerAddress: msg.sender,
            suscriptionPeriodStartTimestamp: suscriptionPeriodStartTimestamp_,
            suscriptionPeriodEndTimestamp: suscriptionPeriodEndTimestamp_,
            isEnabled: isEnabled_,
            claimedTokens: 0
        });

        _slotIds.push(slot.slotId);
        _slotIdToSlot[slotId_] = slot;
        _slotIdToEnabled[slotId_] = isEnabled_;
        _slotIdToExist[slotId_] = true;
        _slotIdToWorcapedAnyTime[slotId_] = false;
        // Emit events
        emit SlotAdded(slotId_);
        if(isEnabled_) {
            emit SlotEnabled(slotId_);
        } else {
            emit SlotDisabled(slotId_);
        }
    }

    function SlotUpdate(uint256 slotId_, uint16 daysToLock_, bool isFixedIncomePercentage_, uint8 fixedPercentage_, 
        uint256 minTokensAmount_, uint256 maxTokensAmount_, bool isEnabled_, uint256 suscriptionPeriodStartTimestamp_,
        uint256 suscriptionPeriodEndTimestamp_) external override onlySlotManagers {
        // Check data
        _slotInfoCheck(slotId_, daysToLock_, isFixedIncomePercentage_, fixedPercentage_, minTokensAmount_,
            maxTokensAmount_, suscriptionPeriodStartTimestamp_, suscriptionPeriodEndTimestamp_);
        require(_slotIdToExist[slotId_] == true, "ERROR: slot with this slot id not exist!");
        require(_slotIdToWorcapedAnyTime[slotId_] == false, "ERROR: is not possible to change slot, because is already used for worcaping!");

        // Work
        Slot storage slot = _slotIdToSlot[slotId_];
        slot.slotId = slotId_;
        slot.daysToLock = daysToLock_;
        slot.isFixedIncomePercentage = isFixedIncomePercentage_;
        slot.fixedPercentage = fixedPercentage_;
        slot.minTokensAmount = minTokensAmount_;
        slot.maxTokensAmount = maxTokensAmount_;
        slot.slotManagerAddress = msg.sender;
        slot.suscriptionPeriodStartTimestamp = suscriptionPeriodStartTimestamp_;
        slot.suscriptionPeriodEndTimestamp = suscriptionPeriodEndTimestamp_;
        slot.isEnabled = isEnabled_;
        
        _slotIdToEnabled[slotId_] = isEnabled_;
        // Emit event
        emit SlotUpdated(slotId_);
        if(isEnabled_) {
            emit SlotEnabled(slotId_);
        } else {
            emit SlotDisabled(slotId_);
        }
    }

    function _removeSlotFromArray(uint256 slotIndex_) internal {
        _slotIds[slotIndex_] = _slotIds[_slotIds.length - 1];
        _slotIds.pop();
    }

    function _getSlotIndexFromArray(uint256 slotId_) internal view returns(bool exist, uint256 slotIndex) {
        slotIndex = 0;
        exist = false;
        for(uint256 i = 0; i < _slotIds.length; i++) {
            if(_slotIds[i] == slotId_) {
                exist = true;
                slotIndex = i;
                break;
            }
        }
        return (exist, slotIndex);
    }

    function SlotDelete(uint256 slotId_) external override onlySlotManagers {
        // Check data
        require(_slotIdToExist[slotId_] == true, "ERROR: slot with this slot id not exist!");
        require(_slotIdToWorcapedAnyTime[slotId_] == false, "ERROR: is not possible to change slot, because is already used for worcaping!");

        // Work
        (bool exist, uint256 slotIndex) = _getSlotIndexFromArray(slotId_);
        if(exist) {
            _removeSlotFromArray(slotIndex);
            delete _slotIdToSlot[slotId_];
            delete _slotIdToWorcapedAnyTime[slotId_];
            delete _slotIdToEnabled[slotId_];
            delete _slotIdToExist[slotId_];
            // Emit event
            emit SlotDeleted(slotId_);
        }
    }

    function SlotEnable(uint256 slotId_) external override onlySlotManagers {
        // Check data
        require(_slotIdToExist[slotId_] == true, "ERROR: slot with this slot id not exist!");
        require(_slotIdToEnabled[slotId_] == false, "ERROR: slot is already enabled!");
        // Work
        _slotIdToSlot[slotId_].isEnabled = true;
        _slotIdToEnabled[slotId_] = true;
        // Emit event
        emit SlotEnabled(slotId_);
    }

    function SlotDisable(uint256 slotId_) external override onlySlotManagers {
        // Check data
        require(_slotIdToExist[slotId_] == true, "ERROR: slot with this slot id not exist!");
        require(_slotIdToEnabled[slotId_] == true, "ERROR: slot is already disabled!");
        // Work
        _slotIdToSlot[slotId_].isEnabled = false;
        _slotIdToEnabled[slotId_] = false;
        // Emit event
        emit SlotDisabled(slotId_);
    }

    function SlotGetAll(bool includeEnabled_, bool includeDisabled_) external override view returns(Slot[] memory slots) {        
        // Check data
        require(includeEnabled_ || includeDisabled_, "ERROR: you need to include enabled and/or disabled slot's!");
        // Work
        Slot[] memory slotsTemp = new Slot[](_slotIds.length);
        uint256 counter = 0;
        for(uint256 i = 0; i < _slotIds.length; i++) {
            uint256 slotId = _slotIds[i];
            Slot memory slot = _slotIdToSlot[slotId];
            if(_slotCheckEnable(includeEnabled_, includeDisabled_, slot)) {
                slotsTemp[counter] = slot;
                counter++;
            }
        }

        // Compact array
        slots = _compactSlotArray(slotsTemp, counter);
        // Return result
        return slots;
    }

    function SlotGetBetweenIds(uint256 slotIdMin_, uint256 slotIdMax_, bool includeEnabled_, bool includeDisabled_) external override view returns(Slot[] memory slots) {
        // Check data
        require(slotIdMin_ <= slotIdMax_, "ERROR: max id need to be greater or equal to min id!");
        require(includeEnabled_ || includeDisabled_, "ERROR: you need to include enabled and/or disabled slot's!");
        // Work
        Slot[] memory slotsTemp = new Slot[](_slotIds.length);
        uint256 counter = 0;
        for(uint256 i = 0; i < _slotIds.length; i++) {
            uint256 slotId = _slotIds[i];
            Slot memory slot = _slotIdToSlot[slotId];
            if(slotIdMin_ >= slot.slotId && slot.slotId <= slotIdMax_) {
                if(_slotCheckEnable(includeEnabled_, includeDisabled_, slot)) {
                    slotsTemp[counter] = slot;
                    counter++;
                }
            }
        }

        // Compact array
        slots = _compactSlotArray(slotsTemp, counter);
        // Return result
        return slots;
    }

    function _slotGetSlotWithMinId(uint256 lowerId_, bool includeEnabled_, bool includeDisabled_) internal view returns(bool exist, Slot memory slot) {
        uint256 lastId = 0;
        exist = false;
        for(uint256 i = 0; i < _slotIds.length; i++) {
            uint256 slotId = _slotIds[i];
            Slot memory slotTemp = _slotIdToSlot[slotId];
            if(_slotCheckEnable(includeEnabled_, includeDisabled_, slot)) {
                if(lastId == 0 && slotTemp.slotId >= lowerId_) {
                    lastId = slotTemp.slotId;
                    slot = slotTemp;
                    exist = true;
                } else if(lastId > 0 && slotTemp.slotId >= lowerId_ && slotTemp.slotId < lastId){
                    lastId = slotTemp.slotId;
                    slot = slotTemp;
                    exist = true;
                }
            }
        }
        return (exist, slot);
    }

    function SlotGetFromId(uint256 slotIdMin_, uint8 numSlots_, bool includeEnabled_, bool includeDisabled_) external override view returns(Slot[] memory slots) {
        // Check data
        require(numSlots_ > 0, "ERROR: number of slots need to be greater of 0!");
        require(includeEnabled_ || includeDisabled_, "ERROR: you need to include enabled and/or disabled slot's!");
        // Work
        uint256 nextMinId = slotIdMin_;
        Slot[] memory slotsTemp = new Slot[](_slotIds.length);
        uint256 counter = 0;
        for(uint256 i = 0; i < numSlots_; i++) {
            (bool exist, Slot memory slot) = _slotGetSlotWithMinId(nextMinId, includeEnabled_, includeDisabled_);
            if(exist) {
                slotsTemp[counter] = slot;
                counter = counter + 1;
                nextMinId = slot.slotId + 1;
            } else {
                break;
            }
        }
        // Compact array
        slots = _compactSlotArray(slotsTemp, counter);
        // Return result
        return slots;
    }

    function SlotGetById(uint256 slotId_) external override view returns(Slot memory slot) {
        // Check data
        require(_slotIdToExist[slotId_] == true, "ERROR: slot with this slot id not exist!");
        // Work & Return result
        return _slotIdToSlot[slotId_];
    }

    function SlotGetIds(bool includeEnabled_, bool includeDisabled_) external override view returns(uint256[] memory slotsIds) {
        // Check data
        require(includeEnabled_ || includeDisabled_, "ERROR: you need to include enabled and/or disabled slot's");
        // Work
        uint256 counter = 0;

        uint256[] memory slotsTempIds = new uint256[](_slotIds.length);
        for(uint256 i = 0; i < _slotIds.length; i++) {
            uint256 slotId = _slotIds[i];
            Slot memory slot = _slotIdToSlot[slotId];
            if(_slotCheckEnable(includeEnabled_, includeDisabled_, slot)) {
                slotsTempIds[counter] = slot.slotId;
                counter++;
            }
        }

        // Compact array
        slotsIds = new uint256[](counter);
        for(uint256 i = 0; i < counter; i++) {
            slotsIds[i] = slotsTempIds[i];
        }

        return slotsIds;
    }

    function _slotCheckEnable(bool includeEnabled_, bool includeDisabled_, Slot memory slot_) internal pure returns(bool isOk){
        isOk = (slot_.isEnabled == true && includeEnabled_) || (slot_.isEnabled == false && includeDisabled_);
        return isOk;
    }

    function _slotHasClaimedTokens(Slot memory slot) internal pure returns(bool hasTokens){
        hasTokens = slot.claimedTokens > 0;
        return hasTokens;
    }

    function SlotsGetWithClaimedTokens(bool includeEnabled, bool includeDisabled) external override view returns(Slot[] memory slots) {
        // Check data
        require(includeEnabled || includeDisabled, "ERROR: you need to include enabled and/or disabled slot's");
        // Work
        Slot[] memory slotsTemp = new Slot[](_slotIds.length);
        uint256 counter = 0;
        for(uint256 i = 0; i < _slotIds.length; i++) {
            uint256 slotId = _slotIds[i];
            Slot memory slot = _slotIdToSlot[slotId];
            // Check is enabled/disabled
            if(_slotCheckEnable(includeEnabled, includeDisabled, slot)
                && _slotIdToWorcapedAnyTime[slot.slotId]
                && _slotHasClaimedTokens(slot)) {
                slotsTemp[counter] = slot;
                counter++;
            }
        }
        // Compact array
        slots = _compactSlotArray(slotsTemp, counter);
        return slots;
    }

    function _compactSlotArray(Slot[] memory slotsTemp_, uint256 counter_) internal pure returns(Slot[] memory slots) {
        // Compact array
        slots = new Slot[](counter_);
        for(uint256 i = 0; i < counter_; i++) {
            slots[i] = slotsTemp_[i];
        }
        return slots;
    }

    function SlotsGetWithoutClaimedTokens(bool includeEnabled_, bool includeDisabled_) external override view returns(Slot[] memory slots) {
        // Check data
        require(includeEnabled_ || includeDisabled_, "ERROR: you need to include enabled and/or disabled slot's");
        // Work
        Slot[] memory slotsTemp = new Slot[](_slotIds.length);
        uint256 counter = 0;
        for(uint256 i = 0; i < _slotIds.length; i++) {
            uint256 slotId = _slotIds[i];
            Slot memory slot = _slotIdToSlot[slotId];
            // Check is enabled/disabled
            if(_slotCheckEnable(includeEnabled_, includeDisabled_, slot)
                && (!_slotIdToWorcapedAnyTime[slot.slotId] || !_slotHasClaimedTokens(slot))) {
                slotsTemp[counter] = slot;
                counter++;
            }
        }
        // Compact array
        slots = _compactSlotArray(slotsTemp, counter);
        return slots;
    }

    function _slotClaimedTokensAdd(uint256 slotId_, uint256 amount_) internal {
        _slotIdToWorcapedAnyTime[slotId_] = true;
        _slotIdToSlot[slotId_].claimedTokens += amount_;
    }

    function _slotClaimedTokensRemove(uint256 slotId_, uint256 amount_) internal {
        _slotIdToSlot[slotId_].claimedTokens -= amount_;
    }

    // Methods: Users
    function WorcapTokens(uint256 tokensAmount_, uint256 slotId_) external override {
        // Check data
        require(_slotIdToExist[slotId_] == true, "ERROR: slot with this slot id not exist");
        require(tokensAmount_ > 0, "ERROR: tokens amount need to be great of 0");
        // Work
        address userWallet = msg.sender;
        UserLockedTokens memory item = UserLockedTokens ({
            userWalletAddres: userWallet,
            slotId: slotId_,
            tokensAmount: tokensAmount_,
            timestamp: block.timestamp
        });
        _userLockedTokens.push(item);
        _addressToUserLockedTokens[userWallet].push(item);
        _userTokens[userWallet][slotId_][item.timestamp] = item;
        _redemeed[userWallet][slotId_][item.timestamp] = false;        
        _slotClaimedTokensAdd(slotId_, tokensAmount_);
        // Event
        emit TokensWorcaped(userWallet, slotId_, tokensAmount_);
    }

    function RedeemTokens(uint256 slotId_, uint256 blockTimestamp_) external override {
        // Check data
        require(_slotIdToExist[slotId_] == true, "ERROR: slot with this slot id not exist");
        require(blockTimestamp_ > 0, "ERROR: block timestamp is not correct");
        address userWallet = msg.sender;
        require(_userTokens[userWallet][slotId_][blockTimestamp_].userWalletAddres == msg.sender, 
            "ERROR: user don't has any worcap for this slot id and this block time");
        require(_redemeed[userWallet][slotId_][blockTimestamp_] == false, "ERROR: this slot is already redeemed by user");
        // Work
        UserLockedTokens storage claim = _userTokens[userWallet][slotId_][blockTimestamp_];
        _redemeed[userWallet][slotId_][blockTimestamp_] = true;
        uint256 tokensAmount = claim.tokensAmount;
        claim.tokensAmount = 0;
        _slotClaimedTokensRemove(slotId_, tokensAmount);
        // Event
        emit TokensRedeemed(userWallet, slotId_, tokensAmount);
    }

    function GetAllUserClaims() external override view returns(UserLockedTokens[] memory) {
        return _addressToUserLockedTokens[msg.sender];
    }

    function _compactClaimsArray(UserLockedTokens[] memory claimsTemp_, uint256 counter_) internal pure returns(UserLockedTokens[] memory claims) {
        // Compact array
        claims = new UserLockedTokens[](counter_);
        for(uint256 i = 0; i < counter_; i++) {
            claims[i] = claimsTemp_[i];
        }
        return claims;
    }

    function GetCurrentUserClaims() external view override returns(UserLockedTokens[] memory userClaims) {
        // Get all user claims
        UserLockedTokens[] memory userClaimsAll = _addressToUserLockedTokens[msg.sender];
        UserLockedTokens[] memory userClaimsTemp = new UserLockedTokens[](userClaimsAll.length);
        // Filter user claims and get only claims with locked tokens
        uint256 counter;
        for(uint256 i = 0; i < userClaimsAll.length; i++) {
            UserLockedTokens memory claim = userClaimsAll[i];
            // Check if claim has any locked token
            if(claim.tokensAmount > 0) {
                userClaimsTemp[counter] = claim;
                counter++;
            }
        }

        userClaims = _compactClaimsArray(userClaimsTemp, counter);
        return userClaims;
    }
}