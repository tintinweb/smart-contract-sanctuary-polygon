/**
 *Submitted for verification at polygonscan.com on 2023-02-11
*/

// File: contracts/EthermonAdventure.sol

/**
 *Submitted for verification at Etherscan.io on 2018-09-04
 */

pragma solidity ^0.6.6;

library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

contract BasicAccessControl {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) external onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function Kill() external onlyOwner {
        selfdestruct(owner);
    }

    function AddModerator(address _newModerator) external onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) external onlyOwner {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) external onlyOwner {
        isMaintaining = _isMaintaining;
    }
}

contract EtheremonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

interface EtheremonDataBase {
    // read
    function getMonsterClass(uint32 _classId)
        external
        view
        returns (
            uint32 classId,
            uint256 price,
            uint256 returnPrice,
            uint32 total,
            bool catchable
        );

    function getMonsterObj(uint64 _objId)
        external
        view
        returns (
            uint64 objId,
            uint32 classId,
            address trainer,
            uint32 exp,
            uint32 createIndex,
            uint32 lastClaimIndex,
            uint256 createTime
        );

    function getElementInArrayType(
        EtheremonEnum.ArrayType _type,
        uint64 _id,
        uint256 _index
    ) external view returns (uint8);

    function addMonsterObj(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint64);

    function addElementToArrayType(
        EtheremonEnum.ArrayType _type,
        uint64 _id,
        uint8 _value
    ) external returns (uint256);
}

abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        virtual
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        virtual
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        public
        virtual
        returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual returns (bool success);
}

interface ERC721Interface {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
}

interface EtheremonAdventureItem {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function getItemInfo(uint256 _tokenId)
        external
        view
        returns (uint256 classId, uint256 value);

    function spawnItem(
        uint256 _classId,
        uint256 _value,
        address _owner
    ) external returns (uint256);
}

interface EtheremonAdventureSetting {
    function getSiteItem(uint256 _siteId, uint256 _seed)
        external
        view
        returns (
            uint256 _monsterClassId,
            uint256 _tokenClassId,
            uint256 _value
        );

    function getSiteId(uint256 _classId, uint256 _seed)
        external
        view
        returns (uint256);
}

interface EtheremonMonsterNFT {
    function mintMonster(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint256);
}

abstract contract EtheremonAdventureData {
    function addLandRevenue(
        uint256 _siteId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external virtual;

    function addTokenClaim(
        uint256 _tokenId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external virtual;

    function addExploreData(
        address _sender,
        uint256 _typeId,
        uint256 _monsterId,
        uint256 _siteId,
        uint256 _startAt,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external virtual returns (uint256);

    function removePendingExplore(uint256 _exploreId, uint256 _itemSeed)
        external
        virtual;

    // public function
    function getLandRevenue(uint256 _classId)
        public
        view
        virtual
        returns (uint256 _emonAmount, uint256 _etherAmount);

    function getTokenClaim(uint256 _tokenId)
        public
        view
        virtual
        returns (uint256 _emonAmount, uint256 _etherAmount);

    function getExploreData(uint256 _exploreId)
        public
        view
        virtual
        returns (
            address _sender,
            uint256 _typeId,
            uint256 _monsterId,
            uint256 _siteId,
            uint256 _itemSeed,
            uint256 _startAt
        );

    function getPendingExplore(address _player)
        public
        view
        virtual
        returns (uint256);

    function getPendingExploreData(address _player)
        public
        view
        virtual
        returns (
            uint256 _exploreId,
            uint256 _typeId,
            uint256 _monsterId,
            uint256 _siteId,
            uint256 _itemSeed,
            uint256 _startAt
        );
}

contract EtheremonAdventure is EtheremonEnum, BasicAccessControl {
    using AddressUtils for address;

    uint8 public constant STAT_COUNT = 6;
    uint8 public constant STAT_MAX = 32;

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint256 createTime;
    }

    struct ExploreData {
        address sender;
        uint256 monsterType;
        uint256 monsterId;
        uint256 siteId;
        uint256 itemSeed;
        uint256 startAt; // blocknumber
    }

    struct ExploreReward {
        uint256 monsterClassId;
        uint256 itemClassId;
        uint256 value;
        uint256 temp;
    }

    address public dataContract;
    address public monsterNFT;
    address public adventureDataContract;
    address public adventureSettingContract;
    address public adventureItemContract;
    address public tokenContract;
    address public kittiesContract;

    uint256 public exploreETHFee = 0.01 ether;
    uint256 public exploreEMONFee = 1500000000;
    uint256 public exploreFastenETHFee = 0.005 ether;
    uint256 public exploreFastenEMONFee = 7500000000;
    uint256 public minBlockGap = 240;
    uint256 public totalSite = 54;

    uint256 seed = 0;

    event SendExplore(
        address indexed from,
        uint256 monsterType,
        uint256 monsterId,
        uint256 exploreId
    );
    event ClaimExplore(
        address indexed from,
        uint256 exploreId,
        uint256 itemType,
        uint256 itemClass,
        uint256 itemId
    );

    modifier requireDataContract() {
        require(dataContract != address(0));
        _;
    }

    modifier requireAdventureDataContract() {
        require(adventureDataContract != address(0));
        _;
    }

    modifier requireAdventureSettingContract() {
        require(adventureSettingContract != address(0));
        _;
    }

    modifier requireTokenContract() {
        require(tokenContract != address(0));
        _;
    }

    modifier requireKittiesContract() {
        require(kittiesContract != address(0));
        _;
    }

    function setContract(
        address _dataContract,
        address _monsterNFT,
        address _adventureDataContract,
        address _adventureSettingContract,
        address _adventureItemContract,
        address _tokenContract,
        address _kittiesContract
    ) public onlyOwner {
        dataContract = _dataContract;
        monsterNFT = _monsterNFT;
        adventureDataContract = _adventureDataContract;
        adventureSettingContract = _adventureSettingContract;
        adventureItemContract = _adventureItemContract;
        tokenContract = _tokenContract;
        kittiesContract = _kittiesContract;
    }

    function setFeeConfig(
        uint256 _exploreETHFee,
        uint256 _exploreEMONFee,
        uint256 _exploreFastenETHFee,
        uint256 _exploreFastenEMONFee
    ) public onlyOwner {
        exploreETHFee = _exploreETHFee;
        exploreEMONFee = _exploreEMONFee;
        exploreFastenEMONFee = _exploreFastenEMONFee;
        exploreFastenETHFee = _exploreFastenETHFee;
    }

    function setConfig(uint256 _minBlockGap, uint256 _totalSite)
        public
        onlyOwner
    {
        minBlockGap = _minBlockGap;
        totalSite = _totalSite;
    }

    function withdrawEther(address _sendTo, uint256 _amount) public onlyOwner {
        // it is used in case we need to upgrade the smartcontract
        if (_amount > address(this).balance) {
            revert();
        }
        payable(_sendTo).transfer(_amount);
    }

    function withdrawToken(address _sendTo, uint256 _amount)
        external
        onlyOwner
        requireTokenContract
    {
        ERC20Interface token = ERC20Interface(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(_sendTo, _amount);
    }

    function adventureByToken(
        address _player,
        uint256 _token,
        uint256 _param1,
        uint256 _param2,
        uint64 _param3
    ) external isActive {
        // param1 = 1 -> explore, param1 = 2 -> claim
        if (_param1 == 1) {
            _exploreUsingEmon(_player, _param2, _param3, _token);
        } else {
            _claimExploreItemUsingEmon(_param2, _token);
        }
    }

    //  delegatedFwd(
    //     extensionCode,
    //     abi.encodeWithSelector(
    //         StakeManagerExtension(extensionCode).updateCheckpointRewardParams.selector,
    //         _rewardDecreasePerCheckpoint,
    //         _maxRewardedCheckpoints,
    //         _checkpointRewardDelta
    //     )
    // );

    function _exploreUsingEmon(
        address _sender,
        uint256 _monsterType,
        uint256 _monsterId,
        uint256 _token
    ) internal {
        if (_token < exploreEMONFee) revert();
        seed = getRandom(_sender, block.number - 1, seed, _monsterId);
        uint256 siteId = getTargetSite(_sender, _monsterType, _monsterId, seed);
        if (siteId == 0) revert();

        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        uint256 exploreId = adventureData.addExploreData(
            _sender,
            _monsterType,
            _monsterId,
            siteId,
            block.number,
            _token,
            0
        );
        emit SendExplore(_sender, _monsterType, _monsterId, exploreId);
    }

    function _claimExploreItemUsingEmon(uint256 _exploreId, uint256 _token)
        internal
        returns (
            uint256 monsterClassId,
            uint256 itemClassId,
            uint256 value
        )
    {
        // if (_token < exploreFastenEMONFee) revert();

        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        ExploreData memory exploreData;
        (
            exploreData.sender,
            exploreData.monsterType,
            exploreData.monsterId,
            exploreData.siteId,
            exploreData.itemSeed,
            exploreData.startAt
        ) = adventureData.getExploreData(_exploreId);

        require(exploreData.itemSeed == 0, "Item already explored");

        // min 2 blocks
        require(
            block.number > exploreData.startAt + 2,
            "Mon is still Exploring..."
        );

        exploreData.itemSeed =
            getRandom(
                exploreData.sender,
                exploreData.startAt + 1,
                exploreData.monsterId,
                _exploreId
            ) %
            100000;

        if (_token < exploreFastenEMONFee) {
            require(
                block.number >
                    (exploreData.startAt +
                        minBlockGap +
                        (exploreData.startAt % minBlockGap)),
                "Increase EMONs to fast explore"
            );
        }
        ExploreReward memory reward;
        (
            reward.monsterClassId,
            reward.itemClassId,
            reward.value
        ) = EtheremonAdventureSetting(adventureSettingContract).getSiteItem(
            exploreData.siteId,
            exploreData.itemSeed
        );

        adventureData.removePendingExplore(_exploreId, exploreData.itemSeed);

        if (reward.monsterClassId > 0) {
            EtheremonMonsterNFT monsterContract = EtheremonMonsterNFT(
                monsterNFT
            );
            reward.temp = monsterContract.mintMonster(
                uint32(reward.monsterClassId),
                exploreData.sender,
                "..name me.."
            );
            emit ClaimExplore(
                exploreData.sender,
                _exploreId,
                0,
                reward.monsterClassId,
                reward.temp
            );
        } else if (reward.itemClassId > 0) {
            // give new adventure item
            EtheremonAdventureItem item = EtheremonAdventureItem(
                adventureItemContract
            );
            reward.temp = item.spawnItem(
                reward.itemClassId,
                reward.value,
                exploreData.sender
            );
            emit ClaimExplore(
                exploreData.sender,
                _exploreId,
                1,
                reward.itemClassId,
                reward.temp
            );
        }
        //  else if (reward.value > 0) {
        //     // send token contract
        //     ERC20Interface token = ERC20Interface(tokenContract);
        //     token.transfer(exploreData.sender, reward.value);
        //     emit ClaimExplore(
        //         exploreData.sender,
        //         _exploreId,
        //         2,
        //         0,
        //         reward.value
        //     );
        // } else {
        return (reward.monsterClassId, reward.itemClassId, reward.value); //revert();
        //}
    }

    // public

    function getRandom(
        address _player,
        uint256 _block,
        uint256 _seed,
        uint256 _count
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(_block), _player, _seed, _count)
                )
            );
    }

    function getTargetSite(
        address _sender,
        uint256 _monsterType,
        uint256 _monsterId,
        uint256 _seed
    ) public view returns (uint256) {
        if (_monsterType == 0) {
            // Etheremon
            MonsterObjAcc memory obj;
            (
                obj.monsterId,
                obj.classId,
                obj.trainer,
                obj.exp,
                obj.createIndex,
                obj.lastClaimIndex,
                obj.createTime
            ) = EtheremonDataBase(dataContract).getMonsterObj(
                uint64(_monsterId)
            );
            if (obj.trainer != _sender) revert();
            return
                EtheremonAdventureSetting(adventureSettingContract).getSiteId(
                    obj.classId,
                    _seed
                );
        } else if (_monsterType == 1 && kittiesContract != address(0)) {
            // Cryptokitties
            // Can make this address dynamic so other projects can collab with us
            if (_sender != ERC721Interface(kittiesContract).ownerOf(_monsterId))
                revert();
            return
                EtheremonAdventureSetting(adventureSettingContract).getSiteId(
                    _seed % totalSite,
                    _seed
                );
        }
        return 0;
    }

    function exploreUsingETH(uint256 _monsterType, uint256 _monsterId)
        public
        payable
        isActive
    {
        // not allow contract to make txn
        if (msg.sender == tx.origin) revert();

        if (msg.value < exploreETHFee) revert();
        seed = getRandom(msg.sender, block.number - 1, seed, _monsterId);
        uint256 siteId = getTargetSite(
            msg.sender,
            _monsterType,
            _monsterId,
            seed
        );
        if (siteId == 0) revert();
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        uint256 exploreId = adventureData.addExploreData(
            msg.sender,
            _monsterType,
            _monsterId,
            siteId,
            block.number,
            0,
            msg.value
        );
        emit SendExplore(msg.sender, _monsterType, _monsterId, exploreId);
    }

    function claimExploreItem(uint256 _exploreId)
        public
        payable
        isActive
        returns (
            uint256 monsterClassId,
            uint256 itemClassId,
            uint256 value
        )
    {
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        ExploreData memory exploreData;
        (
            exploreData.sender,
            exploreData.monsterType,
            exploreData.monsterId,
            exploreData.siteId,
            exploreData.itemSeed,
            exploreData.startAt
        ) = adventureData.getExploreData(_exploreId);

        if (exploreData.itemSeed != 0) revert();

        // min 2 blocks
        if (block.number < exploreData.startAt + 2) revert();

        exploreData.itemSeed =
            getRandom(
                exploreData.sender,
                exploreData.startAt + 1,
                exploreData.monsterId,
                _exploreId
            ) %
            100000;
        if (msg.value < exploreFastenETHFee) {
            if (
                block.number <
                exploreData.startAt +
                    minBlockGap +
                    (exploreData.startAt % minBlockGap)
            ) revert();
        }

        require(exploreData.monsterId > 0, "Invalid monId");
        EtheremonDataBase monsterData = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = monsterData.getMonsterObj(uint64(exploreData.monsterId));

        // getSiteItem required 1 monId parameter and need to get exp from that from EthermonData contract to get X% from current exp.
        ExploreReward memory reward;
        (
            reward.monsterClassId,
            reward.itemClassId,
            reward.value
        ) = EtheremonAdventureSetting(adventureSettingContract).getSiteItem(
            exploreData.siteId,
            exploreData.itemSeed
        );

        adventureData.removePendingExplore(_exploreId, exploreData.itemSeed);

        if (reward.monsterClassId > 0) {
            EtheremonMonsterNFT monsterContract = EtheremonMonsterNFT(
                monsterNFT
            );
            reward.temp = monsterContract.mintMonster(
                uint32(reward.monsterClassId),
                exploreData.sender,
                "..name me.."
            );
            emit ClaimExplore(
                exploreData.sender,
                _exploreId,
                0,
                reward.monsterClassId,
                reward.temp
            );
        } else if (reward.itemClassId > 0) {
            // give new adventure item
            EtheremonAdventureItem item = EtheremonAdventureItem(
                adventureItemContract
            );
            // Is exp a nft because we are minting it in EthermonAdventureItem and we are adding exp in AdventureHandle -> useSingleItem().
            reward.temp = item.spawnItem(
                reward.itemClassId,
                reward.value,
                exploreData.sender
            );
            emit ClaimExplore(
                exploreData.sender,
                _exploreId,
                1,
                reward.itemClassId,
                reward.temp
            );
        }
        return (reward.monsterClassId, reward.itemClassId, reward.value);
    }

    // public

    function predictExploreReward(uint256 _exploreId)
        external
        view
        returns (
            uint256 itemSeed,
            uint256 rewardMonsterClass,
            uint256 rewardItemCLass,
            uint256 rewardValue
        )
    {
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        ExploreData memory exploreData;
        (
            exploreData.sender,
            exploreData.monsterType,
            exploreData.monsterId,
            exploreData.siteId,
            exploreData.itemSeed,
            exploreData.startAt
        ) = adventureData.getExploreData(_exploreId);

        if (exploreData.itemSeed != 0) {
            itemSeed = exploreData.itemSeed;
        } else {
            if (block.number < exploreData.startAt + 2) revert(); //return (0, 0, 0, 0);
            itemSeed =
                getRandom(
                    exploreData.sender,
                    exploreData.startAt + 1,
                    exploreData.monsterId,
                    _exploreId
                ) %
                100000;
        }
        (
            rewardMonsterClass,
            rewardItemCLass,
            rewardValue
        ) = EtheremonAdventureSetting(adventureSettingContract).getSiteItem(
            exploreData.siteId,
            itemSeed
        );
    }

    function getExploreItem(uint256 _exploreId)
        external
        view
        returns (
            address trainer,
            uint256 monsterType,
            uint256 monsterId,
            uint256 siteId,
            uint256 startBlock,
            uint256 rewardMonsterClass,
            uint256 rewardItemClass,
            uint256 rewardValue
        )
    {
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        (
            trainer,
            monsterType,
            monsterId,
            siteId,
            rewardMonsterClass,
            startBlock
        ) = adventureData.getExploreData(_exploreId);

        if (rewardMonsterClass > 0) {
            (
                rewardMonsterClass,
                rewardItemClass,
                rewardValue
            ) = EtheremonAdventureSetting(adventureSettingContract).getSiteItem(
                siteId,
                rewardMonsterClass
            );
        }
    }

    function getPendingExploreItem(address _trainer)
        external
        view
        returns (
            uint256 exploreId,
            uint256 monsterType,
            uint256 monsterId,
            uint256 siteId,
            uint256 startBlock,
            uint256 endBlock
        )
    {
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        (
            exploreId,
            monsterType,
            monsterId,
            siteId,
            endBlock,
            startBlock
        ) = adventureData.getPendingExploreData(_trainer);
        if (exploreId > 0) {
            endBlock = startBlock + minBlockGap + (startBlock % minBlockGap);
        }
    }
}