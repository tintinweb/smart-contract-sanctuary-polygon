// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interfaces.sol";

// main payment contract
// players rewards/ center revenues... are stored here
// each time a transaction is done in the game, initial contract send BZAI here and attribute balance
// claim rewards will burn 20% of amount
// rewards can be used in game economy without burning taxe
// claim revenues doesn't have burning taxe
// revenues can be used (by burn a part of them) for reserve eggs
// UPDATE AUDIT : totalDebt rise is managed only in payWithRewardsOrWallet when BZAI are transferFrom
contract Payments is Ownable, ReentrancyGuard {
    IBZAI immutable BZAI;

    IAddresses public gameAddresses;
    address public daoAddress;

    uint256 public totalDebt;
    uint256 public feesPercentageForPool = 20; // remaining percentage is burned
    uint256 public percentageForDAO = 0; // at the begining DAO provision is 0% but can be updated later (6 months locking period)

    // each rewards for a Zai will increase his piggyBank . percentage deduce from reward depending on zai's state
    uint256[4] private _zaiPiggyBankFees = [5, 4, 3, 1];

    // there is a 6 months minimum period to unlock DAO fees.
    uint256 public unlockDaoTimestamp;

    mapping(address => uint256) private _myReward;
    mapping(address => uint256) private _myRevenues;
    mapping(uint256 => uint256) private _zaiPiggyBank;

    // UPDATE AUDIT : RewardWon is emitted on Payment contract now
    event RewardWon(
        address indexed user,
        uint256 amount,
        uint256 zaiUsed,
        uint256 amountForPiggyBank,
        bool fromDelegation
    );
    event GameAddressesSetted(address gameAddresses);

    event BzaiSpentFromWallet(
        address indexed user,
        uint256 amountSpent,
        address usedOn
    );

    event RewardUsed(
        address indexed user,
        uint256 amountUsed,
        uint256 initialRewardBalanced,
        uint256 amountFromWalletUsed,
        address usedOn
    );
    event RevenuesUsed(
        address indexed user,
        uint256 amountUsed,
        uint256 initialRevenuesBalanced,
        uint256 amountFromWalletUsed,
        address usedOn
    );
    event RevenuesClaimed(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward, uint256 burned);
    event BurnedForEggs(address indexed user, uint256 burned);
    event NftOwnerPaid(address indexed owner, uint256 amount);
    event RevenuesForOwner(address indexed user, address from, uint256 amount);
    event FeesDistributed(
        uint256 totalAmount,
        uint256 burned,
        uint256 poolIncrease
    );
    event DaoUpdated(
        address oldDaoAddress,
        address newDaoAddress,
        uint256 oldPercentageFees,
        uint256 newPercentageFees
    );
    event PercentageForPoolChanged(
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event ZaiPiggyBankFeesChanged(uint256[4] oldMetrics, uint256[4] newMetric);
    event ZaiBurned(address user, uint256 zaiId, uint256 amountDelivered);

    constructor(address _BZAI) {
        BZAI = IBZAI(_BZAI);
        unlockDaoTimestamp = block.timestamp + 183 days;
    }

    modifier onlyAuth() {
        require(
            gameAddresses.isAuthToManagedPayments(msg.sender),
            "Not Authorized"
        );
        _;
    }

    function setGameAddresses(address _address) external onlyOwner {
        require(
            address(gameAddresses) == address(0x0),
            "game addresses already setted"
        );
        gameAddresses = IAddresses(_address);
        emit GameAddressesSetted(_address);
    }

    function setFeesPercentageForPool(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Numbers doesn't match");
        uint256 oldMetric = feesPercentageForPool;
        feesPercentageForPool = _percentage;
        emit PercentageForPoolChanged(oldMetric, _percentage);
    }

    function setPercentageForDAO(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Numbers doesn't match");
        require(
            block.timestamp >= unlockDaoTimestamp,
            "locked period is not over"
        );
        uint256 _oldPercentageFees = percentageForDAO;
        percentageForDAO = _percentage;
        emit DaoUpdated(
            daoAddress,
            daoAddress,
            _oldPercentageFees,
            _percentage
        );
    }

    function setDaoAddress(
        address _dao,
        uint256 _percentage
    ) external onlyOwner {
        require(_percentage <= 100, "Numbers doesn't match");
        require(
            block.timestamp >= unlockDaoTimestamp,
            "locked period is not over"
        );
        address _oldAddress = daoAddress;
        uint256 _oldPercentage = percentageForDAO;
        daoAddress = _dao;
        percentageForDAO = _percentage;
        emit DaoUpdated(_oldAddress, _dao, _oldPercentage, _percentage);
    }

    function setZaiPiggyBankFees(
        uint256[4] memory _percentages
    ) external onlyOwner {
        require(
            _percentages[0] <= 10 &&
                _percentages[1] <= 10 &&
                _percentages[2] <= 10 &&
                _percentages[3] <= 10,
            "Percentages too high"
        );
        uint256[4] memory oldMetrics = _zaiPiggyBankFees;
        _zaiPiggyBankFees = _percentages;
        emit ZaiPiggyBankFeesChanged(oldMetrics, _percentages);
    }

    function getZaiPiggyBankFees() external view returns (uint256[4] memory) {
        return _zaiPiggyBankFees;
    }

    function getMyReward(address _user) external view returns (uint256) {
        return _myReward[_user];
    }

    function getMyCentersRevenues(
        address _user
    ) external view returns (uint256) {
        return _myRevenues[_user];
    }

    // UPDATE AUDIT : one function for revenues + rewards
    function getAvailable(address _user) external view returns (uint256) {
        return _myReward[_user] + _myRevenues[_user];
    }

    function getZaiPiggyBank(uint256 _zaiId) external view returns (uint256) {
        return _zaiPiggyBank[_zaiId];
    }

    // UPDATE AUDIT : decrease totalDebt for token quantity who doesn't stay in contract
    function payOwner(
        address _owner,
        uint256 _amount
    ) external onlyAuth nonReentrant returns (bool) {
        uint256 _toOwner = (_amount * 8000) / 10000;
        uint256 _toPool = _amount - _toOwner;
        totalDebt -= _toPool;

        // 80% for owner of Nuresery/Training Center or Forge
        _myRevenues[_owner] += _toOwner;

        uint256 _quarterToPool = _toPool / 4;

        // 5%  for reward challenge in game (daily and weekly ranking)
        require(
            BZAI.transfer(
                gameAddresses.getAddressOf(
                    AddressesInit.Addresses.REWARDS_RANKING
                ),
                _quarterToPool
            )
        );
        _toPool -= _quarterToPool;

        // 5% for winning contract (where each win in game give % of the win pool to the user)
        require(
            BZAI.transfer(
                gameAddresses.getAddressOf(
                    AddressesInit.Addresses.REWARDS_WINNING_PVE
                ),
                _quarterToPool
            )
        );
        _toPool -= _quarterToPool;

        // 5% for pvp pool
        require(
            BZAI.transfer(
                gameAddresses.getAddressOf(AddressesInit.Addresses.REWARDS_PVP),
                _quarterToPool
            )
        );
        _toPool -= _quarterToPool;

        // 5 % for DAO or Burn
        // UPDATE AUDIT : Check if daoAddress != address(0)
        if (percentageForDAO != 0 && daoAddress != address(0)) {
            uint256 _toDAO = (_toPool * percentageForDAO) / 100;
            _toPool -= _toDAO;
            require(BZAI.transfer(daoAddress, _toDAO));
            require(BZAI.burn(_toPool));
        } else {
            require(BZAI.burn(_toPool));
        }

        require(totalDebt <= BZAI.balanceOf(address(this)));

        emit RevenuesForOwner(_owner, msg.sender, _toOwner);

        return true;
    }

    // UPDATE AUDIT : decrease totalDebt for token quantity who doesn't stay in contract
    function distributeFees(
        uint256 _amount
    ) external onlyAuth nonReentrant returns (bool) {
        totalDebt -= _amount;
        uint256 _toPool = (_amount * feesPercentageForPool) / 100;
        uint256 _toBurn = _amount - _toPool;

        if (percentageForDAO != 0) {
            uint256 _toDAO = (_toBurn * percentageForDAO) / 100;
            _toBurn -= _toDAO;
            require(BZAI.transfer(daoAddress, _toDAO));
        }

        require(BZAI.burn(_toBurn));

        uint256 _quarterToPool = _toPool / 4;

        // 25%  for reward challenge in game (daily and weekly ranking)
        require(
            BZAI.transfer(
                gameAddresses.getAddressOf(
                    AddressesInit.Addresses.REWARDS_RANKING
                ),
                _quarterToPool
            )
        );
        _toPool -= _quarterToPool;

        // 25% for pvp pool
        require(
            BZAI.transfer(
                gameAddresses.getAddressOf(AddressesInit.Addresses.REWARDS_PVP),
                _quarterToPool
            )
        );
        _toPool -= _quarterToPool;

        emit FeesDistributed(_amount, _toBurn, _toPool * 2);

        // 50% for winning contract (where each win in game give % of the win pool to the user)
        return (
            BZAI.transfer(
                gameAddresses.getAddressOf(
                    AddressesInit.Addresses.REWARDS_WINNING_PVE
                ),
                _toPool
            )
        );
    }

    // UPDATE AUDIT : when less than 20 players played in the ranking, there is a quantity of reward not distributed => we burn them
    function burnUndistributedRewards(uint256 _amount) external returns (bool) {
        require(
            msg.sender ==
                gameAddresses.getAddressOf(AddressesInit.Addresses.RANKING),
            "Not authorized"
        );
        BZAI.burn(_amount);
        return (totalDebt <= BZAI.balanceOf(address(this)));
    }

    // UPDATE AUDIT : decrease totalDebt for token quantity who doesn't stay in contract
    function payNFTOwner(
        address _owner,
        uint256 _amount
    ) external onlyAuth nonReentrant returns (bool) {
        uint256 _toSeller = (_amount * 9800) / 10000;
        uint256 _toDistribute = _amount - _toSeller;
        totalDebt -= _toDistribute;

        // 98% for seller of NFT
        _myRevenues[_owner] += _toSeller;

        uint256 _toBurnOrDAO = _toDistribute / 2;
        _toDistribute -= _toBurnOrDAO;

        // 1 % for DAO or Burn
        if (percentageForDAO != 0) {
            require(BZAI.transfer(daoAddress, _toBurnOrDAO));
        } else {
            require(BZAI.burn(_toBurnOrDAO));
        }

        // prevent round math
        uint256 _toPool1 = _toDistribute / 2;
        _toDistribute -= _toPool1;

        // 0.5%  for reward challenge in game (daily and weekly ranking)
        require(
            BZAI.transfer(
                gameAddresses.getAddressOf(
                    AddressesInit.Addresses.REWARDS_RANKING
                ),
                _toPool1
            )
        );
        // 0.5% for winning contract (where each win in game give 0.1% of the win pool to the user)
        require(
            BZAI.transfer(
                gameAddresses.getAddressOf(
                    AddressesInit.Addresses.REWARDS_WINNING_PVE
                ),
                _toDistribute
            )
        );

        require(totalDebt <= BZAI.balanceOf(address(this)));
        emit NftOwnerPaid(_owner, _toSeller);

        return true;
    }

    // if _zaiId is != 0, we credit to _zaiId a BZAI pool
    function rewardPlayer(
        address _user,
        uint256 _amount,
        uint256 _zaiId,
        uint256 _state,
        bool _isDelegate
    ) external onlyAuth nonReentrant returns (bool) {
        // UPDATE AUDIT : When there is a reward This is the good place where we have to raise the totalDebt
        totalDebt += _amount;
        uint256 _forPiggyBank;
        if (_zaiId != 0) {
            _forPiggyBank = (_amount * _zaiPiggyBankFees[_state]) / 100;
            _zaiPiggyBank[_zaiId] += _forPiggyBank;
            _amount -= _forPiggyBank;
        }

        _myReward[_user] += _amount;
        require(totalDebt <= BZAI.balanceOf(address(this)));
        // UPDATE AUDIT : emit event
        emit RewardWon(_user, _amount, _zaiId, _forPiggyBank, _isDelegate);

        return true;
    }

    function burnRevenuesForEggs(
        address _owner,
        uint256 _amount
    ) external onlyAuth nonReentrant returns (bool) {
        if (_myRevenues[_owner] < _amount) {
            return false;
        } else {
            _myRevenues[_owner] -= _amount;
            totalDebt -= _amount;

            BZAI.burn(_amount);
            require(totalDebt <= BZAI.balanceOf(address(this)));
            emit BurnedForEggs(msg.sender, _amount);
            return true;
        }
    }

    // UPDATE AUDIT : Zai must be free from work/training and delegation
    // ZaiNFT must be approve to payment contract
    function burnZaiToGetHisPiggyBank(uint256 _zaiId) external nonReentrant {
        IZaiNFT Izai = IZaiNFT(
            gameAddresses.getAddressOf(AddressesInit.Addresses.ZAI_NFT)
        );
        require(Izai.ownerOf(_zaiId) == msg.sender, "Not your Zai");
        require(Izai.getApproved(_zaiId) == address(this), "Need to approve");

        require(
            !IDelegate(
                gameAddresses.getAddressOf(AddressesInit.Addresses.DELEGATE)
            ).isZaiDelegated(_zaiId),
            "Finish first the delegation process"
        );

        require(
            IZaiMeta(
                gameAddresses.getAddressOf(AddressesInit.Addresses.ZAI_META)
            ).isFree(_zaiId),
            "Zai is Not free, finish first his work/training/apprentice"
        );

        uint256 _toSend = _zaiPiggyBank[_zaiId];
        _zaiPiggyBank[_zaiId] = 0;

        emit ZaiBurned(msg.sender, _zaiId, _toSend);
        require(Izai.burnZai(_zaiId));
        require(BZAI.transfer(msg.sender, _toSend));

        totalDebt -= _toSend;
        require(totalDebt <= BZAI.balanceOf(address(this)));
    }

    function claimReward() external nonReentrant returns (bool) {
        require(_myReward[msg.sender] != 0, "No reward to claim");
        uint256 _reward = _myReward[msg.sender];
        _myReward[msg.sender] = 0;
        totalDebt -= _reward;

        uint256 _toBurn = (_reward * 20) / 100;

        require(BZAI.burn(_toBurn));
        require(BZAI.transfer(msg.sender, _reward - _toBurn));
        require(totalDebt <= BZAI.balanceOf(address(this)));

        emit RewardsClaimed(msg.sender, _reward, _toBurn);

        return true;
    }

    function claimMyCentersRevenues() external nonReentrant returns (bool) {
        require(_myRevenues[msg.sender] != 0, "No revenues to claim");
        uint256 _revenues = _myRevenues[msg.sender];
        _myRevenues[msg.sender] = 0;
        totalDebt -= _revenues;

        require(BZAI.transfer(msg.sender, _revenues));
        require(totalDebt <= BZAI.balanceOf(address(this)));

        emit RevenuesClaimed(msg.sender, _revenues);

        return true;
    }

    // User can pay with their pending rewards and/or BZAI balance
    // UPDATE AUDIT : Add initial reward and revenues balance in event
    // UPDATE AUDIT : Simplify algo
    // + optimize gas reducing calling storage (ex: _initialRewardBalance = _myReward[_user])
    function payWithRewardOrWallet(
        address _user,
        uint256 _amount
    ) external onlyAuth nonReentrant returns (bool) {
        uint256 _usedRewards;
        uint256 _usedRevenues;

        uint256 _initialRewardBalance = _myReward[_user];
        uint256 _initialRevenuesBalance = _myRevenues[_user];

        if (_initialRewardBalance == 0 && _initialRevenuesBalance == 0) {
            // if no rewards and no revenues : use BZAI user's balance
            totalDebt += _amount;
            emit BzaiSpentFromWallet(_user, _amount, msg.sender);
            return (BZAI.transferFrom(_user, address(this), _amount));
        } else if (_initialRewardBalance >= _amount) {
            // if rewards are enough to pay :  use _myReward
            _usedRewards = _amount;
            _myReward[_user] -= _amount;
            _amount = 0;
        } else if (_initialRewardBalance != 0) {
            // UPDATE AUDIT : use myReward in priority
            // if got some rewards, but not enough, used it in totality
            _usedRewards = _initialRewardBalance;
            _myReward[_user] = 0;
            _amount -= _usedRewards;
        }

        if (_initialRevenuesBalance >= _amount) {
            // if revenues are enough to pay :  use _myRevenues
            _usedRevenues = _amount;
            _myRevenues[_user] -= _amount;
        } else {
            // if rewards + revenues is not enough to pay, use all rewards and revenue and complete with user's balance
            if (_initialRevenuesBalance != 0) {
                _myRevenues[_user] = 0;
                _usedRevenues = _initialRevenuesBalance;
                _amount -= _usedRevenues;
            }
            totalDebt += _amount;
            require(BZAI.transferFrom(_user, address(this), _amount));
        }

        // emit rewards and revenues used
        // update totaDebt
        if (_usedRewards != 0) {
            emit RewardUsed(
                _user,
                _usedRewards,
                _initialRewardBalance,
                _amount,
                msg.sender
            );
        }
        if (_usedRevenues != 0) {
            emit RevenuesUsed(
                _user,
                _usedRevenues,
                _initialRevenuesBalance,
                _amount,
                msg.sender
            );
        }
        // check totalDebt is ok
        require(totalDebt <= BZAI.balanceOf(address(this)));
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ZaiStruct {
    // Zai powers
    struct Powers {
        uint8 water;
        uint8 fire;
        uint8 metal;
        uint8 air;
        uint8 stone;
    }

    // A zai can work in a center , training or coaching. He can't fight if he isn't free
    //string[4] _status = ["Free","Training","Coaching","Working"];
    // UPDATE AUDIT : add spotId
    struct Activity {
        uint8 statusId;
        uint8 onSpotId;
        uint16 onCenter;
    }

    struct ZaiMetaData {
        uint8 state; // _states index
        uint8 seasonOf;
        uint32 ipfsPathId;
        bool isGod;
    }

    struct Zai {
        uint8 level;
        uint16 creditForUpgrade; // credit to use to raise powers
        uint16 manaMax;
        uint16 mana;
        uint32 xp;
        Powers powers;
        Activity activity;
        ZaiMetaData metadata;
        string name;
    }

    struct ZaiMinDatasForFight {
        uint8 level;
        uint8 state;
        uint8 statusId;
        uint16 water;
        uint16 fire;
        uint16 metal;
        uint16 air;
        uint16 stone;
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

    struct DelegateData {
        address scholarAddress;
        address ownerAddress;
        uint8 percentageForScholar;
        uint32 contractDuration;
        uint32 contractEnd;
        uint32 lastScholarPlayed;
        bool renewable;
    }

    struct GuildeDatas {
        address renterOf;
        address masterOf;
        address platformAddress;
        uint8 percentageForScholar;
        uint8 percentageForGuilde;
        uint8 percentagePlatformFees;
    }

    struct ScholarDatas {
        GuildeDatas guildeDatas;
        DelegateData delegateDatas;
    }
}

library PotionStruct {
    struct Powers {
        uint16 water;
        uint16 fire;
        uint16 metal;
        uint16 air;
        uint16 stone;
        uint16 rest;
        uint16 xp;
        uint16 mana;
    }

    // UPDATE AUDIT : seller deleted from potion (actual owner of lab can be another user than creator of potion)
    struct Potion {
        uint256 listingPrice;
        uint256 fromLab;
        uint256 potionId;
        uint256 saleTimestamp;
        uint8 potionType; // 0: water ; 1: fire ; 2:metal ; 3:air ; 4:stone  ; 5:rest ; 6:xp ; 7:multiple ;8 : mana; 99 : empty
        Powers powers;
    }
}

library LaboStruct {
    struct WorkInstance {
        uint256 zaiId;
        uint256 beginingAt;
    }

    struct LabDetails {
        uint256 revenues;
        uint256 employees;
        uint256 potionsCredits;
        uint256 numberOfSpots;
        WorkInstance[10] workingSpot;
    }
}

library TrainingStruct {
    // UPDATE AUDIT : stats in struct
    struct Stats {
        uint256 trainingNumber;
        uint256 coachingNumber;
    }

    struct CoachDatas {
        bool coachRequired;
        uint256 minLevelReq;
        uint256 currentCoachLevel;
        uint256 percentPayment;
        uint256 coachId;
    }

    struct TrainingInstance {
        bool spotOpened;
        uint256 price;
        uint256 duration;
        uint256 endAt;
        uint256 zaiId;
        CoachDatas coach;
    }

    struct TrainingDetails {
        uint256 revenues;
        uint256 numberOfSpots;
        TrainingInstance[10] trainingSpots;
    }
}

library AddressesInit {
    enum Addresses {
        ALCHEMY,
        BZAI_TOKEN,
        CHICKEN,
        CLAIM_NFTS,
        DELEGATE,
        EGGS_NFT,
        FIGHT,
        FIGHT_PVP,
        IPFS_STORAGE,
        LABO_MANAGEMENT,
        LABO_NFT,
        LEVEL_STORAGE,
        LOOT,
        MARKET_PLACE,
        MARKET_DUTCH_AUCTION_ZAI,
        NURSERY_MANAGEMENT,
        NURSERY_NFT,
        OPEN_AND_CLOSE,
        ORACLE,
        PAYMENTS,
        POTIONS_NFT,
        PVP_GAME,
        RANKING,
        RENT_MY_NFT,
        REWARDS_PVP,
        REWARDS_WINNING_PVE,
        REWARDS_RANKING,
        TRAINING_MANAGEMENT,
        TRAINING_NFT,
        ZAI_META,
        ZAI_NFT
    }

    //     ALCHEMY, 0
    //     BZAI_TOKEN, 1
    //     CHICKEN, 2
    //     CLAIM_NFTS, 3
    //     DELEGATE, 4
    //     EGGS_NFT, 5
    //     FIGHT, 6
    //     FIGHT_PVP, 7
    //     IPFS_STORAGE, 8
    //     LABO_MANAGEMENT, 9
    //     LABO_NFT, 10
    //     LEVEL_STORAGE, 11
    //     LOOT, 12
    //     MARKET_PLACE, 13
    //     MARKET_DUTCH_AUCTION_ZAI, 14
    //     NURSERY_MANAGEMENT, 15
    //     NURSERY_NFT, 16
    //     OPEN_AND_CLOSE, 17
    //     ORACLE, 18
    //     PAYMENTS, 19
    //     POTIONS_NFT, 20
    //     PVP_GAME, 21
    //     RANKING, 22
    //     RENT_MY_NFT, 23
    //     REWARDS_PVP, 24
    //     REWARDS_WINNING_PVE, 25
    //     REWARDS_RANKING, 26
    //     TRAINING_MANAGEMENT, 27
    //     TRAINING_NFT, 28
    //     ZAI_META, 29
    //     ZAI_NFT, 30
}

interface IAddresses {
    function isAuthToManagedNFTs(address _address) external view returns (bool);

    function isAuthToManagedPayments(
        address _address
    ) external view returns (bool);

    function getAddressOf(
        AddressesInit.Addresses _contract
    ) external view returns (address);
}

interface IAlchemy {
    function updateInterfaces() external;
}

interface IBZAI is IERC20 {
    function burn(uint256 _amount) external returns (bool);
}

interface IChicken is IERC721 {
    function mintChicken(address _to) external returns (uint256);
}

interface IDelegate {
    function gotDelegationForZai(
        uint256 _zaiId
    ) external view returns (ZaiStruct.ScholarDatas calldata scholarDatas);

    function canUseZai(
        uint256 _zaiId,
        address _user
    ) external view returns (bool);

    function getDelegateDatasByZai(
        uint256 _zaiId
    ) external view returns (ZaiStruct.DelegateData memory);

    function isZaiDelegated(uint256 _zaiId) external view returns (bool);

    function updateLastScholarPlayed(uint256 _zaiId) external returns (bool);

    function updateInterfaces() external;
}

interface IEggs is IERC721 {
    function mintEgg(
        address _to,
        uint256 _state,
        uint256 _maturityDuration
    ) external returns (uint256);
}

interface IFighting {
    function updateInterfaces() external;
}

interface IFightingLibrary {
    function updateFightingProgress(
        uint256[30] memory _toReturn,
        uint256[9] calldata _elements,
        uint256[9] calldata _powers
    ) external pure returns (uint256[30] memory);

    function getUsedPowersByElement(
        uint256[9] calldata _elements,
        uint256[9] calldata _powers
    ) external pure returns (uint256[5] memory);

    function isPowersUsedCorrect(
        uint16[5] calldata _got,
        uint256[5] calldata _used
    ) external pure returns (bool);

    function getNewPattern(
        uint256 _random,
        ZaiStruct.ZaiMinDatasForFight memory c,
        uint256[30] memory _toReturn
    ) external pure returns (uint256[30] memory result);
}

interface IGuildeDelegation {
    struct GuildeDatas {
        address renterOf;
        address masterOf;
        address platformAddress;
        uint8 percentageForScholar;
        uint8 percentageForGuilde;
        uint8 percentagePlatformFees;
    }

    function getRentingDatas(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (ZaiStruct.GuildeDatas memory);
}

interface IipfsIdStorage {
    function getTokenURI(
        uint256 _season,
        uint256 _state,
        uint256 _id
    ) external view returns (string memory);

    function getNextIpfsId(
        uint256 _state,
        uint256 _nftId
    ) external returns (uint256);

    function getCurrentSeason() external view returns (uint8);

    function updateInterfaces() external;
}

interface ILaboratory is IERC721 {
    function mintLaboratory(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function getCreditLastUpdate(
        uint256 _tokenId
    ) external view returns (uint256);

    function updateCreditLastUpdate(uint256 _tokenId) external returns (bool);

    function numberOfWorkingSpots(
        uint256 _tokenId
    ) external view returns (uint256);

    function updateNumberOfWorkingSpots(
        uint256 _tokenId,
        uint256 _quantity
    ) external returns (bool);

    function getPreMintNumber() external view returns (uint256);

    function updateInterfaces() external;
}

interface ILabManagement {
    function initSpotsNumber(uint256 _tokenId) external returns (bool);

    function cleanSlotsBeforeClosing(uint256 _laboId) external returns (bool);

    function updateInterfaces() external;
}

interface ILevelStorage {
    function addFighter(uint256 _level, uint256 _zaiId) external returns (bool);

    function removeFighter(
        uint256 _level,
        uint256 _zaiId
    ) external returns (bool);

    function getLevelLength(uint256 _level) external view returns (uint256);

    function getRandomZaiFromLevel(
        uint256 _level,
        uint256 _idForbiden,
        uint256 _random
    ) external view returns (uint256);

    function updateInterfaces() external;
}

interface ILootProgress {
    // UPDATE AUDIT : update interface
    function updateUserProgress(
        address _user
    ) external returns (uint256 beginingDay);

    function updateInterfaces() external;
}

interface IMarket {
    function updateInterfaces() external;
}

interface INurseryNFT is IERC721 {
    function totalSupply() external view returns (uint256);
}

interface INurseryManagement {
    function getEggsPrices(
        uint256 _nursId
    ) external view returns (ZaiStruct.EggsPrices memory);

    function updateInterfaces() external;
}

interface IOpenAndClose {
    function getLaboCreatingTime(
        uint256 _tokenId
    ) external view returns (uint256);

    function canLaboSell(uint256 _tokenId) external view returns (bool);

    function canTrain(uint256 _tokenId) external view returns (bool);

    function updateInterfaces() external;
}

interface IOracle {
    function getRandom() external returns (uint256);
}

interface IPayments {
    function payOwner(address _owner, uint256 _value) external returns (bool);

    function getAvailable(address _user) external view returns (uint256);

    function distributeFees(uint256 _amount) external returns (bool);

    function burnUndistributedRewards(uint256 _amount) external returns (bool);

    function rewardPlayer(
        address _user,
        uint256 _amount,
        uint256 _zaiId,
        uint256 _state,
        bool _isDelegate
    ) external returns (bool);

    function burnRevenuesForEggs(
        address _owner,
        uint256 _amount
    ) external returns (bool);

    function payNFTOwner(
        address _owner,
        uint256 _amount
    ) external returns (bool);

    function payWithRewardOrWallet(
        address _user,
        uint256 _amount
    ) external returns (bool);
}

interface IPotions is IERC721 {
    function mintPotionForSale(
        uint256 _laboId,
        uint256 _price,
        uint256 _type,
        uint256 _power,
        uint256 _quantity
    ) external returns (uint256[] memory);

    function offerPotion(
        uint256 _type,
        uint256 _power,
        address _to,
        uint256 _fromLab
    ) external returns (uint256);

    function burnPotion(uint256 _tokenId) external returns (bool);

    function emptyingPotion(uint256 _tokenId) external returns (bool);

    function mintMultiplePotion(
        uint256[7] memory _powers,
        address _owner
    ) external returns (uint256);

    function changePotionPrice(
        uint256 _tokenId,
        uint256 _laboId,
        uint256 _price
    ) external returns (bool);

    function updatePotionSaleTimestamp(
        uint256 _tokenId
    ) external returns (bool);

    function getFullPotion(
        uint256 _tokenId
    ) external view returns (PotionStruct.Potion memory);

    function getPotionPowers(
        uint256 _tokenId
    ) external view returns (PotionStruct.Powers memory);

    function updateInterfaces() external;
}

interface IRanking {
    function updatePlayerRankings(
        address _user,
        uint256 _xpWin
    ) external returns (bool);

    function getDayBegining() external view returns (uint256);

    function getDayAndWeekRankingCounter()
        external
        view
        returns (uint256 dayNumber, uint256 weekNumber);

    function updateInterfaces() external;
}

interface IReserveForChalengeRewards {
    function updateRewards() external returns (bool, uint256);
}

interface IReserveForWinRewards {
    function updateRewards() external returns (bool, uint256);
}

interface IRewardsPvP {
    function updateInterfaces() external;
}

interface IRewardsRankingFound {
    function getDailyRewards(
        address _rewardStoringAddress
    ) external returns (uint256);

    function getWeeklyRewards(
        address _rewardStoringAddress
    ) external returns (uint256);

    function updateInterfaces() external;
}

interface IRewardsWinningFound {
    function getWinningRewards(
        uint256 level,
        bool bonus
    ) external returns (uint256);

    function updateInterfaces() external;
}

interface ITraining is IERC721 {
    function mintTrainingCenter(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function numberOfTrainingSpots(
        uint256 _tokenId
    ) external view returns (uint256);

    function addTrainingSpots(
        uint256 _tokenId,
        uint256 _amount
    ) external returns (bool);

    function getPreMintNumber() external view returns (uint256);

    function updateInterfaces() external;
}

interface ITrainingManagement {
    function initSpotsNumber(uint256 _tokenId) external returns (bool);

    function cleanSlotsBeforeClosing(uint256 _laboId) external returns (bool);

    function updateInterfaces() external;
}

interface IZaiNFT is IERC721 {
    function mintZai(
        address _to,
        string memory _name,
        uint256 _state
    ) external returns (uint256);

    function createNewChallenger() external returns (uint256);

    function burnZai(uint256 _tokenId) external returns (bool);
}

interface IZaiMeta {
    function getZaiURI(uint256 tokenId) external view returns (string memory);

    function createZaiDatas(
        uint256 _newItemId,
        string memory _name,
        uint256 _state,
        uint256 _level
    ) external;

    function getZai(
        uint256 _tokenId
    ) external view returns (ZaiStruct.Zai memory);

    function getZaiMinDatasForFight(
        uint256 _tokenId
    ) external view returns (ZaiStruct.ZaiMinDatasForFight memory zaiMinDatas);

    function isFree(uint256 _tokenId) external view returns (bool);

    function updateStatus(
        uint256 _tokenId,
        uint256 _newStatusID,
        uint256 _center,
        uint256 _spotId
    ) external;

    function updateXp(
        uint256 _id,
        uint256 _xp
    ) external returns (uint256 level);

    function updateMana(
        uint256 _tokenId,
        uint256 _manaUp,
        uint256 _manaDown,
        uint256 _maxUp
    ) external returns (bool);

    function getNextLevelUpPoints(
        uint256 _level
    ) external view returns (uint256);

    function updateInterfaces() external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}