// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";

import "./Strings.sol";

import "./VRFConsumerBaseV2.sol";

import "./IVRFCoordinatorV2.sol";

import "./Whitelist.sol";

import "./GFCGenesisWeapon.sol";

import "./SafeERC20.sol";

contract GFCBlackSmith is Ownable, Whitelist, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    VRFCoordinatorV2Interface COORDINATOR;
    GFCGenesisWeapon public genesisWeapon;

    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;

    bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;

    uint64 s_subscriptionId;

    uint16 requestConfirmations = 3;

    uint32 callbackGasLimit = 100000;

    // ERC20 basic token contract being held
    IERC20 public immutable TOKEN;
    
    uint256 private constant ROLL_IN_PROGRESS = 42;

    //The amount of GCOIN burnt to forge
    uint256 public forgeCost = 500 ether;

    //arrays of total number of melee weapons in each tier
    uint16[] public meleeWeaponCount;

    //arrays of total number of ranged weapons in each tier
    uint16[] public rangedWeaponCount;

    uint16[] public meleeP2eWeaponCount;

    uint16[] public rangedP2eWeaponCount;

    //arrays of number of weapon required to forge the next tier
    uint16[] public weaponForgeRate;

    //In case we need to pause weapon forge
    bool public paused;

    struct ForgeInfo{
        uint256 category; //1: melee, 2: ranged
        uint256 tier; //1-7
        uint256 forgeType; //1: basic forge, 2: forge with OG, 3: asteroids forge
    }
    
    mapping(uint256 => address) private s_rollers;
    mapping(address => uint256) private s_results;
    mapping(address => ForgeInfo) public addressForgeInfo;

    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);
    event WeaponForged(address indexed account, uint256 tokenId, uint256 indexed transactionId);
    event RewardMinted(address indexed account, uint256 tokenId, uint256 indexed transactionId);

    constructor(IERC20 token_, uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) 
    {
        TOKEN = token_;
        s_subscriptionId = subscriptionId;

        //fill in the addresses for the corresponding contract addresses before deployment
        genesisWeapon = GFCGenesisWeapon(address(0xCbc964dd716F07b4965B4526E30541a66F414ccF));

        //Initalise the total number of weapons
        meleeWeaponCount =    [0, 3, 2, 1, 3, 2, 1, 1, 1];
        rangedWeaponCount =   [0, 2, 4, 11, 5, 6, 2, 1, 1];

        meleeP2eWeaponCount = [0, 7, 7, 1, 1, 1, 1, 1, 1];
        rangedP2eWeaponCount = [0, 3, 2, 1, 1, 1, 1, 1, 1];

        //Initalise the weapon forge rate;
        weaponForgeRate = [0, 4, 4, 3, 2, 2, 2, 2];
    }

    /** 
     * Requests randomness 
     */
    function getRandNum4Forge() public {
        require(s_results[msg.sender] == 0, "Already rolled");
        uint256 requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, 1);
        s_rollers[requestId] = msg.sender;
        s_results[msg.sender] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_results[s_rollers[requestId]] = randomWords[0];
        emit DiceLanded(requestId, randomWords[0]);
    }
    
    function chargeGCOIN() internal {
        //Charge user the GCOIN required from the forge
        IERC20(TOKEN).safeTransferFrom(msg.sender, address(this), forgeCost);
    }

    function forgeWeapon(uint256 category, uint256 tier, uint256[] calldata amounts) public{
        require(!paused, "The contract have been paused");
        require(s_results[msg.sender] == 0, "Random number pending or rolled");
        require(tier > 0 && tier < 9, "invalid tier input (must be between 1 and 8)");
        require(category > 0 && category < 5, "invalid category (must be 1, 2, 3, or 4)");
        checkIngredients(category, tier, amounts);
        burnIngredients(category, tier, amounts);
        chargeGCOIN();
        getRandNum4Forge();
        addressForgeInfo[msg.sender] = ForgeInfo(category, tier, 1);
    }

    function forgeWithOGWeapon(uint256 category, uint256[] calldata amounts) public {
        require(!paused, "The contract have been paused");
        require(s_results[msg.sender] == 0, "Random number pending or rolled");
        require(category > 0 && category < 5, "invalid category (must be 1, 2, 3 or 4)");
        uint tier = 0;
        if(category == 1) {
            require(genesisWeapon.balanceOf(msg.sender, 13001) > 0, "You must have at least 1 OG's boxing gloves");
            tier = 3;
            checkIngredients(category, tier, amounts);
            burnIngredients(category, tier, amounts);
            chargeGCOIN();
            getRandNum4Forge();
        }else if(category == 2) {
            require(genesisWeapon.balanceOf(msg.sender, 24005) > 0, "You must have at least 1 Doctore's crossbow");
            tier = 4;
            checkIngredients(category, tier, amounts);
            burnIngredients(category, tier, amounts);
            chargeGCOIN();
            getRandNum4Forge();
        }else{
            revert();
        }
        addressForgeInfo[msg.sender] = ForgeInfo(category, tier, 2);
    }

    function smith(uint256 transactionId) public {
        require(!paused, "The contract have been paused");
        require(s_results[msg.sender] != 0, "Dice not rolled");
        require(s_results[msg.sender] != ROLL_IN_PROGRESS, "Roll in progress");
        ForgeInfo storage fInfo = addressForgeInfo[msg.sender];
        uint256 tokenId;
        if(fInfo.forgeType == 1) {
            tokenId = mintNextTier(fInfo.category, fInfo.tier);
            emit WeaponForged(msg.sender, tokenId, transactionId);
        }else if(fInfo.forgeType == 2) {
            tokenId = smithOGWeapon(fInfo.category);
            emit WeaponForged(msg.sender, tokenId, transactionId);
        }else {
            revert();
        }
        s_results[msg.sender] = 0;
    }

    function smithOGWeapon(uint256 category) internal returns (uint256){
        uint256 tokenId;
        uint256 randNum;
        uint256 tier;
        if(category == 1) {
            randNum = getResult(msg.sender);
            tier = 3;
            //33% chance to skip a tier
            if(randNum % 100 <= 33) {tier++;}
            tokenId = mintNextTier(category, tier);
        }else if(category == 2) {
            randNum = getResult(msg.sender);
            tier = 4;
            //50% chance to skip a tier
            if(randNum % 100 <= 50) {tier++;}
            tokenId = mintNextTier(category, tier);
        }else{
            revert();
        }
        return tokenId;
    }

    function checkIngredients(uint256 category, uint256 tier, uint256[] calldata amounts) internal view{
        uint256 totalAmount = 0;
        for(uint256 i = 0; i < amounts.length; i++) {
            require(genesisWeapon.balanceOf(msg.sender, category*10000 + tier*1000 + i) >= amounts[i], "You must have enough of that type of weapon");
            totalAmount += amounts[i];
        }
        require(totalAmount == weaponForgeRate[tier], "Number of weapons selected not equal to burn rate");
    }

    function burnIngredients(uint256 category, uint256 tier, uint256[] memory amounts) internal {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                genesisWeapon.burn(msg.sender, category * 10000 + tier * 1000 + i, amounts[i]);
            }
        }
    }

    function mintNextTier(uint256 category, uint256 tier) internal returns (uint256){
        uint256 randNum = getResult(msg.sender);
        uint256 weaponId = 11000;
        tier++;
        if(category == 1){
            uint256 weaponType = randNum % meleeWeaponCount[tier];
            weaponId = category*10000 + tier*1000 + weaponType; 
        } else if (category == 2) {
            uint256 weaponType = randNum % rangedWeaponCount[tier];
            weaponId = category*10000 + tier*1000 + weaponType; 
        } else if (category == 3) {
            uint256 weaponType = randNum % meleeP2eWeaponCount[tier];
            weaponId = category*10000 + tier*1000 + weaponType;
        } else if (category == 4) {
            uint256 weaponType = randNum % rangedP2eWeaponCount[tier];
            weaponId = category*10000 + tier*1000 + weaponType;
        }
        return genesisWeapon.mintWeapon(msg.sender, weaponId, 1);
    }

    function setGenesisWeapon(address _weapon) external onlyOwner {
		genesisWeapon = GFCGenesisWeapon(_weapon);
	}

    function setForgeCost(uint256 _cost) external onlyOwner {
		forgeCost = _cost;
	}

    function setMeleeP2eCount(uint16[] calldata array) public onlyOwner {
        meleeP2eWeaponCount = array;
    }

    function setRangedP2eCount(uint16[] calldata array) public onlyOwner {
        rangedP2eWeaponCount = array;
    }

    function setMeleeCount(uint16[] calldata array) public onlyOwner{
        meleeWeaponCount = array;
    }

    function setRangedCount(uint16[] calldata array) public onlyOwner{
        rangedWeaponCount = array;
    }

    function setWeaponForgeRate(uint16[] calldata array) public onlyOwner{
        weaponForgeRate = array;
    }

    function togglePause() public onlyOwner{
        paused = !paused;
    }

    function withdrawGCOIN() external onlyOwner {
        IERC20(TOKEN).safeTransfer(msg.sender, IERC20(TOKEN).balanceOf(address(this)));
    }
    
    /**
     * @notice Get the random number if VRF callback on the fulfillRandomness function
     * @return the random number generated by chainlink VRF
     */
    function getResult(address addr) public view returns (uint256) {
        require(s_results[addr] != 0, "Dice not rolled");
        require(s_results[addr] != ROLL_IN_PROGRESS, "Roll in progress");
        return s_results[addr];
    }
}