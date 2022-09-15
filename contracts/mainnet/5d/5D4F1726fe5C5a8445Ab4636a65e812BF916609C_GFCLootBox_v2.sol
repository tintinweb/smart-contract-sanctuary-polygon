// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Burnable.sol";

import "./Ownable.sol";

import "./Strings.sol";

import "./VRFConsumerBaseV2.sol";

import "./IVRFCoordinatorV2.sol";

import "./Whitelist.sol";

import "./GFCGenesisKey_Polygon.sol";

import "./GFCGenesisWeapon.sol";

import "./BYOPillGFC.sol";

import "./GFCMysteryItem.sol";

import "./IKeyNft.sol";

import "./ReentrancyGuard.sol";

import "./IERC20.sol";

contract GFCLootBox_v2 is Ownable, Whitelist, ReentrancyGuard, VRFConsumerBaseV2 {
    using Strings for uint256;

    VRFCoordinatorV2Interface COORDINATOR;
    GFCGenesisKeyPoly public genesisKey;
    GFCGenesisWeapon public genesisWeapon;
    BYOPillGFC public byoPill;
    IKeyNft public key;
    GFCMysteryItem public mysteryItem;
    
    uint256 private constant ROLL_IN_PROGRESS = 42;

    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;

    address gCoin = 0x071AC29d569a47EbfFB9e57517F855Cb577DCc4C;

    bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;

    uint64 s_subscriptionId;

    uint16 requestConfirmations = 3;

    uint32 callbackGasLimit = 2400000;

    uint256 public gCoinPayAmount = 200 ether;

    //Number of burnt keys
    uint256 public BURNT_KEYS;

    //In case we need to pause opening
    bool public paused;
    //In case we need to pause P2E Keys opening
    bool public keyPaused;

    uint256[][2] public PROBs;
    uint16[] public meleeWeaponCount;

    //arrays of total number of ranged weapons in each tier
    uint16[] public rangedWeaponCount;

    struct KeyInfo{
        uint256 tier; //1-3
        uint256 amount;
    }
    
    mapping(uint256 => address) private s_rollers;
    mapping(address => uint256[]) private s_results;
    mapping(address => uint256) private s_pending_status;
    mapping(address => KeyInfo) public addressGenesisKeyInfo;
    mapping(address => KeyInfo) public addressKeyInfo;

    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256[] indexed result);
    event WeaponMinted(uint256 indexed transactionId, uint256 weaponId, uint256 amount);
    event BYOPillMinted(uint256 indexed transactionId, uint256 pillId, uint256 amount);
    event MysterItemMinted(uint256 indexed transactionId, uint256 ItemId, uint256 amount);
    event LootBoxesOpened(uint256 indexed transactionId);

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        //fill in the addresses for the corresponding contract addresses before deployment
        genesisKey = GFCGenesisKeyPoly(address(0x3702f4C46785BbD947d59A2516ac1ea30F2BAbF2));
        genesisWeapon = GFCGenesisWeapon(address(0xCbc964dd716F07b4965B4526E30541a66F414ccF));
        byoPill = BYOPillGFC(address(0xB581Cc7a3211674D6484a11C8663b9011B600EEE));
        mysteryItem = GFCMysteryItem(address(0xFd24D200C6715f3C0a2DdF8a8b128952eFed7724));
        key = IKeyNft(address(0x67a7aE8E3B3e1E58e2a105B4C7413a5506169476));

        //Probability for Tiers with gold key
        PROBs[0] = [0, 80000, 15000, 4000, 1000, 500, 5, 2, 1];
        //Probability for Tiers with silver key
        PROBs[1] = [0, 92000, 6000, 1000, 500];
        meleeWeaponCount =    [0, 7, 7, 1, 1, 1, 1, 1, 1];
        rangedWeaponCount =   [0, 3, 2, 1, 1, 1, 1, 1, 1];
    }

    function setGCoinPayAmount(uint256 _amount) external onlyOwner {
        gCoinPayAmount = _amount;
    }

    function _transferGCoin(uint256 amount) internal {
        require(IERC20(gCoin).balanceOf(msg.sender) >= gCoinPayAmount * amount, "Insufficient gcoin amount");
        require(IERC20(gCoin).allowance(msg.sender, address(this)) >= gCoinPayAmount * amount, "Insufficient gcoin allowance amount");

        IERC20(gCoin).transferFrom(msg.sender, address(this), gCoinPayAmount * amount);
    }

    /**
        First Step on opening loot bxo
        Burn keys and request random number from Chainlink
     */
    function getRandom(uint256 tier, uint256 amount) external {
        require(!paused, "The contract have been paused");
        require(tier > 0 && tier < 4, "invalid tier input (must be 1,2 or 3)");
        require(genesisKey.balanceOf(msg.sender, tier) >= amount, "You don't have enough keys to open this many loot boxes");
        genesisKey.burn(msg.sender, tier, amount);
        getRandNum4LootBox(amount);
        addressGenesisKeyInfo[msg.sender] = KeyInfo(tier, amount);
    }

    function getKeyRandom(uint256 keyId, uint256 amount) external {
        require(!keyPaused, "The contract have been paused");
        require(key.balanceOf(msg.sender, keyId) >= amount, "You don't have enough keys to open this many loot boxes");
        _transferGCoin(amount);
        key.burn(msg.sender, keyId, amount);
        getRandNum4LootBox(amount * 3);
        addressKeyInfo[msg.sender] = KeyInfo(keyId, amount);
    }

    /**
        Second Step on opening loot box
        Check if the random number has been generated
        if so, continute to mint the loot box content for the user
     */
    function openLootBox(uint256 transactionId) nonReentrant external {
        require(!paused, "The contract have been paused");
        uint256[] memory randNums = getResult(msg.sender);
        KeyInfo storage kInfo = addressGenesisKeyInfo[msg.sender];
        BURNT_KEYS += kInfo.amount;
        //Reset the random number for next time
        s_results[msg.sender] = new uint256[](0);
        if(kInfo.tier == 1) {
            openTier1LootBox(transactionId, kInfo.amount, randNums);
        }else if(kInfo.tier == 2) {
            openTier2LootBox(transactionId, kInfo.amount, randNums);
        }else if(kInfo.tier == 3) {
            openTier3LootBox(transactionId, kInfo.amount, randNums);
        }
    }

    function openGoldSilverLootBox(uint256 transactionId) external nonReentrant {
        require(!keyPaused, "The contract have been paused");
        uint256[] memory randNums = getResult(msg.sender);
        KeyInfo storage kInfo = addressKeyInfo[msg.sender];
        BURNT_KEYS += kInfo.amount;
        //Reset the random number for next time
        s_results[msg.sender] = new uint256[](0);
        if(kInfo.tier == 0) {
            openGoldKeyLootBox(transactionId, kInfo.amount, randNums);
        }else if(kInfo.tier == 1) {
            openSilverKeyLootBox(transactionId, kInfo.amount, randNums);
        }
    }

    function rarityGen(uint256 _randinput, uint256 number) internal view returns (uint8)
    {
        uint256 currentLowerBound = 0;
        for (uint8 i = 0; i < PROBs[number].length; i++) {
          uint256 thisPercentage = PROBs[number][i];
          if(thisPercentage == 0){
            continue;
          }
          if (
              _randinput >= currentLowerBound &&
              _randinput < currentLowerBound + thisPercentage
          ) return i;
          currentLowerBound = currentLowerBound + thisPercentage;
        }
        return 1;
    }
    function getGoldSiverKeyRangedOrMaleeWeaponId(uint256 index, uint256[] memory randNums, uint256 keyType) internal view returns(uint256) {
        uint256 weaponCategory = randNums[index * 3 + 1] % 2 == 0 ? 3 : 4;
        uint8 weaponTier = rarityGen(randNums[index * 3] % 100000, keyType);
        uint256 weaponSubId = randNums[index * 3 + 2] % (weaponCategory == 3 ? meleeWeaponCount[weaponTier] : rangedWeaponCount[weaponTier]);
        uint256 weaponId = weaponCategory * 10000 + weaponTier * 1000 + weaponSubId;
        return weaponId;
    }

    function openGoldKeyLootBox(uint256 transactionId, uint256 amount, uint256[] memory randomNums) internal {
        for (uint256 i = 0; i < amount; i += 1) {
            uint256 weaponId = getGoldSiverKeyRangedOrMaleeWeaponId(i, randomNums, 0);
            genesisWeapon.mintWeapon(msg.sender, weaponId, 1);
            emit WeaponMinted(transactionId, weaponId, 1);
        }
    }

    function openSilverKeyLootBox(uint256 transactionId, uint256 amount, uint256[] memory randomNums) internal {
        for (uint256 i = 0; i < amount; i += 1) {
            uint256 weaponId = getGoldSiverKeyRangedOrMaleeWeaponId(i, randomNums, 1);
            genesisWeapon.mintWeapon(msg.sender, weaponId, 1);
            emit WeaponMinted(transactionId, weaponId, 1);
        }
    }

    function openTier1LootBox(uint256 transactionId, uint256 amount, uint256[] memory randomNums) internal{
        for(uint256 j = 0; j < amount; j++) {
            uint256 weaponId = genesisWeapon.MintTier1KeyMeleeWeapon(msg.sender, 1, randomNums[j]);
            emit WeaponMinted(transactionId, weaponId, 1);
            weaponId = genesisWeapon.MintTier1KeyRangedWeapon(msg.sender, 1, randomNums[j]);
            emit WeaponMinted(transactionId, weaponId, 1);
            mintByoPill(transactionId, randomNums[j]);
            if(randomNums[j]%10000 <= 4000) {
                uint256 itemId = mysteryItem.mintMysteryItem(msg.sender, 1, randomNums[j]);
                emit MysterItemMinted(transactionId, itemId, 1);
            }
        }
        emit LootBoxesOpened(transactionId);
    }

    function openTier2LootBox(uint256 transactionId, uint256 amount, uint256[] memory randomNums) internal{
        for(uint256 j = 0; j < amount; j++) {
            uint256 weaponId = genesisWeapon.MintTier2KeyRangedWeapon(msg.sender, 1, randomNums[j]);
            emit WeaponMinted(transactionId, weaponId, 1);
            mintByoPill(transactionId, randomNums[j]);
        }
        emit LootBoxesOpened(transactionId);
    }

    function openTier3LootBox(uint256 transactionId, uint256 amount, uint256[] memory randomNums) internal{
        for(uint256 j = 0; j < amount; j++) {
            uint256 weaponId = genesisWeapon.MintTier3KeyMeleeWeapon(msg.sender, 1, randomNums[j]);
            emit WeaponMinted(transactionId, weaponId, 1);
            mintByoPill(transactionId, randomNums[j]);
        }
        emit LootBoxesOpened(transactionId);
    }

    /**
     * Requests randomwords (Chainlink VRF V2)
     */
    function getRandNum4LootBox(uint256 amount) internal {
        require(s_results[msg.sender].length == 0, "Already rolled");
        uint256 s_requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, uint32(amount));
        s_rollers[s_requestId] = msg.sender;
        s_pending_status[msg.sender] = ROLL_IN_PROGRESS;
        emit DiceRolled(s_requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_results[s_rollers[requestId]] = randomWords;
        s_pending_status[s_rollers[requestId]] = 0;
        emit DiceLanded(requestId, randomWords);
    }

    function mintByoPill(uint256 transactionId, uint256 randNum) internal{
        uint256 pillId = byoPill.randomMint(msg.sender, 1, randNum);
        emit BYOPillMinted(transactionId, pillId, 1);
    }

    function setGenesisKey(address _genesisKey) external onlyOwner {
		genesisKey = GFCGenesisKeyPoly(_genesisKey);
	}

    function setGenesisWeapon(address _weapon) external onlyOwner {
		genesisWeapon = GFCGenesisWeapon(_weapon);
	}

    function setBYOPill(address _pill) external onlyOwner {
		byoPill = BYOPillGFC(_pill);
	}

    function setMysteryItem(address _item) external onlyOwner {
		mysteryItem = GFCMysteryItem(_item);
	}

    function setKey(address _key) external onlyOwner {
		key = IKeyNft(_key);
	}

    function setProbs(uint256 index, uint16[] memory PROBsArray) external onlyOwner {
        PROBs[index] = PROBsArray;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function toggleKeyPaused() external onlyOwner {
        keyPaused = !keyPaused;
    }

    function withdrawMatic() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "Unable to withdraw MATIC");
    }
    
    /**
     * @notice Get the random number if VRF callback on the fulfillRandomness function
     * @return the random number generated by chainlink VRF
     */
    function getResult(address addr) public view returns (uint256[] memory) {
        require(s_results[addr].length != 0, "Dice not rolled");
        require(s_pending_status[addr] != ROLL_IN_PROGRESS, "Roll in progress");
        return s_results[addr];
    }

    function withdrawGCoin() external onlyOwner {
        IERC20(gCoin).transfer(msg.sender, IERC20(gCoin).balanceOf(address(this)));
    }
}