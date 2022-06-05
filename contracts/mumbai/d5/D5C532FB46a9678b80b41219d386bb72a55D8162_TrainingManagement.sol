// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";

contract TrainingManagement is Ownable {

    IERC20 BZAI;
    IAddresses public gameAddresses;

    constructor(address _BZAI)  {
        BZAI = IERC20(_BZAI);
    }

    mapping(uint256 => uint256) public tcRevenues;

    uint256 public addSpotPrice = 200000 * 1E18;

    uint256 public minimumTrainingPrice = 100 * 1E18;

    string[5] slotStatus = ["not_set","closed","free","in_use","waiting_coach"];

    struct coachDatas {
        bool coachRequired;
        uint256 minLevelReq;
        uint256 percentPayment;
        uint256 coachId;
    }

    struct TrainingInstance {
        bool spotOpened;
        uint256 price;
        uint256 duration;
        uint256 endAt;
        uint256 zaiId;
        coachDatas coach;
    }

    mapping(uint256 => mapping(uint256 => TrainingInstance)) public trainingSpots;

    modifier onlyCenterOwner(uint256 _trainingId){
        require(ITraining(gameAddresses.getTrainingNFTAddress()).ownerOf(_trainingId) == msg.sender,"!Yours");
        _;
    }

    modifier zaiOwner(uint256 _zaiId){
        require(IZaiNFT(gameAddresses.getZaiAddress()).ownerOf(_zaiId) == msg.sender,"!Yours");
        _;
    }

    function setGameAddresses(address _address) public onlyOwner {
        gameAddresses = IAddresses(_address);
    }

    function setSpotPrice(uint256 _price) external onlyOwner {
        addSpotPrice = _price;
    }

    // 0 = not params, 1= closed, 2 = Free, 3 = in use, 4 = waitingcoach
    function getSpotStatus(uint256 _spotId,uint256 _trainingId) external view returns(string memory){
        return slotStatus[_getSpotStatus(_spotId,_trainingId)];
    }

    function _getSpotStatus(uint256 _spotId,uint256 _trainingId) internal view returns(uint256 _state){
        TrainingInstance memory t = trainingSpots[_trainingId][_spotId];
        if(t.price == 0){
            return 0;
        } else if(!t.spotOpened){
            return 1;
        } else if(t.coach.coachId == 0 && t.coach.percentPayment > 0){
            return 4;
        } else if(t.zaiId == 0 || block.timestamp >= t.endAt){
            return 2;
        } else {
            return 3;
        }
    }

    function upgradeTC(uint256 _spotsQty, uint256 _trainingId)
        external
        onlyCenterOwner(_trainingId)
        returns (bool)
    {
        address _payment = gameAddresses.getPaymentsAddress();

        require(payWithRewardOrWallet(msg.sender, _payment, _spotsQty * addSpotPrice));
        IPayments(_payment).distributeFees(_spotsQty * addSpotPrice);

        return ITraining(gameAddresses.getTrainingNFTAddress()).addTrainingSpots(_trainingId,_spotsQty);
    }

    function setTrainingSpot(
        uint256 _spotId,
        uint256 _trainingId,
        uint256 _duration,
        uint256 _price,
        bool _coachNeeded,
        uint256 _minCoachLevel,
        uint256 _coachPercentPayment
    ) external 
    onlyCenterOwner(_trainingId)
    {
        require(ITraining(gameAddresses.getTrainingNFTAddress()).numberOfTrainingSpots(_trainingId) >= _spotId, "!Exist");
        require(_getSpotStatus(_spotId, _trainingId) != 3, "Spot!=Free");
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        require(t.coach.coachId == 0, "Got coach, you have to kick him ");

        if (t.zaiId != 0) {
            _updateZai(t.zaiId, t.duration, t.coach.coachId);
            t.zaiId = 0;
            t.endAt = 0;
        }
        t.duration = _duration;
        t.price = _price;

        if(_coachNeeded){
           t.coach.minLevelReq = _minCoachLevel;
           t.coach.percentPayment = _coachPercentPayment;
           t.coach.coachRequired = true;
        }else{
            t.spotOpened = true;
        }
    }

    function registerCoaching(uint256 _zaiId, uint256 _spotId, uint256 _trainingId) external zaiOwner(_zaiId){
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        IZaiNFT I = IZaiNFT(gameAddresses.getZaiAddress());
        require(t.coach.coachRequired,"!Exist");
        require(t.coach.coachId == 0, "Got coach");
        ZaiStruct.Zai memory z = IZaiNFT(gameAddresses.getZaiAddress()).getZai(_zaiId);

        require(z.level >= t.coach.minLevelReq, "!Level");
        require(I.isFree(_zaiId), "Zai!=Free");
        I.updateStatus(_zaiId, 2, _trainingId);
        t.coach.coachId = _zaiId;
        t.spotOpened = true;
    }

    function stopHiringCoach(uint256 _spotId, uint256 _trainingId, uint256 _newPrice) external onlyCenterOwner(_trainingId){
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        if(t.coach.coachId != 0){
            IZaiNFT(gameAddresses.getZaiAddress()).updateStatus(t.coach.coachId, 0, 0);
            t.coach.coachId = 0;
        }
        t.coach.minLevelReq = 0;
        t.coach.coachRequired = false;
        t.price = _newPrice;

    }

    function kickCoachFromSpot(uint256 _spotId, uint256 _trainingId) external onlyCenterOwner(_trainingId){
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        require(t.coach.coachId != 0, "No coach to kick");

        IZaiNFT(gameAddresses.getZaiAddress()).updateStatus(t.coach.coachId, 0, 0);
        t.coach.coachId = 0;
    }

    function quiteCoaching(uint256 _zaiId, uint256 _spotId, uint256 _trainingId) external zaiOwner(_zaiId){
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        IZaiNFT I = IZaiNFT(gameAddresses.getZaiAddress());
        require(_getSpotStatus(_spotId, _trainingId) != 3, "InUse");
        ZaiStruct.Zai memory z = IZaiNFT(gameAddresses.getZaiAddress()).getZai(_zaiId);

        require(z.level >= t.coach.minLevelReq, "!Level");
        t.coach.coachId = 0;
        I.updateStatus(_zaiId, 0, 0);
        t.spotOpened = false;
    }

    function closingSpot(uint256 _trainingId, uint256 _spotId) external onlyCenterOwner(_trainingId){
        trainingSpots[_trainingId][_spotId].spotOpened= false;
    }

    function beginTraining(
        uint256 _spotId,
        uint256 _trainingId,
        uint256 _zaiId
    ) external 
    zaiOwner(_zaiId)
    {
        address _zaiAddress = gameAddresses.getZaiAddress();
        address _paymentAddress = gameAddresses.getPaymentsAddress();

        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        IZaiNFT I = IZaiNFT(_zaiAddress);
        require(_getSpotStatus(_spotId, _trainingId) == 2, "T!=Free");
        require(IOpenAndClose(gameAddresses.getOpenAndCloseAddress()).canTrain(_trainingId), "!Ready");
        require(I.isFree(_zaiId), "M!=Free");
        I.updateStatus(_zaiId,1,_trainingId);

        address ownerOfTC = ITraining(gameAddresses.getTrainingNFTAddress()).ownerOf(_trainingId);
        uint256 ownerPayment = t.price;

        if(t.coach.coachId != 0){
            uint256 coachPayment = ownerPayment * t.coach.percentPayment / 100;
            ownerPayment = ownerPayment - coachPayment;
            address ownerOfCoach = IZaiNFT(_zaiAddress).ownerOf(t.coach.coachId);
            IPayments(_paymentAddress).payOwner(ownerOfCoach, coachPayment);
        }

        require(payWithRewardOrWallet(msg.sender, _paymentAddress, t.price));
        IPayments(_paymentAddress).payOwner(ownerOfTC, ownerPayment);
        
        tcRevenues[_trainingId] = tcRevenues[_trainingId] + t.price;

        if (t.zaiId != 0) {
            _updateZai(t.zaiId, t.duration,t.coach.coachId);
        }

        t.endAt = block.timestamp + t.duration;
        t.zaiId = _zaiId;
    }

    function finishTraining(uint256 _spotId, uint256 _trainingId, uint256 _zaiId) external zaiOwner(_zaiId){
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        if (block.timestamp >= t.endAt) {
            _updateZai(t.zaiId, t.duration,t.coach.coachId);
        }

        IZaiNFT(gameAddresses.getZaiAddress()).updateStatus(t.zaiId,0,0);

        t.endAt = 0;
        t.zaiId = 0;

    }

    function cleanSlotsBeforeClosing(uint256 _trainingId) external returns(bool){
        require(msg.sender == gameAddresses.getOpenAndCloseAddress(), "Not authorized");
        uint256 numberOfTrainingSpots = ITraining(gameAddresses.getTrainingNFTAddress()).numberOfTrainingSpots(_trainingId);
        IZaiNFT IZai = IZaiNFT(gameAddresses.getZaiAddress());
        if(numberOfTrainingSpots == 0 ){
            return true;
        }else{
            for(uint256 i = 1 ; i <= numberOfTrainingSpots ;){
                TrainingInstance storage t = trainingSpots[_trainingId][i];
                if(t.zaiId != 0){
                    _updateZai(t.zaiId, t.duration,t.coach.coachId);
                    t.duration = 0;
                    t.zaiId = 0;
                    if(t.coach.coachId != 0){
                        IZai.updateStatus(t.zaiId, 0, 0);     
                    }
                }
                unchecked{ ++i; }
            }
            return true;
        }
    }

    function _updateZai(uint256 _zaiId, uint256 _duration, uint256 _coachId)
        private
    {
        IZaiNFT I = IZaiNFT(gameAddresses.getZaiAddress());
        ZaiStruct.Zai memory z = I.getZai(_zaiId);

        if(_coachId != 0){
            ZaiStruct.Zai memory c = I.getZai(_coachId);
            if(c.level - z.level > 0){
                _duration = _duration * (c.level - z.level + 1);
            }
        }

        uint256 levelTens = z.level - (z.level % 10);
        uint256 multiplierXp = 1;
        if (levelTens > 0) {
            multiplierXp = (levelTens / 10) + 1;
        }

        I.updateXp(_zaiId,_duration * multiplierXp);
    }

    function payWithRewardOrWallet(address _user, address _recipient, uint256 _amount) internal returns(bool){
        address _paymentAddress = gameAddresses.getPaymentsAddress();
        uint256 _credit = IPayments(_paymentAddress).getMyReward(_user);
        if(_credit == 0){
            return(BZAI.transferFrom(_user, _recipient, _amount));
        }else if(_credit > _amount){
            return IPayments(_paymentAddress).useReward(_user,_amount);
        }else {
            IPayments(_paymentAddress).useReward(_user,_credit);
            return(BZAI.transferFrom(_user, _recipient, _amount - _credit));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ZaiStruct {
        // Zai powers
    // Zai powers
    struct Powers {
        uint256 water;
        uint256 fire;
        uint256 metal;
        uint256 air;
        uint256 stone;
    }

    // A zai can work in a center , training or coaching. He can't fight if he isn't free
    //string[4] _status = ["Free","Training","Coaching","Working"];
    struct Activity{
        uint256 statusId;
        uint256 onCenter;
    }

    struct ZaiMetaData{
        uint256 state; // _states index
        uint256 ipfsPathId;
        uint256 seasonOf;
    }

    struct Zai {
        string name;
        uint256 xp; 
        uint256 alchemyXp;
        uint256 level;
        uint256 creditForUpgrade; // credit to use to raise powers
        Powers powers;
        Activity activity;
        ZaiMetaData metadata;
    }

    struct Stats {
        uint256 zaiTotalWins;
        uint256 zaiTotalDraw;
        uint256 zaiTotalLoss;
        uint256 zaiTotalFights;
        uint256 zaiTotalRandomSelected;  
        uint256 zaiNumberOfWinThisDay;
    }

    struct EggsPrices {
        uint256 bronzePrice;
        uint256 silverPrice;
        uint256 goldPrice;
        uint256 platinumPrice;
    }

    struct MintedData {
        uint256 bronzeMinted;
        uint256 silverMinted;
        uint256 goldMinted;
        uint256 platinumMinted;
    }

    struct WorkInstance {
        uint256 zaiId;
        uint256 beginingAt;
    }

    struct DelegateData{
        address scholarAddress;
        uint256 contractDuration;
        uint256 contractEnd;
        uint256 percentageForScholar;
        uint256 lastScholarPlayed;
        bool renewable;
    } 

}

library PotionStruct {
    struct Powers {
        uint256 water;
        uint256 fire;
        uint256 metal;
        uint256 air;
        uint256 stone;
        uint256 rest;
        uint256 xp;
    }

    struct Potion {
        Powers powers;
        uint256 potionType; // 0: water ; 1: fire ; 2:metal ; 3:air ; 4:stone  ; 5:rest ; 6:xp ; 7:multiple
        address seller;
        uint256 listingPrice;
        uint256 fromLab;
        uint256 potionId;
        uint256 saleTimestamp;
    }
}

interface IOracle {
    function getRandom(bytes32 _id) external returns (uint256);
}

interface IZaiMeta {
    function getState(uint256 state) external view returns(string memory);

    function godNames(uint256 _ipfsId) external view returns(string memory);

    function getRandomPowers(uint256 level, uint256 _points, uint256 random) external view returns(ZaiStruct.Powers memory);

    function getGodsPowers(uint256 _ipfsId) external view returns(ZaiStruct.Powers memory);

    function updatePowers(uint256 level, ZaiStruct.Powers memory powers, ZaiStruct.Powers memory toAdd, bool isGod) external view returns(ZaiStruct.Powers memory);

    function getLevel(uint256 _xp) external view returns (uint256);

    function getNextLevelUpPoints(uint256 _level) external view returns(uint256);
}

interface IZaiNFT is IERC721Enumerable {

    function mintZai(address _to,string memory _name,uint256 _state) external returns (uint256);

    function burnZai(uint256 _tokenId) external;

    function updateStatus(uint256 _tokenId, uint256 _newStatusID, uint256 _center) external;

    function updateXp(uint256 _id,uint256 _xp) external returns (uint256 level);

    function isFree(uint256 _tokenId) external view returns(bool);

    function updateAlchemyXp(uint256 _tokenId, uint256 _xpRaised) external;

    function getZai(uint256 _tokenId) external view returns(ZaiStruct.Zai memory);
    
    function getNextLevelUpPoints(uint256 _level) external view returns(uint256);
    
}

interface IipfsIdStorage {
    function getTokenURI(uint256 _season, uint256 _state, uint256 _id) external view returns(string memory);

    function getNextIpfsId(uint256 _state) external returns(uint256);

    function getCurrentSeason() external view returns(uint256);
}

interface ILaboratory is IERC721Enumerable{
    function mintLaboratory(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function getCreditLastUpdate(uint256 _tokenId) external view returns(uint256);

    function updateCreditLastUpdate(uint256 _tokenId) external returns(bool);

    function numberOfWorkingSpots(uint256 _tokenId) external view returns(uint256);

    function updateNumberOfWorkingSpots(uint256 _tokenId) external returns(bool);

    function getPreMintNumber() external view returns(uint256);
}

interface ILabManagement{
    function createdPotionsForLab(uint256 _tokenId) external view returns(uint256);

    function laboratoryRevenues(uint256 _tokenId) external view returns(uint256);

    function getCredit(uint256 _laboId) external view returns(uint256);

    function workingSpot(uint256 _laboId, uint256 _slotId) external view returns(ZaiStruct.WorkInstance memory);

    function cleanSlotsBeforeClosing(uint256 _laboId) external returns(bool);

}

interface IBZAI is IERC20{
    function burn(uint256 _amount) external returns(bool);
}

interface ITraining is IERC721Enumerable{
    function mintTrainingCenter(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function numberOfTrainingSpots(uint256 _tokenId) external view returns(uint256);

    function addTrainingSpots(uint256 _tokenId, uint256 _amount) external returns(bool);

    function getPreMintNumber() external view returns(uint256);

}

interface ITrainingManagement {
    function cleanSlotsBeforeClosing(uint256 _laboId) external returns(bool);
}



interface INursery is IERC721Enumerable{
    function mintNursery(address _to, uint256 _bronzePrice, uint256 _silverPrice, uint256 _goldPrice, uint256 _platinumPrice) external returns (uint256);

    function burnNursery(uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;

    function nextStateToMint(uint256 _tokenId) external view returns (uint256);

    function getEggsPrices(uint256 _nursId) external view returns(ZaiStruct.EggsPrices memory);

    function getNurseryMintedDatas(uint256 _tokenId) external view returns (ZaiStruct.MintedData memory);

    function getNextUnlock(uint256 _tokenId) external view returns (uint256);

    function getPreMintNumber() external view returns(uint256);

    function nurseryRevenues(uint256 _tokenId) external view returns(uint256);

    function nurseryMintedDatas(uint256 _tokenId) external view returns(ZaiStruct.MintedData memory);

}

interface ILottery is IERC721Enumerable{
    function getLotteryPrices() external view returns(uint256 _ticket, uint256 _bronze, uint256 _silver, uint256 _gold);
}

interface IStaking {
    function receiveFees(uint256 _amount) external;
}

interface IBZAIToken {
    function burnToken(uint256 _amount) external;
}

interface IPayments {
    function payOwner(address _owner, uint256 _value) external returns(bool);

    function distributeFees(uint256 _amount) external returns(bool);

    function getMyReward(address _user) external view returns(uint256);

    function useReward(address _user, uint256 _amount) external returns(bool);

    function rewardPlayer(address _user, uint256 _amount) external returns(bool);
}

interface IEggs is IERC721Enumerable{

    function mintEgg(address _to,uint256 _state,uint256 _maturityDuration) external returns (uint256);

    function burnEgg(uint256 _tokenId) external returns(bool);

    function isMature(uint256 _tokenId) external view returns(bool);

    function getStateIndex(uint256 _tokenId) external view returns (uint256);
}

interface IPotions is IERC721Enumerable{
    function mintPotionForSale(uint256 _fromLab,uint256 _price,uint256 _type, uint256 _power) external returns (uint256);

    function offerPotion(uint256 _type,uint256 _power,address _to) external returns (uint256);

    function updatePotion(uint256 _tokenId) external; 

    function burnPotion(uint256 _tokenId) external returns(bool);

    function getPotion(uint256 _tokenId) external view returns(address seller, uint256 price, uint256 fromLab);

    function buyPotion(address _to, uint256 _type) external returns (uint256);

    function mintMultiplePotion(uint256[7] memory _powers, address _owner) external returns(uint256);

    function changePotionPrice(uint256 _tokenId, uint256 _laboId, uint256 _price) external returns(bool);

    function updatePotionSaleTimestamp(uint256 _tokenId) external returns(bool);

    function getFullPotion(uint256 _tokenId) external view returns(PotionStruct.Potion memory);
}

interface IAddresses {
    function getBZAIAddress() external view returns(address);

    function getOracleAddress() external view returns(address);

    function getStakingAddress() external view returns(address); 

    function getZaiAddress() external view returns(address);

    function getIpfsStorageAddress() external view returns(address);

    function getLaboratoryAddress() external view returns(address);

    function getLaboratoryNFTAddress() external view returns(address);

    function getTrainingCenterAddress() external view returns(address);

    function getTrainingNFTAddress() external view returns(address);

    function getNurseryAddress() external view returns(address);

    function getPotionAddress() external view returns(address);

    function getTeamAddress() external view returns(address);

    function getGameAddress() external view returns(address);

    function getEggsAddress() external view returns(address);

    function getLotteryAddress() external view returns(address);

    function getPaymentsAddress() external view returns(address);

    function getChallengeRewardsAddress() external view returns(address);

    function getWinRewardsAddress() external view returns(address);

    function getOpenAndCloseAddress() external view returns(address);

    function getAlchemyAddress() external view returns(address);

    function getChickenAddress() external view returns(address);

    function getReserveChallengeAddress() external view returns(address);

    function getReserveWinAddress() external view returns(address);

    function getWinChallengeAddress() external view returns(address);

    function isAuthToManagedNFTs(address _address) external view returns(bool);

    function isAuthToManagedPayments(address _address) external view returns(bool);

    function getLevelStorageAddress() external view returns(address);

    function getRankingContract() external view returns(address);

    function getAuthorizedSigner() external view returns(address);

    function getDelegateZaiAddress() external view returns(address);

    function getZaiStatsAddress() external view returns(address);

    function getLootAddress() external view returns(address);
}

interface IOpenAndClose {

    function getLaboCreatingTime(uint256 _tokenId) external view returns(uint256);

    function getNurseryCreatingTime(uint256 _tokenId) external view returns(uint256);

    function canLaboSell(uint256 _tokenId) external view returns (bool);

    function canTrain(uint256 _tokenId) external view returns (bool);

    function canNurserySell(uint256 _tokenId) external view returns (bool);

    function nurseryMinted()external view returns(uint256);

    function laboratoryMinted()external view returns(uint256);

    function trainingCenterMinted()external view returns(uint256);

    function getLaboratoryName(uint256 _tokenId) external view returns(string memory);

    function getNurseryName(uint256 _tokenId) external view returns(string memory);

    function getNurseryState(uint256 _tokenId) external view returns (string memory);

    function getTrainingCenterName(uint256 _tokenId) external view returns(string memory);

    function getLaboratoryState(uint256 _tokenId) external view returns (string memory);

}

interface IReserveForChalengeRewards {
    function getNextUpdateTimestamp() external view returns(uint256);

    function getRewardFinished() external view returns(bool);

    function updateRewards() external returns(bool);
}

interface IReserveForWinRewards {
    function getNextUpdateTimestamp() external view returns(uint256);

    function getRewardFinished() external view returns(bool);

    function updateRewards() external returns(bool);
}

interface ILevelStorage {
     function addFighter(uint256 _level, uint256 _zaiId) external returns(bool);

     function removeFighter(uint256 _level, uint256 _zaiId) external returns (bool);

     function getLevelLength(uint256 _level) external view returns(uint256);
     
     function getRandomZaiFromLevel(uint256 _level, uint256 _idForbiden) external returns(uint256 _zaiId);
}

interface IRewardsRankingFound {
    function getDailyRewards(address _rewardStoringAddress) external returns(uint256);

    function getWeeklyRewards(address _rewardStoringAddress) external returns(uint256);
}

interface IRewardsWinningFound {
    function getWinningRewards(uint256 level) external returns(uint256);
}

interface IRanking {
    function updatePlayerRankings(address _user) external returns(bool);

    function getDayBegining() external view returns(uint256);
}

interface IDelegate {
    function gotDelegationForZai(uint256 _zaiId, address _user) external view returns(bool);

    function getDelegateDatasByZai(uint256 _zaiId) external view returns(ZaiStruct.DelegateData memory);

    function isZaiDelegated(uint256 _zaiId) external view returns(bool);

    function updateLastScholarPlayed(uint256 _zaiId) external returns(bool);
}

interface IStats {
    function updateCounterWinLoss(uint256 _zaiId,uint256[30] memory _fightProgress) external returns(bool result);

    function getZaiStats(uint256 _zaiId) external view returns(uint256[5] memory);

    function updateAllPowersInGame(ZaiStruct.Powers memory toAdd) external returns(bool);
}

interface IFighting{
    function getZaiStamina(uint256 _zaiId) external view returns(uint256);

    function getDayWinByZai(uint256 zaiId) external view returns(uint256);
}

interface ILootProgress {
    function updateUserProgress(address _user) external;
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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}