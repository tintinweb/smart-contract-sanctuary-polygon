// SPDX-License-Identifier: MIT

/*
______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
 | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
 |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
_| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                     ________
                     ___  __ )_____ ______ _________________
                     __  __  |_  _ \_  __ `/__  ___/__  ___/
                     _  /_/ / /  __// /_/ / _  /    _(__  )
                     /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./BSBBaseGameModeUpgradeable.sol";
import "../shared/chainlink/VRFConsumerBaseUpgradeable.sol";
import "../../collections/child/interface/IBSBBloodShard.sol";

contract BSBForestUpgradeable is Initializable, BSBBaseGameModeUpgradeable, VRFConsumerBaseUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct ImpactType {
        uint yieldBoost;
        uint riskReduction;
        uint bloodShardBoost;
    }

    uint[] public levelMilestones;
    mapping(uint => ImpactType) public levelImpacts;

    uint private vrfFee;
    bytes32 private vrfKeyHash;
    uint private seed;

    uint constant public gen1HouseHoldBonusPercentage = 80;
    uint constant public fullHouseHoldBonusPercentage = 100;
    uint constant public tokenGeneratorWithBuffBonusPercentage = 100;
    uint constant public houseHoldBasePercentage = 25;
    uint constant public baseRisk = 50;
    uint constant public treeHouseEnrollYieldBuff = 30;
    uint constant public mintPassYieldBuff = 10;
    uint constant public baseStaminaYield = 5;
    uint constant public mintPassStaminaBuff = 2;
    uint constant public treeHouseStaminaBuff = 5;
    uint constant public staminaDaysRate = 1;
    uint constant public metaPassRiskReductionPercentage = 5;
    uint constant public minimumYieldRisk = 10;

    mapping(address => mapping(uint256 => uint256)) public tokenHouseMapping;
    mapping(address => mapping(uint256 => bool)) public tokenHouseAppartenance;
    mapping(uint256 => mapping(address => EnumerableSetUpgradeable.UintSet)) houseEnrollments;

    event BloodTokensStolen(address from, address to, uint amount, address collection, uint winnerToken);
    event BloodTokensClaimed(address collection, uint tokenId, uint amount);
    event SeedFulfilled();

    function __BSBForest_init(
        address linkTokenAddr_,
        address vrfCoordinatorAddr_,
        bytes32 vrfKeyHash_,
        uint vrfFee_
    ) public initializer {
        __BSBBaseGameMode_init();
        __VRFConsumerBase_init(vrfCoordinatorAddr_, linkTokenAddr_);
        vrfKeyHash = vrfKeyHash_;
        vrfFee = vrfFee_;
    }

    // ACTIONS
    function enroll(CollectionItems[] memory collectionItems_) external whenNotPaused {
        for (uint i = 0; i < collectionItems_.length; ++i) {
            _checkIfAllowedToStake(collectionItems_[i], _msgSender());
            _addToElitesIfNecessary(collectionItems_[i]);
            _stakeItems(collectionItems_[i], _msgSender());
        }

        BSBStorageCaller.stakeAssets(collectionItems_, _msgSender());
    }

    function disEnroll(CollectionItems[] memory collectionItems_) external whenNotPaused {
        bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(_msgSender()) != 0;

        uint accumulatedYield_;
        for (uint i = 0; i < collectionItems_.length; ++i) {
            accumulatedYield_ += _claimRewards(collectionItems_[i], applyBuff_);
            _removeFromElitesAndUnstackIfNecessary(collectionItems_[i]);
            _unStakeItems(collectionItems_[i], _msgSender());
        }
        BSBBloodTokenCaller.mint(_msgSender(), accumulatedYield_ * ETHER);

        BSBStorageCaller.unStakeAssets(collectionItems_, _msgSender());

        delete applyBuff_;
        delete accumulatedYield_;
    }

    function stackInHouse(CollectionItems[] memory collectionItems_, uint256 houseId_) external whenNotPaused returns(uint) {
        _checkIfOwnsItem(contracts["treeHouse"], houseId_, _msgSender());

        bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(_msgSender()) != 0;
        TreeHouseStats memory treeHouseStats = BSBStorageCaller.getTreeHouseStats(houseId_);

        uint accumulatedYield_;
        for (uint i = 0; i < collectionItems_.length; ++i) {
            CollectionItems memory item = collectionItems_[i];
            _checkIfOwnsItems(item, _msgSender());
            address collection = item.collection;
            require(
                collection == contracts["gen0"] ||
                collection == contracts["gen1"] ||
                collection == contracts["tokenGenerator"],
                "FRS:1"
            );

            require(
                item.assets.length + getTreeHouseOccupancy(houseId_) <= treeHouseStats.size.value,
                "FRS:2"
            );

            accumulatedYield_ += _claimRewards(item, applyBuff_);

            for (uint j = 0; j < item.assets.length; ++j) {
                _stackToken(collection, item.assets[j], houseId_);
            }
        }
        BSBBloodTokenCaller.mint(_msgSender(), accumulatedYield_ * ETHER);

        delete applyBuff_;
        delete treeHouseStats;

        return accumulatedYield_;
    }

    function unStackFromHouse(CollectionItems[] memory collectionItems_) external whenNotPaused returns(uint){
        bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(_msgSender()) != 0;

        uint accumulatedYield_;
        for (uint i = 0; i < collectionItems_.length; ++i) {
            CollectionItems memory item = collectionItems_[i];
            _checkIfOwnsItems(item, _msgSender());

            accumulatedYield_ += _claimRewards(item, applyBuff_);

            for (uint j = 0; j < item.assets.length; ++j) {
                _unstackToken(item.collection, item.assets[j]);
            }
        }
        BSBBloodTokenCaller.mint(_msgSender(), accumulatedYield_ * ETHER);

        delete applyBuff_;
        return accumulatedYield_;
    }

    function claimRewards(CollectionItems[] memory collectionItems_) public override whenNotPaused {
        uint accumulatedYield_;
        bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(_msgSender()) != uint(0);

        for (uint i = 0; i < collectionItems_.length; ++i) {
            _checkIfOwnsItems(collectionItems_[i], _msgSender());
            accumulatedYield_ += _claimRewards(collectionItems_[i], applyBuff_);
        }

        delete applyBuff_;

        BSBBloodTokenCaller.mint(_msgSender(), accumulatedYield_ * ETHER);
    }

    function calculateBearRewards(address collection_, uint[] calldata tokenIds_) external view returns (uint[] memory, uint[] memory) {
        uint[] memory yieldRewards = new uint[](tokenIds_.length);
        uint[] memory staminaRewards = new uint[](tokenIds_.length);
        BearStats[] memory bearsStats = BSBStorageCaller.getBearsStats(collection_, tokenIds_);
        for (uint64 i = 0; i < tokenIds_.length; ++i) {
            bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(tokenOwners[collection_][tokenIds_[i]]) != 0;
            yieldRewards[i] = _calculateBearYield(collection_, tokenIds_[i], applyBuff_, collectionsYield[collection_], bearsStats[i].level.value);
            staminaRewards[i] = _calculateBearAccumulatedStamina(collection_, tokenIds_[i], applyBuff_, bearsStats[i].stamina);
        }
        return (yieldRewards, staminaRewards);
    }

    function calculateTreeHouseRewards(uint[] calldata tokenIds_) external view returns (uint[] memory) {
        uint[] memory yieldRewards = new uint[](tokenIds_.length);
        address collection_ = contracts["treeHouse"];
        for (uint64 i = 0; i < tokenIds_.length; ++i) {
            uint256 tokenId_ = tokenIds_[i];
            bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(tokenOwners[collection_][tokenId_]) != 0;
            yieldRewards[i] = _calculateTreeHouseYield(
                tokenId_,
                collection_,
                collectionsYield[collection_],
                applyBuff_
            );
        }
        return yieldRewards;
    }

    function calculateTokenGeneratorRewards(uint[] calldata tokenIds_) external view returns (uint[] memory) {
        uint[] memory yieldRewards = new uint[](tokenIds_.length);
        address collection_ = contracts["tokenGenerator"];
        for (uint64 i = 0; i < tokenIds_.length; ++i) {
            uint256 tokenId_ = tokenIds_[i];
            bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(tokenOwners[collection_][tokenId_]) != 0;
            yieldRewards[i] = tokenHouseAppartenance[collection_][tokenIds_[i]] ? _calculateTokenGeneratorYield(
                tokenId_,
                collection_,
                collectionsYield[collection_],
                applyBuff_
            ) : 0;
        }
        return yieldRewards;
    }

    function calculateDailyYieldForBears(address collection_, uint[] calldata tokenIds_) external view returns (uint[] memory) {
        uint[] memory dailyYields = new uint[](tokenIds_.length);
        BearStats[] memory bearsStats = BSBStorageCaller.getBearsStats(collection_, tokenIds_);
        for (uint i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId_ = tokenIds_[i];
            bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(tokenOwners[collection_][tokenId_]) != 0;
            dailyYields[i] = _calculateDailyYieldWithBonus(
                collection_,
                collectionsYield[collection_],
                tokenId_,
                applyBuff_,
                bearsStats[i].level.value
            );
        }
        return dailyYields;
    }

    function calculateStaminaIncreaseRate(address wallet) external view returns (uint) {
        return _calculateStaminaIncreaseRate(
            BSBMintPassBuffCaller.getBuffBalance(wallet) != uint(0)
        );
    }

    function getHouseEnrolments(
        uint tokenId_
    ) external view returns(
        uint[] memory,
        uint[] memory,
        uint[] memory
    ) {
        EnumerableSetUpgradeable.UintSet storage gen0Enrolled = houseEnrollments[tokenId_][contracts["gen0"]];
        EnumerableSetUpgradeable.UintSet storage gen1Enrolled = houseEnrollments[tokenId_][contracts["gen1"]];
        EnumerableSetUpgradeable.UintSet storage housesEnrolled = houseEnrollments[tokenId_][contracts["tokenGenerator"]];

        uint[] memory gen0Enrolments = new uint[](EnumerableSetUpgradeable.length(gen0Enrolled));
        uint[] memory gen1Enrolments = new uint[](EnumerableSetUpgradeable.length(gen1Enrolled));
        uint[] memory tokenGeneratorsEnrolments = new uint[](EnumerableSetUpgradeable.length(housesEnrolled));

        for (uint i = 0; i < EnumerableSetUpgradeable.length(gen0Enrolled); ++i){
            gen0Enrolments[i] = EnumerableSetUpgradeable.at(gen0Enrolled, i);
        }

        for (uint i = 0; i < EnumerableSetUpgradeable.length(gen1Enrolled); ++i){
            gen1Enrolments[i] = EnumerableSetUpgradeable.at(gen1Enrolled, i);
        }

        for (uint i = 0; i < EnumerableSetUpgradeable.length(housesEnrolled); ++i){
            tokenGeneratorsEnrolments[i] = EnumerableSetUpgradeable.at(housesEnrolled, i);
        }

        return (gen0Enrolments, gen1Enrolments, tokenGeneratorsEnrolments);
    }

    function isEnrolledForMany(address collection_, uint[] calldata tokenIds_) public view returns (bool[] memory) {
        bool[] memory enrolledStatuses = new bool[](tokenIds_.length);
        for(uint i = 0; i < tokenIds_.length; i++) {
            enrolledStatuses[i] = tokenHouseAppartenance[collection_][tokenIds_[i]];
        }
        return enrolledStatuses;
    }

    function getTreeHouseOccupancy(uint houseId_) public view returns (uint) {
        return EnumerableSetUpgradeable.length(houseEnrollments[houseId_][contracts["gen0"]]) +
        EnumerableSetUpgradeable.length(houseEnrollments[houseId_][contracts["gen1"]]) +
        EnumerableSetUpgradeable.length(houseEnrollments[houseId_][contracts["tokenGenerator"]]);
    }

    function getTokenGeneratorCapacities(uint[] calldata tokenIds_) external view returns (uint[] memory) {
        address collection_ = contracts["tokenGenerator"];
        uint[] memory tokenGeneratorBonuses = new uint[](tokenIds_.length);

        for (uint i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId_ = tokenIds_[i];
            bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(tokenOwners[collection_][tokenId_]) != 0;
            tokenGeneratorBonuses[i] = _getTokenGeneratorCapacity(collection_, tokenId_, applyBuff_);
        }

        return tokenGeneratorBonuses;
    }

    function getTreeHouseCapacities(uint[] calldata tokenIds_) external view returns (uint[] memory) {
        address collection_ = contracts["treeHouse"];
        uint[] memory treeHouseBonuses = new uint[](tokenIds_.length);

        for (uint i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId_ = tokenIds_[i];
            bool applyBuff_ = BSBMintPassBuffCaller.getBuffBalance(tokenOwners[collection_][tokenId_]) != 0;
            treeHouseBonuses[i] = _getTreeHouseBonus(tokenIds_[i], applyBuff_);
        }

        return treeHouseBonuses;
    }

    function getLevelImpact(uint level_) public view returns (ImpactType memory) {
        for (uint i = 0; i < levelMilestones.length; ++i) {
            if (level_ >= levelMilestones[levelMilestones.length - 1 - i]) {
                return levelImpacts[levelMilestones[levelMilestones.length - 1 - i]];
            }
        }

        return levelImpacts[0];
    }

    function setLevelImpacts(uint[] memory milestones_, ImpactType[] calldata impacts_) external onlyOwner {
        require(milestones_.length == impacts_.length, "FRS:3");

        levelMilestones = milestones_;

        for (uint i = 0; i < milestones_.length; i++) {
            levelImpacts[milestones_[i]] = impacts_[i];
        }
    }

    function initSeedGeneration() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= vrfFee, "FRS:4");
        return requestRandomness(vrfKeyHash, vrfFee);
    }

    function _addToElitesIfNecessary(CollectionItems memory collectionItem_) internal {
        if (collectionItem_.collection == contracts["gen0"] || collectionItem_.collection == contracts["gen1"]) {
            BearStats[] memory bearsStats = BSBStorageCaller.getBearsStats(
                collectionItem_.collection, collectionItem_.assets
            );

            for (uint i = 0; i < collectionItem_.assets.length; ++i) {
                if (bearsStats[i].isElite) {
                    _addEliteToPool(
                        collectionItem_.collection, collectionItem_.assets[i], bearsStats[i].faction, _msgSender()
                    );
                }
            }

            delete bearsStats;
        }
    }

    function _removeFromElitesAndUnstackIfNecessary(CollectionItems memory collectionItem_) internal {
        BearStats[] memory bearsStats;
        address collection_ = collectionItem_.collection;
        bool isBear = collection_ == contracts["gen0"] || collection_ == contracts["gen1"];
        if (isBear) {
            bearsStats = BSBStorageCaller.getBearsStats(collection_, collectionItem_.assets);
        }
        for (uint i = 0; i < collectionItem_.assets.length; ++i) {
            if (collection_ == contracts["treeHouse"]) {
                require(getTreeHouseOccupancy(collectionItem_.assets[i]) == 0, "FRS:5");
            } else if (tokenHouseAppartenance[collection_][collectionItem_.assets[i]]) {
                _unstackToken(collection_, collectionItem_.assets[i]);
            }
            if (isBear && bearsStats[i].isElite) {
                _removeEliteFromPool(collection_, collectionItem_.assets[i], bearsStats[i].faction);
            }
        }
        delete isBear;
        delete bearsStats;
    }

    function _stackToken(address collection_, uint tokenId_, uint houseId_) internal {
        require(!tokenHouseAppartenance[collection_][tokenId_], "FRS:6");
        tokenHouseAppartenance[collection_][tokenId_] = true;
        tokenHouseMapping[collection_][tokenId_] = houseId_;
        EnumerableSetUpgradeable.add(houseEnrollments[houseId_][collection_], tokenId_);
    }

    function _unstackToken(address collection_, uint tokenId_) internal {
        require(tokenHouseAppartenance[collection_][tokenId_], "FRS:7");
        EnumerableSetUpgradeable.remove(houseEnrollments[tokenHouseMapping[collection_][tokenId_]][collection_], tokenId_);
        delete tokenHouseMapping[collection_][tokenId_];
        delete tokenHouseAppartenance[collection_][tokenId_];
    }

    function _claimRewards(CollectionItems memory collectionItems_, bool applyBuff_) internal returns (uint) {
        uint accumulatedRewards_;
        address collection_ = collectionItems_.collection;

        if (collection_ == contracts["gen0"] || collection_ == contracts["gen1"]) {
            accumulatedRewards_ = _claimBearRewards(collectionItems_, applyBuff_);
        } else if (collection_ == contracts["treeHouse"]) {
            accumulatedRewards_ = _claimTreeHouseRewards(collectionItems_, applyBuff_);
        } else if (collection_ == contracts["tokenGenerator"]) {
            accumulatedRewards_ = _claimTokenGeneratorRewards(collectionItems_, applyBuff_);
        }

        delete collection_;

        return accumulatedRewards_;
    }

    function _claimTokenGeneratorRewards(
        CollectionItems memory collectionItems_,
        bool applyBuff_
    ) internal returns(uint) {

        uint256 accumulatedYield;
        address collectionAddress = collectionItems_.collection;
        uint[] memory collectionAssets = collectionItems_.assets;
        uint collectionBaseYield_ = collectionsYield[collectionAddress];

        for (uint i = 0; i < collectionAssets.length; ++i) {
            uint tokenId = collectionAssets[i];
            address collection_ = collectionAddress;
            if (tokenHouseAppartenance[collection_][tokenId]) {

                uint yield = _calculateTokenGeneratorYield(
                    tokenId,
                    collection_,
                    collectionBaseYield_,
                    applyBuff_
                );

                if (yield > 0) {
                    emit BloodTokensClaimed(collection_, tokenId, yield);
                }

                accumulatedYield += yield;
            }

            stateChangeDates[collection_][tokenId] = block.timestamp;

            delete collection_;
            delete tokenId;
        }

        return accumulatedYield;
    }

    function _calculateTokenGeneratorYield(
        uint tokenId_,
        address collection_,
        uint yield_,
        bool applyBuff_
    ) internal view returns (uint) {
        uint accumulatedYield_ = _calculateYieldForRate(collection_, tokenId_, yield_);

        return _getTokenGeneratorCapacity(collection_, tokenId_, applyBuff_) * accumulatedYield_ / 100;
    }

    function _getTokenGeneratorCapacity(
        address collection_,
        uint tokenId_,
        bool applyBuff_
    ) internal view returns (uint) {
        if (applyBuff_) {
            return tokenGeneratorWithBuffBonusPercentage;
        }
        uint treeHouseId_ = tokenHouseMapping[collection_][tokenId_];

        return _getTreeHouseBonus(treeHouseId_, applyBuff_);
    }

    function _claimTreeHouseRewards(CollectionItems memory collectionItems_, bool applyBuff_) internal returns (uint) {
        uint256 accumulatedYield;
        address collectionAddress = collectionItems_.collection;
        uint[] memory collectionAssets = collectionItems_.assets;
        uint collectionBaseYield_ = collectionsYield[collectionAddress];

        for (uint i = 0; i < collectionAssets.length; ++i) {
            uint tokenId = collectionAssets[i];

            uint yield = _calculateTreeHouseYield(
                tokenId,
                collectionAddress,
                collectionBaseYield_,
                applyBuff_
            );

            if (yield > 0) {
                emit BloodTokensClaimed(collectionAddress, tokenId, yield);
            }

            accumulatedYield += yield;

            stateChangeDates[collectionAddress][tokenId] = block.timestamp;
        }

        return accumulatedYield;
    }

    function _calculateTreeHouseYield(
        uint tokenId_,
        address collection_,
        uint yield_,
        bool applyBuff_
    ) internal view returns (uint) {
        uint accumulatedYield_ = _calculateYieldForRate(collection_, tokenId_, yield_);

        return _getTreeHouseBonus(tokenId_, applyBuff_) * accumulatedYield_ / 100;
    }

    function _getTreeHouseBonus(uint tokenId_, bool applyBuff_) internal view returns (uint) {
        if (applyBuff_ || EnumerableSetUpgradeable.length(houseEnrollments[tokenId_][contracts["gen0"]]) > 0) {
            return fullHouseHoldBonusPercentage;
        } else if (EnumerableSetUpgradeable.length(houseEnrollments[tokenId_][contracts["gen1"]]) > 0) {
            return gen1HouseHoldBonusPercentage;
        }

        return houseHoldBasePercentage;
    }

    function _claimBearRewards(CollectionItems memory collectionItems_, bool applyBuff_) internal returns (uint) {
        uint256 accumulatedYield;

        uint collectionBaseYield_ = collectionsYield[collectionItems_.collection];
        address collectionAddress = collectionItems_.collection;
        uint[] memory collectionAssets = collectionItems_.assets;

        BearStats[] memory bearStats = BSBStorageCaller.getBearsStats(
            collectionAddress,
            collectionAssets
        );

        for (uint i = 0; i < collectionAssets.length; ++i) {
            uint tokenId = collectionAssets[i];
            uint yield = _applyRisk(
                tokenId,
                bearStats[i].faction,
                _calculateBearYield(
                    collectionAddress,
                    tokenId,
                    applyBuff_,
                    collectionBaseYield_,
                    bearStats[i].level.value
                ),
                bearStats[i].level.value,
                applyBuff_
            );
            if (yield > 0) {
                emit BloodTokensClaimed(collectionAddress, tokenId, yield);
            }
            accumulatedYield += yield;

            bearStats[i].stamina.value += _calculateBearAccumulatedStamina(
                collectionAddress, tokenId, applyBuff_, bearStats[i].stamina
            );

            BSBStorageCaller.setBearStats(collectionAddress, tokenId, bearStats[i]);

            stateChangeDates[collectionAddress][tokenId] = block.timestamp;
        }

        return accumulatedYield;
    }

    function _applyRisk(
        uint tokenId_,
        uint faction_,
        uint amount_,
        uint level_,
        bool applyBuff_
    ) internal returns(uint) {
        uint risk_ = (baseRisk - (applyBuff_ ? metaPassRiskReductionPercentage : 0)) * 100;

        uint levelImpactRiskReduction_ = getLevelImpact(level_).riskReduction;

        if (risk_ > levelImpactRiskReduction_) {
            risk_ -= levelImpactRiskReduction_;
        } else {
            risk_ = 0;
        }

        risk_ /= 100;
        risk_ = risk_ < minimumYieldRisk ? minimumYieldRisk : risk_;

        uint wonAmount = amount_;
        if (_pickPortionOutOfAmount(risk_, tokenId_, amount_)) {
            (address winner, address winnerCollection, uint winnerToken) = _pickWinnerFromElites(faction_, tokenId_);

            if (winner != address(0) && winner != _msgSender()) {
                emit BloodTokensStolen(_msgSender(), winner, amount_, winnerCollection, winnerToken);
                BSBBloodTokenCaller.mint(winner, amount_ * ETHER);

                wonAmount = 0;
            }

            delete winner;
            delete winnerCollection;
            delete winnerToken;
        }

        return wonAmount;
    }

    function _calculateBearYield(
        address collection_,
        uint tokenId_,
        bool applyBuff_,
        uint yield_,
        uint level_
    ) internal view returns (uint) {
        return _calculateYieldForRate(
            collection_,
            tokenId_,
            _calculateDailyYieldWithBonus(collection_, yield_, tokenId_, applyBuff_, level_)
        );
    }

    function _calculateDailyYieldWithBonus(
        address collection_,
        uint yield_,
        uint tokenId_,
        bool applyBuff_,
        uint level_
    ) internal view returns(uint) {
        uint percentageBonus = (applyBuff_ ? mintPassYieldBuff : 0) +
        (tokenHouseAppartenance[collection_][tokenId_] ? treeHouseEnrollYieldBuff : 0) +
        getLevelImpact(level_).yieldBoost;

        return yield_ + percentageBonus * yield_ / 100;
    }

    function _calculateStaminaIncreaseRate(bool applyBuff_) internal pure returns(uint) {
        return baseStaminaYield + (applyBuff_ ? mintPassStaminaBuff : 0);
    }

    function _calculateStaminaIncreaseRateWithHouseBuff(
        bool applyBuff_,
        address collection_,
        uint tokenId_
    ) internal view returns(uint) {
        return _calculateStaminaIncreaseRate(applyBuff_)
            + (tokenHouseAppartenance[collection_][tokenId_] ? treeHouseStaminaBuff : 0);
    }

    function _calculateBearAccumulatedStamina(
        address collection_,
        uint tokenId_,
        bool applyBuff_,
        Stat memory stamina_
    ) internal view returns (uint) {
        uint accumulatedStamina_ =
            (block.timestamp - stateChangeDates[collection_][tokenId_]) / (staminaDaysRate * DAYS) *
            _calculateStaminaIncreaseRateWithHouseBuff(applyBuff_, collection_, tokenId_);

        uint maximumAccumulatedStamina = stamina_.max - stamina_.value;

        return accumulatedStamina_ > maximumAccumulatedStamina ? maximumAccumulatedStamina : accumulatedStamina_;
    }

    function _pickWinnerFromElites(
        uint faction_,
        uint tokenId_
    ) internal view returns (address, address, uint) {
        address gen0Address = contracts["gen0"];
        address gen1Address = contracts["gen1"];
        EnumerableSetUpgradeable.UintSet storage gen0Elites = elites[faction_][gen0Address];
        EnumerableSetUpgradeable.UintSet storage gen1Elites = elites[faction_][gen1Address];

        uint gen0ElitesWeight_ = EnumerableSetUpgradeable.length(gen0Elites) * 3;
        uint elitesPoolSize_ = gen0ElitesWeight_ + EnumerableSetUpgradeable.length(gen1Elites);

        if (elitesPoolSize_ == uint(0)) {
            delete gen0Address;
            delete gen1Address;

            delete gen0ElitesWeight_;
            delete elitesPoolSize_;

            return (address(0), address(0), uint(0));
        }

        uint winnerWeightedIndex_ = _getRandom(elitesPoolSize_, tokenId_);

        delete elitesPoolSize_;

        uint winnerTokenId_;
        if (winnerWeightedIndex_ >= gen0ElitesWeight_) {
            winnerTokenId_ = EnumerableSetUpgradeable.at(
                gen1Elites, winnerWeightedIndex_ - gen0ElitesWeight_
            );
            return (elitesOwners[gen1Address][winnerTokenId_], gen1Address, winnerTokenId_);
        }

        delete gen1Address;
        delete gen0ElitesWeight_;

        winnerTokenId_ = EnumerableSetUpgradeable.at(
            gen0Elites, winnerWeightedIndex_ / 3
        );
        return (elitesOwners[gen0Address][winnerTokenId_], gen0Address, winnerTokenId_);
    }

    function _calculateYieldForRate(
        address collection_,
        uint tokenId_,
        uint yield_
    ) internal view returns (uint) {
        return (block.timestamp - stateChangeDates[collection_][tokenId_]) * yield_ / DAYS;
    }

    function _getRandom(uint max_, uint tokenId) internal view returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(
                    seed,
                    max_,
                    tokenId,
                    tx.origin,
                    blockhash(block.number - 1),
                    block.timestamp
                )
            )
        ) % max_;
    }

    function _pickPortionOutOfAmount(uint portion_, uint tokenId_, uint amount_) internal view returns (bool) {
        return uint(
            keccak256(
                abi.encodePacked(
                    seed,
                    tokenId_,
                    amount_,
                    tx.origin,
                    blockhash(block.number - 1),
                    block.timestamp)
            )
        ) % 100 < portion_;
    }

    function fulfillRandomness(bytes32, uint randomness) internal override {
        seed = randomness;
        emit SeedFulfilled();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./BSBBaseUpgradeable.sol";
import "../storage/interface/IBSBStorage.sol";
import "../storage/interface/IBSBTypes.sol";
import "../storage/interface/IBSBMintPassBuff.sol";
import "../../collections/child/interface/IBSBBloodToken.sol";

abstract contract BSBBaseGameModeUpgradeable is BSBBaseUpgradeable, IBSBTypes {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(string => address) public contracts;

    mapping(address => uint) public collectionsYield;

    mapping(address => mapping(uint256 => uint256)) public stateChangeDates;

    // faction => collection => elitesIds
    mapping(uint256 => mapping(address => EnumerableSetUpgradeable.UintSet)) elites;

    // collection => eliteId => owner
    mapping(address => mapping(uint256 => address)) public elitesOwners;

    // owner => collection => tokenIds
    mapping(address => mapping(address => EnumerableSetUpgradeable.UintSet)) stakedAssets;

    // collection => tokenId => owner
    mapping(address => mapping(uint => address)) public tokenOwners;

    EnumerableSetUpgradeable.AddressSet allowedStakeCollections;

    IBSBStorage BSBStorageCaller;
    IBSBBloodToken BSBBloodTokenCaller;
    IBSBMintPassBuff BSBMintPassBuffCaller;

    function __BSBBaseGameMode_init() public initializer {
        __BSBBase_init();
    }

//    function claimAllRewards() external whenNotPaused {
//        CollectionItems[] memory collectionItems = new CollectionItems[](EnumerableSetUpgradeable.length(allowedStakeCollections));
//        for (uint i = 0; i < collectionItems.length; i++) {
//            address collection = EnumerableSetUpgradeable.at(allowedStakeCollections, i);
//            collectionItems[i].collection = collection;
//            collectionItems[i].assets = new uint[](EnumerableSetUpgradeable.length(stakedAssets[_msgSender()][collection]));
//            for (uint j = 0; j < collectionItems[i].assets.length; j++) {
//                collectionItems[i].assets[j] = EnumerableSetUpgradeable.at(stakedAssets[_msgSender()][collection], j);
//            }
//        }
//        claimRewards(collectionItems);
//    }

//    function claimAllRewardsForCollection(address collection) external whenNotPaused {
//        require(EnumerableSetUpgradeable.contains(allowedStakeCollections, collection), "BGM:6");
//        CollectionItems memory collectionItems = CollectionItems({
//            collection: collection,
//            assets: new uint[](EnumerableSetUpgradeable.length(stakedAssets[_msgSender()][collection]))
//        });
//        for (uint i = 0; i < collectionItems.assets.length; i++) {
//            collectionItems.assets[i] = EnumerableSetUpgradeable.at(stakedAssets[_msgSender()][collection], i);
//        }
//        CollectionItems[] memory collections = new CollectionItems[](1);
//        collections[0] = collectionItems;
//        claimRewards(collections);
//    }

    function claimRewards(CollectionItems[] memory collectionItems_) public virtual;

    function getStakedAssets(address owner_, address collection_) external view returns(uint[] memory){
        uint[] memory stakedAssets_ =  new uint[](EnumerableSetUpgradeable.length(stakedAssets[owner_][collection_]));

        for (uint i = 0; i < stakedAssets_.length; ++i) {
            stakedAssets_[i] = EnumerableSetUpgradeable.at(stakedAssets[owner_][collection_], i);
        }

        return stakedAssets_;
    }

    function setContractAddresses(string[] calldata aliases_, address[] calldata addresses_) external onlyOwner {
        for (uint i = 0; i < aliases_.length; ++i) {
            contracts[aliases_[i]] = addresses_[i];
        }
    }

    function setAllowedStakeCollections(address[] calldata addresses_) external onlyOwner {
        for (uint i = 0; i < addresses_.length; ++i) {
            EnumerableSetUpgradeable.add(allowedStakeCollections, addresses_[i]);
        }
    }

    function removeAllowedStakeCollections(address[] calldata addresses_) external onlyOwner {
        for (uint i = 0; i < addresses_.length; ++i) {
            EnumerableSetUpgradeable.remove(allowedStakeCollections, addresses_[i]);
        }
    }

    function setStorageCaller(address address_) external onlyOwner {
        BSBStorageCaller = IBSBStorage(address_);
    }

    function setTokenCaller(address address_) external onlyOwner {
        BSBBloodTokenCaller = IBSBBloodToken(address_);
    }

    function setMintPassBuffCaller(address address_) external onlyOwner {
        BSBMintPassBuffCaller = IBSBMintPassBuff(address_);
    }

    function setCollectionsYield(
        address[] calldata addresses_,
        uint[] calldata yields_
    ) external onlyOwner {
        for (uint i = 0; i < addresses_.length; ++i) {
            collectionsYield[addresses_[i]] = yields_[i];
        }
    }

    function _unStakeItems(CollectionItems memory collectionItems_, address owner_) internal whenNotPaused {
        for (uint256 i = 0; i < collectionItems_.assets.length; ++i) {
            require(
                EnumerableSetUpgradeable.remove(
                    stakedAssets[owner_][collectionItems_.collection],
                    collectionItems_.assets[i]
                ),
                "BGM:1"
            );

            delete tokenOwners[collectionItems_.collection][collectionItems_.assets[i]];
        }
    }

    function _stakeItems(CollectionItems memory collectionItems_, address owner_) internal whenNotPaused {
        for (uint256 i = 0; i < collectionItems_.assets.length; ++i) {
            require(
                EnumerableSetUpgradeable.add(
                    stakedAssets[owner_][collectionItems_.collection],
                    collectionItems_.assets[i]
                ),
                "BGM:2"
            );

            tokenOwners[collectionItems_.collection][collectionItems_.assets[i]] = owner_;
            stateChangeDates[collectionItems_.collection][collectionItems_.assets[i]] = block.timestamp;
        }
    }

    function _addEliteToPool(
        address collection_,
        uint256 tokenId_,
        uint256 faction_,
        address owner_
    ) internal whenNotPaused {
        elitesOwners[collection_][tokenId_] = owner_;
        EnumerableSetUpgradeable.add(elites[faction_][collection_], tokenId_);
    }

    function _removeEliteFromPool(
        address collection_,
        uint256 tokenId_,
        uint256 faction_
    ) internal whenNotPaused {
        delete elitesOwners[collection_][tokenId_];
        EnumerableSetUpgradeable.remove(elites[faction_][collection_], tokenId_);
    }

    function _checkIfAllowedToStake(CollectionItems memory collectionItems_, address owner_) internal view {
        require(
            EnumerableSetUpgradeable.contains(allowedStakeCollections, collectionItems_.collection),
            "BGM:3"
        );
        for (uint256 i = 0; i < collectionItems_.assets.length; ++i) {
            require(
                IERC721Upgradeable(collectionItems_.collection).ownerOf(collectionItems_.assets[i]) == owner_,
                "BGM:4"
            );
        }
    }

    function _checkIfOwnsItems(CollectionItems memory collectionItems_, address owner_) internal view {
        for (uint256 i = 0; i < collectionItems_.assets.length; ++i) {
            _checkIfOwnsItem(collectionItems_.collection, collectionItems_.assets[i], owner_);
        }
    }

    function _checkIfOwnsItem(address collection_, uint tokenId_, address owner_) internal view {
        require(tokenOwners[collection_][tokenId_] == owner_, "BGM:5");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./VRFRequestIDBase.sol";
import "./LinkTokenInterface.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBaseUpgradeable is Initializable, VRFRequestIDBase {
    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */

    function __VRFConsumerBase_init(address _vrfCoordinator, address _link) internal onlyInitializing {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }


    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IBSBBloodShard {
    function mint(
        address account,
        uint256 amount,
        bytes calldata data
    ) external;

    function burn(uint256 id, uint256 amount, address wallet) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract BSBBaseUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {
    
    modifier onlyAuthorised {
        require(owner() == _msgSender() || authorizedContracts[_msgSender()], "BASE:1");
        _;
    }

    uint256 constant public DAYS = 1 days;
    uint256 constant public ETHER = 1 ether;

    mapping(address => bool) public authorizedContracts;

    function __BSBBase_init() internal initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function setContractsStatuses(
        address[] calldata addresses_, 
        bool[] calldata statuses_
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; ++i) {
            authorizedContracts[addresses_[i]] = statuses_[i];
        }
    }
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.0;

import "./IBSBTypes.sol";

interface IBSBStorage is IBSBTypes {

    // BEARS

    // GETTERS
    function getBearsStats(address, uint[] calldata) external view returns(BearStats[] memory);

    function getBearStats(address, uint) external view returns(BearStats memory);

    // SETTERS

    function setBearStats(address, uint, BearStats calldata) external;

    function setBearsStats(address, uint[] calldata, BearStats[] calldata) external;

    // TREEHOUSE

    function setTreeHouseStats(uint, TreeHouseStats calldata) external;

    function getTreeHouseStats(uint) external view returns(TreeHouseStats memory);

    function setTreeHousesStats(uint[] calldata, TreeHouseStats[] calldata) external;

    function getTreeHousesStats(uint[] calldata) external view returns(TreeHouseStats[] memory);


    function stakeAssets(CollectionItems[] calldata, address) external;

    function unStakeAssets(CollectionItems[] calldata, address) external;

    function elitesCount(address) external view returns(uint);

}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

interface IBSBTypes {

    struct Stat {
        uint256 min;
        uint256 max;
        uint256 value;
    }

    struct BearStats {
        bool isLegendary;
        bool isElite;
        uint256 faction;
        Stat stamina;
        Stat offense;
        Stat defense;
        Stat level;
        Stat leadership;
    }

    struct TreeHouseStats {
        Stat size;
        Stat defense;
    }

    struct CollectionItems {
        address collection;
        uint256[] assets;
    }
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

interface IBSBMintPassBuff {
    function getBuffBalance(address) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

interface IBSBBloodToken {
    function spend(
        uint256 amount,
        address sender
    ) external;

    function spend(
        uint256 amount,
        address sender,
        address recipient,
        address redirectAddress,
        uint256 redirectPercentage,
        uint256 burnPercentage
    ) external;

    function mint(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
    /**
     * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}