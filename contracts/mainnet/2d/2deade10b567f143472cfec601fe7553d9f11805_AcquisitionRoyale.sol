// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IAcquisitionRoyale.sol";
import "./interfaces/IAcqrHook.sol";

contract AcquisitionRoyale is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IAcquisitionRoyale,
    ERC721EnumerableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ImmunityPeriods {
        uint256 acquisition;
        uint256 merger;
        uint256 revival;
    }

    struct FoundingParameters {
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 endTime;
    }

    struct PassiveRpParameters {
        uint256 max;
        uint256 base;
        uint256 acquisitions;
        uint256 mergers;
    }

    uint256 private _gameStartTime;
    uint256 private _mergerBurnPercentage;
    uint256 private _withdrawalBurnPercentage;
    ImmunityPeriods private _immunityPeriods;
    FoundingParameters private _foundingParameters;
    PassiveRpParameters private _passiveRpPerDay;
    IMerkleProofVerifier private _verifier;
    IERC20Upgradeable private _weth;
    IRunwayPoints private _runwayPoints;
    ICompete private _compete;
    ICost private _acquireCost;
    ICost private _mergeCost;
    ICost private _fundraiseCost;
    IERC1155Burnable private _consumables;
    IBranding private _fallbackBranding;
    mapping(address => bool) private _hasFoundedFree;
    mapping(string => bool) private _nameInUse;
    mapping(IBranding => bool) private _supportForBranding;

    mapping(uint256 => Enterprise) internal _enterprises;
    uint256 internal _reservedCount;
    uint256 internal _freeCount;
    uint256 internal _auctionCount;

    // auctioned = 0-8999
    uint256 private constant MAX_AUCTIONED = 9000;
    // free = 9000-13999
    uint256 private constant MAX_FREE = 5000;
    // reserved = 14000-14999
    uint256 private constant MAX_RESERVED = 1000;
    // percentages represented as 8 decimal place values.
    uint256 private constant PERCENT_DENOMINATOR = 10000000000;

    address private _admin;
    ICost private _acquireRpCost;
    ICost private _mergeRpCost;
    ICost private _acquireRpReward;
    uint8 private _fundingMode; // 0 = Support both; 1 = RP only; 2 = Matic only
    IAcqrHook internal _hook;

    bool public _paused;

    function initialize(
        string memory _newName,
        string memory _newSymbol,
        address _newVerifier,
        address _newWeth,
        address _newRunwayPoints,
        address _newConsumables
    ) public initializer {
        __ERC721_init(_newName, _newSymbol);
        __Ownable_init();
        // default rp passive accumulation rates
        _passiveRpPerDay.max = 2e19; // 20 max rp/day
        _passiveRpPerDay.base = 1e18; // 1 base rp/day
        _passiveRpPerDay.acquisitions = 2e18; // 2 rp/day per acquisition
        _passiveRpPerDay.mergers = 1e18; // 1 rp/day per merger
        _withdrawalBurnPercentage = 2500000000; // 25%
        _verifier = IMerkleProofVerifier(_newVerifier);
        _weth = IERC20Upgradeable(_newWeth);
        _runwayPoints = IRunwayPoints(_newRunwayPoints);
        _consumables = IERC1155Burnable(_newConsumables);
    }

    function foundReserved(address _recipient) external override nonReentrant {
        require(
            msg.sender == owner() || msg.sender == _admin,
            "caller is not owner or admin"
        );
        uint256 _id;
        if (_freeCount < MAX_FREE) {
            _id = MAX_AUCTIONED + _freeCount;
            _freeCount++;
        } else {
            _supplyCheck(_reservedCount, MAX_RESERVED);
            _id = MAX_AUCTIONED + MAX_FREE + _reservedCount;
            _reservedCount++;
        }
        _safeMint(_recipient, _id);
        _enterprises[_id].name = string(
            abi.encodePacked("Enterprise #", _toString(_id))
        );
        _enterprises[_id].revivalImmunityStartTime = block.timestamp;
        _enterprises[_id].branding = _fallbackBranding;
    }

    function foundAuctioned(uint256 _quantity)
        external
        payable
        override
        nonReentrant
    {
        _publicFoundingCheck();
        require(_quantity > 0, "amount cannot be zero");
        _supplyCheck((_auctionCount + _quantity), MAX_AUCTIONED + 1);
        uint256 _totalPrice;
        if (msg.sender != owner()) {
            require(
                block.timestamp <= _foundingParameters.endTime,
                "founding has ended"
            );
            _totalPrice = getAuctionPrice() * _quantity;
            _fundsCheck(msg.value, _totalPrice);
            payable(owner()).transfer(_totalPrice);
        }
        // send back excess MATIC even if owner is minting
        if (msg.value > _totalPrice) {
            payable(msg.sender).transfer(msg.value - _totalPrice);
        }
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 _id = _auctionCount;
            _auctionCount++;
            _safeMint(msg.sender, _id);
            _enterprises[_id].name = string(
                abi.encodePacked("Enterprise #", _toString(_id))
            );
            _enterprises[_id].revivalImmunityStartTime = block.timestamp;
            _enterprises[_id].branding = _fallbackBranding;
        }
    }

    function compete(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _rpToSpend
    ) external override {
        _checkIfPaused();
        _hostileActionCheck(msg.sender, _callerId, _targetId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_callerId);
        _updateEnterpriseRp(_targetId);
        uint256 _damage = _compete.getDamage(_callerId, _targetId, _rpToSpend);
        _competeUnchecked(_callerId, _targetId, _damage, _rpToSpend);
    }

    function competeAndAcquire(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _burnedId
    ) external payable override {
        _checkIfPaused();
        _hostileActionCheck(msg.sender, _callerId, _targetId);
        _validTargetCheck(_callerId, _targetId, _burnedId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_callerId);
        _updateEnterpriseRp(_targetId);
        uint256 _damage = _enterprises[_targetId].rp;
        uint256 _rpToSpend =
            _compete.getRpRequiredForDamage(_callerId, _targetId, _damage);
        _competeUnchecked(_callerId, _targetId, _damage, _rpToSpend);
        _acquireUnchecked(_callerId, _targetId, _burnedId, msg.value);
    }

    function merge(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _burnedId
    ) external payable override nonReentrant {
        _checkIfPaused();
        _selfActionCheck(msg.sender, _callerId, _targetId);
        _validTargetCheck(_callerId, _targetId, _burnedId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_callerId);
        _updateEnterpriseRp(_targetId);

        if (_isFundingNative(msg.value)) {
            /**
             * Skip reading from amountToRecipient because there is not a
             * another user involved in a merger. Ignore amountToBurn
             * because I do not foresee us wanting to burn MATIC.
             */
            (, uint256 _amountToTreasury, ) =
                _mergeCost.updateAndGetCost(_callerId, _targetId, 1);
            _fundsCheck(msg.value, _amountToTreasury);
            payable(owner()).transfer(_amountToTreasury);
            if (msg.value > _amountToTreasury) {
                payable(msg.sender).transfer(msg.value - _amountToTreasury);
            }
        } else {
            /**
             * Skip reading from amountToRecipient because there is not a
             * another user involved in a merger. Ignore amountToTreasury
             * since we probably will never want to send RP to the treasury.
             */
            (, , uint256 _amountToBurn) =
                _mergeRpCost.updateAndGetCost(_callerId, _targetId, 1);
            _runwayPoints.burnFrom(msg.sender, _amountToBurn);
        }

        _burn(_burnedId);
        uint256 _idToKeep = (_burnedId == _callerId) ? _targetId : _callerId;
        (uint256 _newCallerRpBalance, uint256 _newTargetRpBalance) =
            _hook.mergeHook(_callerId, _targetId, _burnedId);
        _enterprises[_callerId].rp = _newCallerRpBalance;
        _enterprises[_targetId].rp = _newTargetRpBalance;

        _enterprises[_idToKeep].mergers++;
        _enterprises[_idToKeep].mergerImmunityStartTime = block.timestamp;
        emit Merger(_callerId, _targetId, _burnedId);
    }

    function deposit(uint256 _enterpriseId, uint256 _amount)
        external
        override
        nonReentrant
    {
        _checkIfPaused();
        _enterpriseOwnerCheck(msg.sender, _enterpriseId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_enterpriseId);
        _runwayPoints.burnFrom(msg.sender, _amount);
        _enterprises[_enterpriseId].rp = _hook.depositHook(
            _enterpriseId,
            _amount
        );
        emit Deposit(_enterpriseId, _amount);
    }

    function withdraw(uint256 _enterpriseId, uint256 _amount)
        external
        override
        nonReentrant
    {
        _checkIfPaused();
        _enterpriseOwnerCheck(msg.sender, _enterpriseId);
        // before any RP operations, update actual balances to match virtual balances
        _updateEnterpriseRp(_enterpriseId);
        (uint256 _newRpBalance, uint256 _rpToMint, uint256 _rpToBurn) =
            _hook.withdrawHook(_enterpriseId, _amount);
        _enterprises[_enterpriseId].rp = _newRpBalance;
        _runwayPoints.mint(msg.sender, _rpToMint);
        emit Withdrawal(_enterpriseId, _rpToMint, _rpToBurn);
    }

    function rename(uint256 _enterpriseId, string memory _name)
        external
        override
        nonReentrant
    {
        _checkIfPaused();
        if (msg.sender != owner()) {
            _enterpriseOwnerCheck(msg.sender, _enterpriseId);
            _consumableTokenCheck(msg.sender, 0);
            require(!_nameInUse[_name], "name in use");
            require(_verifyName(_name), "invalid name");
            _consumables.burn(msg.sender, 0, 1);
            _nameInUse[_name] = true;
        }
        _enterprises[_enterpriseId].name = _name;
        _enterprises[_enterpriseId].renames++;
        emit Rename(_enterpriseId, _name);
    }

    function rebrand(uint256 _enterpriseId, IBranding _branding)
        external
        override
        nonReentrant
    {
        _checkIfPaused();
        _enterpriseOwnerCheck(msg.sender, _enterpriseId);
        require(_supportForBranding[_branding], "branding not supported");
        if (msg.sender != owner()) {
            _consumableTokenCheck(msg.sender, 1);
            _consumables.burn(msg.sender, 1, 1);
        }
        _enterprises[_enterpriseId].branding = _branding;
        _enterprises[_enterpriseId].rebrands++;
        emit Rebrand(_enterpriseId, address(_branding));
    }

    function revive(uint256 _enterpriseId) external override nonReentrant {
        _checkIfPaused();
        require(!_exists(_enterpriseId), "enterprise already exists");
        require(
            _isEnterpriseMinted(_enterpriseId),
            "enterprise has not been minted"
        );
        if (msg.sender != owner()) {
            _consumableTokenCheck(msg.sender, 2);
            _consumables.burn(msg.sender, 2, 1);
        }
        _safeMint(msg.sender, _enterpriseId);
        _enterprises[_enterpriseId].rp = 0;
        _enterprises[_enterpriseId].revivalImmunityStartTime = block.timestamp;
        _enterprises[_enterpriseId].lastRpUpdateTime = block.timestamp;
        _enterprises[_enterpriseId].revives++;
        emit Revival(_enterpriseId);
    }

    function setGameStartTime(uint256 _startTime) external override onlyOwner {
        _gameStartTime = _startTime;
        emit GameStartTimeChanged(_gameStartTime);
    }

    function setFoundingPriceAndTime(
        uint256 _newFoundingStartPrice,
        uint256 _newFoundingEndPrice,
        uint256 _newFoundingStartTime,
        uint256 _newFoundingEndTime
    ) external override onlyOwner {
        require(
            _newFoundingStartPrice > _newFoundingEndPrice,
            "start price must be > end price"
        );
        require(
            _newFoundingEndTime > _newFoundingStartTime,
            "end time must be > start time"
        );
        _foundingParameters.startPrice = _newFoundingStartPrice;
        _foundingParameters.endPrice = _newFoundingEndPrice;
        _foundingParameters.startTime = _newFoundingStartTime;
        _foundingParameters.endTime = _newFoundingEndTime;
        emit FoundingPriceAndTimeChanged(
            _foundingParameters.startPrice,
            _foundingParameters.endPrice,
            _foundingParameters.startTime,
            _foundingParameters.endTime
        );
    }

    function setPassiveRpPerDay(
        uint256 _newMax,
        uint256 _newBase,
        uint256 _newAcquisitions,
        uint256 _newMergers
    ) external override onlyOwner {
        _passiveRpPerDay.max = _newMax;
        _passiveRpPerDay.base = _newBase;
        _passiveRpPerDay.acquisitions = _newAcquisitions;
        _passiveRpPerDay.mergers = _newMergers;
        emit PassiveRpPerDayChanged(
            _passiveRpPerDay.max,
            _passiveRpPerDay.base,
            _passiveRpPerDay.acquisitions,
            _passiveRpPerDay.mergers
        );
    }

    function setImmunityPeriods(
        uint256 _acquisitionImmunityPeriod,
        uint256 _mergerImmunityPeriod,
        uint256 _revivalImmunityPeriod
    ) external override onlyOwner {
        _immunityPeriods.acquisition = _acquisitionImmunityPeriod;
        _immunityPeriods.merger = _mergerImmunityPeriod;
        _immunityPeriods.revival = _revivalImmunityPeriod;
        emit ImmunityPeriodsChanged(
            _immunityPeriods.acquisition,
            _immunityPeriods.merger,
            _immunityPeriods.revival
        );
    }

    function setMergerBurnPercentage(uint256 _percentage)
        external
        override
        onlyOwner
    {
        _mergerBurnPercentage = _percentage;
        emit MergerBurnPercentageChanged(_mergerBurnPercentage);
    }

    function setWithdrawalBurnPercentage(uint256 _percentage)
        external
        override
        onlyOwner
    {
        _withdrawalBurnPercentage = _percentage;
        emit WithdrawalBurnPercentageChanged(_withdrawalBurnPercentage);
    }

    function setCompete(address _newCompete) external override onlyOwner {
        _compete = ICompete(_newCompete);
        emit CompeteChanged(_newCompete);
    }

    function setCostContracts(
        address _newAcquireCost,
        address _newMergeCost,
        address _newAcquireRpCost,
        address _newMergeRpCost,
        address _newAcquireRpReward
    ) external override onlyOwner {
        _acquireCost = ICost(_newAcquireCost);
        _mergeCost = ICost(_newMergeCost);
        _acquireRpCost = ICost(_newAcquireRpCost);
        _mergeRpCost = ICost(_newMergeRpCost);
        _acquireRpReward = ICost(_newAcquireRpReward);
        emit CostContractsChanged(
            _newAcquireCost,
            _newMergeCost,
            _newAcquireRpCost,
            _newMergeRpCost,
            _newAcquireRpReward
        );
    }

    function setSupportForBranding(address _branding, bool _support)
        external
        override
        onlyOwner
    {
        _supportForBranding[IBranding(_branding)] = _support;
        emit SupportForBrandingChanged(_branding, _support);
    }

    function setFallbackBranding(address _newFallbackBranding)
        external
        override
        onlyOwner
    {
        _fallbackBranding = IBranding(_newFallbackBranding);
        emit FallbackBrandingChanged(_newFallbackBranding);
    }

    function setAdmin(address _newAdmin) external override onlyOwner {
        _admin = _newAdmin;
    }

    function setFundingMode(uint8 _mode) external override onlyOwner {
        _fundingMode = _mode;
    }

    function setHook(address _newHook) external override onlyOwner {
        _hook = IAcqrHook(_newHook);
    }

    function setPaused(bool _pause) external onlyOwner {
        _paused = _pause;
    }

    function reclaimFunds() external override onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function burnRP(address _account, uint256 _amount) external onlyOwner {
        _runwayPoints.burnFrom(_account, _amount);
    }

    function getRunwayPoints() external view override returns (IRunwayPoints) {
        return _runwayPoints;
    }

    function getCompete() external view override returns (ICompete) {
        return _compete;
    }

    function getCostContracts()
        external
        view
        override
        returns (
            ICost acquireCost_,
            ICost mergeCost_,
            ICost acquireRpCost_,
            ICost mergeRpCost_,
            ICost acquireRpReward_
        )
    {
        return (
            _acquireCost,
            _mergeCost,
            _acquireRpCost,
            _mergeRpCost,
            _acquireRpReward
        );
    }

    function isNameInUse(string memory _name)
        external
        view
        override
        returns (bool)
    {
        return _nameInUse[_name];
    }

    function isBrandingSupported(IBranding _branding)
        external
        view
        override
        returns (bool)
    {
        return _supportForBranding[_branding];
    }

    function getConsumables()
        external
        view
        override
        returns (IERC1155Burnable)
    {
        return _consumables;
    }

    function getArtist(uint256 _enterpriseId)
        external
        view
        override
        returns (string memory)
    {
        return
            _revertToFallback(_enterpriseId)
                ? _fallbackBranding.getArtist()
                : _enterprises[_enterpriseId].branding.getArtist();
    }

    function getFallbackBranding() external view override returns (IBranding) {
        return _fallbackBranding;
    }

    function getReservedCount() external view override returns (uint256) {
        return _reservedCount;
    }

    function getFreeCount() external view override returns (uint256) {
        return _freeCount;
    }

    function getAuctionCount() external view override returns (uint256) {
        return _auctionCount;
    }

    function getGameStartTime() external view override returns (uint256) {
        return _gameStartTime;
    }

    function getFoundingPriceAndTime()
        external
        view
        override
        returns (
            uint256 _startPrice,
            uint256 _endPrice,
            uint256 _startTime,
            uint256 _endTime
        )
    {
        return (
            _foundingParameters.startPrice,
            _foundingParameters.endPrice,
            _foundingParameters.startTime,
            _foundingParameters.endTime
        );
    }

    function getPassiveRpPerDay()
        external
        view
        override
        returns (
            uint256 _max,
            uint256 _base,
            uint256 _acquisitions,
            uint256 _mergers
        )
    {
        return (
            _passiveRpPerDay.max,
            _passiveRpPerDay.base,
            _passiveRpPerDay.acquisitions,
            _passiveRpPerDay.mergers
        );
    }

    function getImmunityPeriods()
        external
        view
        override
        returns (
            uint256 _acquisition,
            uint256 _merger,
            uint256 _revival
        )
    {
        return (
            _immunityPeriods.acquisition,
            _immunityPeriods.merger,
            _immunityPeriods.revival
        );
    }

    function getMergerBurnPercentage()
        external
        view
        override
        returns (uint256)
    {
        return _mergerBurnPercentage;
    }

    function getWithdrawalBurnPercentage()
        external
        view
        override
        returns (uint256)
    {
        return _withdrawalBurnPercentage;
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (address)
    {
        return _exists(_tokenId) ? super.ownerOf(_tokenId) : address(0);
    }

    function isMinted(uint256 _tokenId) external view override returns (bool) {
        if (
            _tokenId >= MAX_AUCTIONED + MAX_FREE &&
            _tokenId < MAX_AUCTIONED + MAX_FREE + MAX_RESERVED
        ) {
            return (_tokenId < MAX_AUCTIONED + MAX_FREE + _reservedCount);
        } else if (_tokenId >= MAX_AUCTIONED) {
            return (_tokenId < MAX_AUCTIONED + _freeCount);
        } else if (_tokenId >= 0) {
            return (_tokenId < _auctionCount);
        } else {
            return false;
        }
    }

    function hasFoundedFree(address _user)
        external
        view
        override
        returns (bool)
    {
        return _hasFoundedFree[_user];
    }

    function getMaxReserved() external pure override returns (uint256) {
        return MAX_RESERVED;
    }

    function getMaxFree() external pure override returns (uint256) {
        return MAX_FREE;
    }

    function getMaxAuctioned() external pure override returns (uint256) {
        return MAX_AUCTIONED;
    }

    function getEnterprise(uint256 _enterpriseId)
        external
        view
        override
        returns (Enterprise memory)
    {
        return _enterprises[_enterpriseId];
    }

    function getAdmin() external view override returns (address) {
        return _admin;
    }

    function getFundingMode() external view override returns (uint8) {
        return _fundingMode;
    }

    function getHook() external view override returns (IAcqrHook) {
        return _hook;
    }

    function tokenURI(uint256 _enterpriseId)
        public
        view
        override(ERC721Upgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        return
            _revertToFallback(_enterpriseId)
                ? _fallbackBranding.getArt(_enterpriseId)
                : _enterprises[_enterpriseId].branding.getArt(_enterpriseId);
    }

    function getAuctionPrice() public view override returns (uint256) {
        // round up to prevent a small enough range resulting in a decay of zero
        uint256 _decayPerSecond =
            (_foundingParameters.startPrice - _foundingParameters.endPrice) /
                (_foundingParameters.endTime - _foundingParameters.startTime) +
                1;
        uint256 _decay =
            _decayPerSecond *
                (block.timestamp - _foundingParameters.startTime);
        uint256 _auctionPrice;
        if (_decay > _foundingParameters.startPrice) {
            return _foundingParameters.endPrice;
        }
        _auctionPrice = _foundingParameters.startPrice - _decay;
        return
            _auctionPrice < _foundingParameters.endPrice
                ? _foundingParameters.endPrice
                : _auctionPrice;
    }

    function isEnterpriseImmune(uint256 _enterpriseId)
        public
        view
        override
        returns (bool)
    {
        uint256 _acquisitionImmunityEnd =
            _enterprises[_enterpriseId].acquisitionImmunityStartTime +
                _immunityPeriods.acquisition;
        uint256 _mergerImmunityEnd =
            _enterprises[_enterpriseId].mergerImmunityStartTime +
                _immunityPeriods.merger;
        uint256 _revivalImmunityEnd =
            _enterprises[_enterpriseId].revivalImmunityStartTime +
                _immunityPeriods.revival;
        return (_acquisitionImmunityEnd >= block.timestamp ||
            _mergerImmunityEnd >= block.timestamp ||
            _revivalImmunityEnd >= block.timestamp);
    }

    function getEnterpriseVirtualBalance(uint256 _enterpriseId)
        public
        view
        override
        returns (uint256)
    {
        // if balance has never been updated, use the game's start time
        uint256 _lastRpUpdateTime =
            (_enterprises[_enterpriseId].lastRpUpdateTime == 0)
                ? _gameStartTime
                : _enterprises[_enterpriseId].lastRpUpdateTime;
        uint256 _rpPerDay =
            _passiveRpPerDay.base +
                (_passiveRpPerDay.acquisitions *
                    _enterprises[_enterpriseId].acquisitions) +
                (_passiveRpPerDay.mergers *
                    _enterprises[_enterpriseId].mergers);
        _rpPerDay = (_rpPerDay > _passiveRpPerDay.max)
            ? _passiveRpPerDay.max
            : _rpPerDay;
        // divide rpPerDay by 86400 seconds in a day
        return
            _enterprises[_enterpriseId].rp +
            ((_rpPerDay * (block.timestamp - _lastRpUpdateTime)) / 86400);
    }

    function _competeUnchecked(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _damage,
        uint256 _rpToSpend
    ) private nonReentrant {
        (uint256 _newCallerRpBalance, uint256 _newTargetRpBalance) =
            _hook.competeHook(_callerId, _targetId, _damage, _rpToSpend);
        _enterprises[_callerId].rp = _newCallerRpBalance;
        _enterprises[_targetId].rp = _newTargetRpBalance;
        _enterprises[_callerId].competes += _rpToSpend;
        _enterprises[_callerId].damageDealt += _damage;
        _enterprises[_targetId].damageTaken += _damage;
        _enterprises[_callerId].acquisitionImmunityStartTime = 0;
        _enterprises[_callerId].mergerImmunityStartTime = 0;
        _enterprises[_callerId].revivalImmunityStartTime = 0;
        emit Compete(_callerId, _targetId, _rpToSpend, _damage);
    }

    function _acquireUnchecked(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _burnedId,
        uint256 _nativeSent
    ) private nonReentrant {
        if (_isFundingNative(_nativeSent)) {
            /**
             * Skip reading amountToBurn since we probably will never want to
             * burn native assets paid by the user.
             */
            (uint256 _amountToRecipient, uint256 _amountToTreasury, ) =
                _acquireCost.updateAndGetCost(_callerId, _targetId, 1);
            _fundsCheck(_nativeSent, _amountToRecipient + _amountToTreasury);
            if (_amountToRecipient != 0) {
                payable(ownerOf(_targetId)).transfer(_amountToRecipient);
            }
            if (_amountToTreasury != 0) {
                payable(owner()).transfer(_amountToTreasury);
            }
            if (_nativeSent > _amountToRecipient + _amountToTreasury) {
                payable(msg.sender).transfer(
                    _nativeSent - _amountToRecipient - _amountToTreasury
                );
            }
        } else {
            /**
             * Skip reading from amountToTreasury since we probably will never
             * want to send RP to the treasury.
             */
            (uint256 _amountToRecipient, , uint256 _amountToBurn) =
                _acquireRpCost.updateAndGetCost(_callerId, _targetId, 1);
            if (_amountToRecipient != 0) {
                _runwayPoints.transferFrom(
                    msg.sender,
                    ownerOf(_targetId),
                    _amountToRecipient
                );
            }
            if (_amountToBurn != 0) {
                _runwayPoints.burnFrom(msg.sender, _amountToBurn);
            }
        }
        /**
         * Read from amountToRecipient to determine the RP to mint for the
         * target Enterprise owner to compensate them for being acquired.
         */
        (uint256 _amountToReward, , ) =
            _acquireRpReward.updateAndGetCost(_callerId, _targetId, 1);
        if (_amountToReward != 0) {
            _runwayPoints.mint(ownerOf(_targetId), _amountToReward);
        }

        _burn(_burnedId);
        uint256 _idToKeep = (_burnedId == _callerId) ? _targetId : _callerId;
        if (_idToKeep == _targetId) {
            _transfer(ownerOf(_targetId), msg.sender, _targetId);
        }
        (uint256 _newCallerRpBalance, uint256 _newTargetRpBalance) =
            _hook.acquireHook(_callerId, _targetId, _burnedId, _nativeSent);
        _enterprises[_callerId].rp = _newCallerRpBalance;
        _enterprises[_targetId].rp = _newTargetRpBalance;
        _enterprises[_idToKeep].acquisitions++;
        _enterprises[_idToKeep].acquisitionImmunityStartTime = block.timestamp;
        emit Acquisition(_callerId, _targetId, _burnedId);
    }

    function _isFundingNative(uint256 _nativeSent)
        internal
        view
        returns (bool)
    {
        /**
         * If funding mode is MATIC only, but msg.value is 0, this check
         * will revert.
         */
        if (_nativeSent == 0 && (_fundingMode == 0 || _fundingMode == 1)) {
            return false;
        } else if (
            _nativeSent > 0 && (_fundingMode == 0 || _fundingMode == 2)
        ) {
            return true;
        }
        revert("Invalid funding method");
    }

    function _updateEnterpriseRp(uint256 _enterpriseId) private {
        _enterprises[_enterpriseId].rp = getEnterpriseVirtualBalance(
            _enterpriseId
        );
        _enterprises[_enterpriseId].lastRpUpdateTime = block.timestamp;
    }

    function _publicFoundingCheck() private view {
        require(
            _foundingParameters.startPrice != 0 &&
                _foundingParameters.endTime != 0 &&
                block.timestamp >= _foundingParameters.startTime,
            "founding has not started"
        );
    }

    function _checkIfPaused() private view {
        require(!_paused, "Game paused");
    }

    function _validTargetCheck(
        uint256 _callerId,
        uint256 _targetId,
        uint256 _burnedId
    ) private pure {
        require(
            _burnedId == _callerId || _burnedId == _targetId,
            "invalid burn target"
        );
    }

    function _hostileActionCheck(
        address _sender,
        uint256 _callerId,
        uint256 _targetId
    ) private view {
        _baseActionCheck(_sender, _callerId, _targetId);
        require(_exists(_targetId), "target enterprise doesn't exist");
        require(!isEnterpriseImmune(_targetId), "target enterprise is immune");
    }

    function _selfActionCheck(
        address _sender,
        uint256 _callerId,
        uint256 _targetId
    ) private view {
        _baseActionCheck(_sender, _callerId, _targetId);
        require(
            ownerOf(_targetId) == _sender,
            "not owner of target enterprise"
        );
    }

    function _baseActionCheck(
        address _sender,
        uint256 _callerId,
        uint256 _targetId
    ) private view {
        require(_callerId != _targetId, "enterprises are identical");
        _enterpriseOwnerCheck(_sender, _callerId);
    }

    function _enterpriseOwnerCheck(address _sender, uint256 _enterpriseId)
        private
        view
    {
        require(ownerOf(_enterpriseId) == _sender, "not enterprise owner");
    }

    function _consumableTokenCheck(address _sender, uint256 _id) private view {
        require(
            _consumables.balanceOf(_sender, _id) > 0,
            "caller is not token owner"
        );
    }

    function _fundsCheck(uint256 _given, uint256 _needed) private pure {
        require(_given >= _needed, "insufficient MATIC");
    }

    function _supplyCheck(uint256 _count, uint256 _max) private pure {
        require(_count < _max, "exceeds supply");
    }

    function _isEnterpriseMinted(uint256 _id) private view returns (bool) {
        return ((_id >= 0 && _id < _auctionCount) ||
            (_id >= MAX_AUCTIONED && _id < _freeCount + MAX_AUCTIONED) ||
            (_id >= MAX_AUCTIONED + MAX_FREE &&
                _id < _reservedCount + MAX_AUCTIONED + MAX_FREE));
    }

    function _revertToFallback(uint256 _enterpriseId)
        private
        view
        returns (bool)
    {
        try
            _enterprises[_enterpriseId].branding.getArt(_enterpriseId)
        returns (string memory _enterpriseArt) {
            if (
                (bytes(_enterpriseArt).length == 0) ||
                !_supportForBranding[_enterprises[_enterpriseId].branding]
            ) {
                return true;
            } else {
                return false;
            }
        } catch {
            return true;
        }
    }

    function _verifyName(string memory _name) private pure returns (bool) {
        bytes memory _nameInBytes = bytes(_name);
        if (_nameInBytes.length < 1) return false; // Cannot be empty
        if (_nameInBytes.length > 20) return false; // Cannot be longer than 20 characters
        if (_nameInBytes[0] == 0x20) return false; // Leading space
        if (_nameInBytes[_nameInBytes.length - 1] == 0x20) return false; // Trailing space

        bytes1 _lastChar = _nameInBytes[0];
        for (uint256 _i; _i < _nameInBytes.length; _i++) {
            bytes1 _char = _nameInBytes[_i];

            if (_char == 0x20 && _lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(_char >= 0x30 && _char <= 0x39) && //9-0
                !(_char >= 0x41 && _char <= 0x5A) && //A-Z
                !(_char >= 0x61 && _char <= 0x7A) && //a-z
                !(_char == 0x20) //space
            ) return false;

            _lastChar = _char;
        }
        return true;
    }

    function _toString(uint256 value) private pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    receive() external payable {
        revert("Direct transfers not supported");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "./IBranding.sol";
import "./ICompete.sol";
import "./ICost.sol";
import "./IRunwayPoints.sol";
import "./IMerkleProofVerifier.sol";
import "./IERC1155Burnable.sol";
import "./IAcqrHook.sol";

/**
 * Interface for the AcquisitionRoyale NFT game.
 */
interface IAcquisitionRoyale is
    IERC721MetadataUpgradeable,
    IERC721EnumerableUpgradeable
{
    struct Enterprise {
        string name;
        uint256 rp;
        uint256 lastRpUpdateTime;
        uint256 acquisitionImmunityStartTime;
        uint256 mergerImmunityStartTime;
        uint256 revivalImmunityStartTime;
        uint256 competes;
        uint256 acquisitions;
        uint256 mergers;
        IBranding branding;
        uint256 fundraiseRpTotal;
        uint256 fundraiseWethTotal;
        uint256 damageDealt;
        uint256 damageTaken;
        uint256 renames;
        uint256 rebrands;
        uint256 revives;
    }

    event GameStartTimeChanged(uint256 startTime);
    event FoundingPriceAndTimeChanged(
        uint256 startPrice,
        uint256 endPrice,
        uint256 startTime,
        uint256 endTime
    );
    event PassiveRpPerDayChanged(
        uint256 max,
        uint256 base,
        uint256 acquisitions,
        uint256 mergers
    );
    event ImmunityPeriodsChanged(
        uint256 acquisition,
        uint256 merger,
        uint256 revival
    );
    event MergerBurnPercentageChanged(uint256 percentage);
    event WithdrawalBurnPercentageChanged(uint256 percentage);
    event CompeteChanged(address compete);
    event CostContractsChanged(
        address acquireCost,
        address mergeCost,
        address acquireRpCost,
        address mergeRpCost,
        address acquireRpReward
    );
    event Compete(
        uint256 indexed callerId,
        uint256 indexed targetId,
        uint256 rpSpent,
        uint256 damage
    );
    event Acquisition(
        uint256 indexed callerId,
        uint256 indexed targetId,
        uint256 burnedId
    );
    event Merger(
        uint256 indexed callerId,
        uint256 indexed targetId,
        uint256 burnedId
    );
    event Fundraise(uint256 indexed enterpriseId, uint256 amount);
    event Deposit(uint256 indexed enterpriseId, uint256 amount);
    event Withdrawal(
        uint256 indexed enterpriseId,
        uint256 amountAfterFee,
        uint256 fee
    );
    event Rename(uint256 indexed enterpriseId, string name);
    event Rebrand(uint256 indexed enterpriseId, address branding);
    event Revival(uint256 indexed enterpriseId);
    event SupportForBrandingChanged(address branding, bool supported);
    event FallbackBrandingChanged(address branding);

    /** MINTING FUNCTIONS **/
    /**
     * Mints enterprises reserved for the treasury at no cost to it.
     * Can be called at any anytime, mints until supply of MAX_RESERVED + MAX_FREE is exhausted.
     * @dev The minting supply of this function was extended to include MAX_FREE after free claiming was deprecated.
     * function can only be called by owner().
     */
    function foundReserved(address recipient) external;

    /**
     * Mints enterprises for a cost determined by a 2-week falling price auction. Prices start at foundingStartPrice
     * and linearly fall to foundingEndPrice.
     * Can be called once founding has started and until founding period ends or supply of MAX_AUCTIONED is exhausted.
     */
    function foundAuctioned(uint256 quantity) external payable;

    /** IN-GAME ACTIONS **/
    /**
     * Reduces the RP of a target enterprise based on the amount of RP the caller spends. Calling enterprise loses its immmunity.
     * Cost to compete is RP spent from the caller's enterprise.
     */
    function compete(
        uint256 callerId,
        uint256 targetId,
        uint256 rpToSpend
    ) external;

    /**
     * Competes with enough RP to bring target RP balance to zero and acquires the target enterprise.
     * Compete/Acquire behavior is identical to the actions performed individually.
     */
    function competeAndAcquire(
        uint256 callerId,
        uint256 targetId,
        uint256 burnedId
    ) external payable;

    /**
     * Merges two caller-owned enterprises, specifying either enterprise to be burnt in the process.
     * Increases the merger count for the surviving enterprise by one. Surviving enterprise gains immunity.
     * Cost is denominated in native token and is determined by MergeCost.
     */
    function merge(
        uint256 callerId,
        uint256 targetId,
        uint256 burnedId
    ) external payable;

    /// Deposits RP from the senders wallet into a enterprise they own.
    function deposit(uint256 enterpriseId, uint256 amount) external;

    /// Withdraws RP from a enterprise they own into the sender's wallet.
    function withdraw(uint256 enterpriseId, uint256 amount) external;

    /**
     * Burn a rename token to change your enterprise name, must abide by the following rules:
     * name must be unique
     * max 20 characters
     * only letters or spaces
     * cannot start or end with a space
     * no consecutive spaces
     * @dev Owner can call this function to change an enterprise name without rename tokens.
     * Name verification is also ignored to allow governance to set inappropriate names blank.
     */
    function rename(uint256 enterpriseId, string memory name) external;

    /**
     * Burn a rebrand token to change your enterprise artwork
     * @dev Owner can call this function to rebrand their own enterprises without rebrand tokens.
     */
    function rebrand(uint256 enterpriseId, IBranding branding) external;

    /**
     * Burn a revive token to bring back a burnt enterprise under your ownership.
     * @dev Owner can call this function to revive an enterprise without revive tokens.
     */
    function revive(uint256 enterpriseId) external;

    /** SETTERS FOR GAME/MINTING RELATED VALUES **/
    /**
     * Sets the start time for the Acquisition Royale game.
     * Users are limited to using rebrand and rename until game has begun.
     * @dev function can only be called by owner(). New value must be greater than zero.
     */
    function setGameStartTime(uint256 startTime) external;

    /**
     * Sets the parameters to begin the founding period. Values provided cannot be zero.
     * Founding end price must be >= start price. Founding start time must be >= end time.
     * @dev function can only be called by owner().
     */
    function setFoundingPriceAndTime(
        uint256 newFoundingStartPrice,
        uint256 newFoundingEndPrice,
        uint256 newFoundingStartTime,
        uint256 newFoundingEndTime
    ) external;

    /**
     * Sets the parameters for how much rp enterprises will generate passively.
     * default 20 max rp/day, 1 base rp/day, 2 rp/day per acquisition, 1 rp/day per merger
     * @dev function can only be called by owner().
     */
    function setPassiveRpPerDay(
        uint256 newMaxRpPerDay,
        uint256 newBaseRpPerDay,
        uint256 newAcquisitionRpPerDay,
        uint256 newMergerRpPerDay
    ) external;

    /**
     * Sets the immunity periods for acquisitions, mergers, and revivals.
     * These periods will be added to their respective immunity start times and
     * compared against the current timestamp to determine if an Enterprise is immune.
     * @dev function can only be called by owner().
     */
    function setImmunityPeriods(
        uint256 acquisitionImmunityPeriod,
        uint256 mergerImmunityPeriod,
        uint256 revivalImmunityPeriod
    ) external;

    /**
     * Sets the percentage of the burned enterprise's RP to burn during a merger.
     * @dev function can only be called by owner().
     */
    function setMergerBurnPercentage(uint256 percentage) external;

    /**
     * Sets the percentage of the RP burned during a withdrawal from an enterprise.
     * Initialized to default value of 25%.
     * @dev function can only be called by owner().
     */
    function setWithdrawalBurnPercentage(uint256 percentage) external;

    /** SETTERS FOR GAME SPECIFIC COMPONENTS **/
    /**
     * Sets the contract implementing ICompete to determine the RP damage and cost of a Compete action.
     * @dev function can only be called by owner().
     */
    function setCompete(address newCompete) external;

    /**
     * Sets all contracts that implement the `ICost` interface, used for
     * determining the cost of in-game actions.
     * @dev function can only be called by owner().
     */
    function setCostContracts(
        address _newAcquireCost,
        address _newMergeCost,
        address _newAcquireRpCost,
        address _newMergeRpCost,
        address _newAcquireRpReward
    ) external;

    /**
     * Sets whether contract implementing IBranding is whitelisted for usage.
     * @dev function can only be called by owner().
     */
    function setSupportForBranding(address branding, bool support) external;

    /**
     * Sets the contract implementing our default enterprise artwork if a enterprise brand returns an empty string.
     * @dev function can only be called by owner().
     */
    function setFallbackBranding(address newFallbackBranding) external;

    /**
     * Sets the alternate account able to use foundReserved.
     * @dev function can only be called by owner().
     */
    function setAdmin(address newAdmin) external;

    /**
     * Sets whether to only allow RP for in-game actions, only MATIC, or
     * allow both to be used. 0 = both can be used (default); 1 = RP only;
     * 2 = MATIC only.
     * @dev function can only be called by owner().
     */
    function setFundingMode(uint8 mode) external;

    /**
     * Sets the contract implementing `IAcqrHook` containing functions that
     * are called during in-game actions `compete`, `merge`, and
     * `competeAndAcquire`.
     * @dev function can only be called by owner().
     */
    function setHook(address newHooks) external;

    /**
     * Returns any native token balances stuck on the contract to the owner()
     * @dev function can only be called by owner().
     */
    function reclaimFunds() external;

    /** GETTERS FOR GAME COMPONENTS **/
    /**
     * Returns contract implementing IRunwayPoints for the in-game RP currency.
     * @dev Not set by a setter function, initialized with the contract.
     */
    function getRunwayPoints() external view returns (IRunwayPoints);

    /// Returns the contract implementing ICompete to determine the RP damage and cost of a Compete action.
    function getCompete() external view returns (ICompete);

    /**
     * Returns the contracts that implement the `ICost` interface, used for
     * determining the cost of in-game actions.
     */
    function getCostContracts()
        external
        view
        returns (
            ICost acquireCost_,
            ICost mergeCost_,
            ICost acquireRpCost_,
            ICost mergeRpCost_,
            ICost acquireRpReward_
        );

    /// Returns true if name is taken, false if not.
    function isNameInUse(string memory name) external view returns (bool);

    /// Returns whether a contract is a whitelisted branding.
    function isBrandingSupported(IBranding branding)
        external
        view
        returns (bool);

    /**
     * Returns the contract implementing consumables to rename/rebrand/revive enterprises.
     * @dev Acquisition Royale assumes ERC1155 token id 0 => rename, 1 => rebrand, 2 => revive.
     */
    function getConsumables() external view returns (IERC1155Burnable);

    /// Returns the artist of the art selected for a enterprise.
    function getArtist(uint256 enterpriseId)
        external
        view
        returns (string memory);

    /// Returns the contract implementing our default enterprise artwork if a enterprise brand returns an empty string.
    function getFallbackBranding() external view returns (IBranding);

    /** GETTERS FOR GAME/MINTING RELATED VALUES **/
    /// Returns the number of enterprises reserved for the treasury that have been minted.
    function getReservedCount() external view returns (uint256);

    /// Returns the number of enterprises claimable by eligible addresses that have been minted.
    function getFreeCount() external view returns (uint256);

    /// Returns the number of enterprises purchasable through the falling price auction that have been minted.
    function getAuctionCount() external view returns (uint256);

    /// Returns the start time for the Acquisition Royale game.
    function getGameStartTime() external view returns (uint256);

    /// Returns the start price, end price, start timestamp, and end timestamp for the falling price auction.
    function getFoundingPriceAndTime()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /// Returns the maximum passive rp accumulation/day, base rp/day, rp per acquisition/day, rp per merger/day.
    function getPassiveRpPerDay()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * For each action, returns the immunity period given to an Enterprise for
     * performing that action.
     */
    function getImmunityPeriods()
        external
        view
        returns (
            uint256 acquisition,
            uint256 merger,
            uint256 revival
        );

    /// Returns the percentage of the burned enterprise's RP to burn during a merger.
    function getMergerBurnPercentage() external view returns (uint256);

    /// Returns the percentage of the RP burned during a withdrawal from an enterprise.
    function getWithdrawalBurnPercentage() external view returns (uint256);

    /// Returns the alternate account able to use foundReserved.
    function getAdmin() external view returns (address);

    /**
     * Returns whether to only allow RP for in-game actions, only MATIC, or
     * allow both to be used. 0 = Both can be used (default); 1 = RP Only;
     * 2 = MATIC only.
     */
    function getFundingMode() external view returns (uint8);

    /**
     * Gets the contract implementing `IAcqrHook` containing functions that
     * are called during in-game actions `compete`, `merge`, and
     * `competeAndAcquire`.
     */
    function getHook() external view returns (IAcqrHook);

    /**
     * Returns true if an enterprise has already been minted, even if it was
     * burnt. False if not.
     */
    function isMinted(uint256 tokenId) external view returns (bool);

    /** HELPER METHODS **/
    /// Returns true if eligible address has already minted a enterprise via foundFree(), false if not.
    function hasFoundedFree(address user) external view returns (bool);

    /// Returns attributes via the Enterprise struct for a specific enterprise.
    function getEnterprise(uint256 enterpriseId)
        external
        view
        returns (Enterprise memory);

    /**
     * Returns the current price for minting a enterprise via the falling price auction.
     * The price is a linear interpolation between start and end price, over the timespan between start and end time.
     * The price cannot be lower than the end price.
     */
    function getAuctionPrice() external view returns (uint256);

    /**
     * Determines whether a enterprise is immune based on its acquisitionImmunityStartTime, mergerImmmunityStartTime,
     * and their respective immunity periods. Compares the maximum of both values with the current timestamp.
     * Returns true if immune, false if not.
     */
    function isEnterpriseImmune(uint256 enterpriseId)
        external
        view
        returns (bool);

    /**
     * @notice Returns the RP of an Enterprise including amounts passively earned since the last performed action.
     * @dev Enterprises accumulate RP passively from a base amount + amount earned for acquisitions/mergers.
     * This RP is calculated lazily, meaning that amounts earned from passive income are not updated on-chain
     * until an Enterprise is involved in an action.
     */
    function getEnterpriseVirtualBalance(uint256 enterpriseId)
        external
        view
        returns (uint256);

    /** CONTRACT CONSTANTS **/
    /// Maximum supply of enterprises reserved for the treasury, set to 10000.
    function getMaxReserved() external pure returns (uint256);

    /// Maximum supply of enterprises claimable for free by eligible addresses, set to 5000.
    function getMaxFree() external pure returns (uint256);

    /// Maximum supply of enterprises purchasable through the falling price auction, set to 5000.
    function getMaxAuctioned() external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

interface IAcqrHook {
    /**
     * A hook containing core RP calculation logic for mergers. Called after
     * the action has been paid for and an enterprise has been burnt. The
     * AcquisitionRoyale contract will update the caller's and target's
     * enterprise balances with the values returned by this hook.
     * @dev Any additional functionality should be included in this hook along
     * with the base merger logic.
     * Only the AcquisitionRoyale contract may call this hook.
     */
    function mergeHook(
        uint256 callerId,
        uint256 targetId,
        uint256 burnedId
    )
        external
        returns (uint256 newCallerRpBalance, uint256 newTargetRpBalance);

    /**
     * A hook containing core RP calculation logic for competes. Called after
     * damage to be dealt is calculated based on the amount of RP provided.
     * The AcquisitionRoyale contract will update the caller's and target's
     * enterprise balances with the values returned by this hook.
     * @dev Any additional functionality should be included in this hook along
     * with the base compete logic.
     * Only the AcquisitionRoyale contract may call this hook.
     */
    function competeHook(
        uint256 callerId,
        uint256 targetId,
        uint256 damage,
        uint256 rpToSpend
    )
        external
        returns (uint256 newCallerRpBalance, uint256 newTargetRpBalance);

    /**
     * A hook containing core RP calculation logic for acquisitions. Called
     * after the action has been paid for and enterprises have been
     * transferred/burnt. The AcquisitionRoyale contract will update the
     * caller's and target's enterprise balances with the values returned by
     * this hook.
     * @dev Any additional functionality should be included in this hook along
     * with the base acquisition logic.
     * Only the AcquisitionRoyale contract may call this hook.
     */
    function acquireHook(
        uint256 callerId,
        uint256 targetId,
        uint256 burnedId,
        uint256 nativeSent
    )
        external
        returns (uint256 newCallerRpBalance, uint256 newTargetRpBalance);

    /**
     * A hook containing core RP calculation logic for deposits. Called
     * after the enterprise's balance has been updated with any RP accumulated
     * passively. The AcquisitionRoyale contract will update the enterprise's
     * balance with the value returned by this hook.
     * @dev Any additional functionality should be included in this hook along
     * with the base deposit logic.
     * Only the AcquisitionRoyale contract may call this hook.
     */
    function depositHook(uint256 enterpriseId, uint256 amount)
        external
        returns (uint256);

    /**
     * A hook containing core RP calculation logic for withdrawals. Called
     * after the enterprise's balance has been updated with any RP accumulated
     * passively. The AcquisitionRoyale contract will update the enterprise's
     * balance with the value returned by this hook.
     * @dev Any additional functionality should be included in this hook along
     * with the base withdrawal logic.
     * Only the AcquisitionRoyale contract may call this hook.
     */
    function withdrawHook(uint256 enterpriseId, uint256 amount)
        external
        returns (
            uint256 newCallerRpBalance,
            uint256 rpToMint,
            uint256 rpToBurn
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

interface IBranding {
    function getArt(uint256 tokenId) external view returns (string memory);

    function getArtist() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

interface ICompete {
    function getDamage(
        uint256 callerId,
        uint256 recipientId,
        uint256 rpToSpend
    ) external returns (uint256);

    function getRpRequiredForDamage(
        uint256 callerId,
        uint256 recipientId,
        uint256 damage
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

interface ICost {
    function getCost(uint256 callerId, uint256 recipientId)
        external
        view
        returns (
            uint256 amountToRecipient,
            uint256 amountToTreasury,
            uint256 amountToBurn
        );

    function updateAndGetCost(
        uint256 callerId,
        uint256 recipientId,
        uint256 actionCount
    )
        external
        returns (
            uint256 amountToRecipient,
            uint256 amountToTreasury,
            uint256 amountToBurn
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRunwayPoints is IERC20 {
    function mint(address recipient, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

interface IMerkleProofVerifier {
    function verify(address account, bytes32[] memory proof)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

interface IERC1155Burnable is IERC1155, IERC1155MetadataURI {
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}