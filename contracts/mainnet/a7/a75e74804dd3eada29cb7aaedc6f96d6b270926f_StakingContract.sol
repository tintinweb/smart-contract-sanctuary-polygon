// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./MagicWand.sol";
import "./SPELLPOWER.sol";

contract StakingContract is Ownable {

    MagicWand public magicWand;
    MagicWand public mysticAmulet;
    SPELLPOWER public spellpower;

    // 10 $Spellpower per day for staked wand
    uint256 public DAILY_SPELLPOWER_RATE_WAND = 10 ether;

    // 2 $Spellpower per day for staked amulet
    uint256 public DAILY_SPELLPOWER_RATE_AMULET = 2 ether;

    // Maximum to be earned from staking is 5 million $Spellpower
    uint256 public constant MAXIMUM_SPELLPOWER_FOR_MINT = 5000000 ether;

    bool public paused = true;

    struct StakingMagicWand {
        uint256 timestamp;
        address owner;
    }

    struct StakingMysticAmulet {
        uint256 timestamp;
        address owner;
    }

    mapping(uint256 => StakingMagicWand) public magicWandStakings;
    mapping(address => uint8) public numberOfStakedMagicWands;
    mapping(address => uint256[]) public magicWandStakingsByOwner;
    uint256 public stakedMagicWandsCount;

    mapping(uint256 => StakingMysticAmulet) public mysticAmuletStakings;
    mapping(address => uint8) public numberOfStakedMysticAmulets;
    mapping(address => uint256[]) public mysticAmuletStakingsByOwner;
    uint256 public stakedMysticAmuletsCount;

    constructor(address _spellpower, address _magicWand, address _mysticAmulet){
        spellpower = SPELLPOWER(_spellpower);
        magicWand = MagicWand(_magicWand);
        mysticAmulet = MagicWand(_mysticAmulet);
    }

    ///////////////////////////////////////////////////////////////////////////////

    function stakeMagicWand(uint256 tokenId) public checkIfPaused{
        require(magicWand.ownerOf(tokenId) == msg.sender, "You must own that magic wand");
        require(magicWand.isApprovedForAll(msg.sender, address(this)));

        StakingMagicWand memory staking = StakingMagicWand(block.timestamp, msg.sender);
        magicWandStakings[tokenId] = staking;
        magicWandStakingsByOwner[msg.sender].push(tokenId);
        numberOfStakedMagicWands[msg.sender]++;

        magicWand.transferFrom(msg.sender, address(this), tokenId);

        stakedMagicWandsCount++;
    }

    function batchStakeMagicWands(uint256[] memory tokenIds) external checkIfPaused{
        for (uint8 i = 0; i < tokenIds.length; i++) {
            stakeMagicWand(tokenIds[i]);
        }
    }

    function unstakeMagicWand(uint256 tokenId) public {
        require(magicWand.ownerOf(tokenId) == address(this), "Magic wand must be staked");
        StakingMagicWand storage staking = magicWandStakings[tokenId];
        require(staking.owner == msg.sender, "You must own that magic wand");
        uint256[] storage stakedMagicWand = magicWandStakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedMagicWand.length; index++) {
            if (stakedMagicWand[index] == tokenId) {
                break;
            }
        }
        require(index < stakedMagicWand.length, "Magic wand not found");
        stakedMagicWand[index] = stakedMagicWand[stakedMagicWand.length - 1];
        stakedMagicWand.pop();
        numberOfStakedMagicWands[msg.sender]--;
        staking.owner = address(0);
        magicWand.transferFrom(address(this), msg.sender, tokenId);
        stakedMagicWandsCount--;
    }

    function batchUnstakeMagicWands(uint256[] memory tokenIds) external {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            unstakeMagicWand(tokenIds[i]);
        }
    }

    function calculateWandReward(StakingMagicWand memory staking) public view returns (uint256) {
        uint256 amount = ((block.timestamp - staking.timestamp) * DAILY_SPELLPOWER_RATE_WAND) / 1 days;

        if(spellpower.totalSupply() + amount >= MAXIMUM_SPELLPOWER_FOR_MINT){
            return MAXIMUM_SPELLPOWER_FOR_MINT - spellpower.totalSupply();
        }
        else{
            return amount;
        }
    }

    function _claimWandRewards(uint256 tokenId, bool unstake) internal returns (uint256 calculatedRewards) {
        StakingMagicWand storage staking = magicWandStakings[tokenId];

        require(staking.owner == msg.sender, "You must be the owner of that staked magic wand.");

        calculatedRewards = calculateWandReward(staking);

        if (unstake) {
            unstakeMagicWand(tokenId);
        }
        else {
            staking.timestamp = block.timestamp;
        }
    }

    function claimWandRewards(uint16[] calldata tokenIds, bool unstake) external checkIfPaused{
        require(spellpower.totalSupply() < MAXIMUM_SPELLPOWER_FOR_MINT, "Spellpower token supply depleted.");
        require(tx.origin == msg.sender);

        uint256 calculatedRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            calculatedRewards += _claimWandRewards(tokenIds[i], unstake);
        }

        if (calculatedRewards == 0){
            return;
        }

        spellpower.mint(msg.sender, calculatedRewards);
    }

    ///////////////////////////////////////////////////////////////////////////////

    function stakeMysticAmulet(uint256 tokenId) public checkIfPaused{
        require(mysticAmulet.ownerOf(tokenId) == msg.sender, "You must own that mystic amulet");
        require(mysticAmulet.isApprovedForAll(msg.sender, address(this)));

        StakingMysticAmulet memory staking = StakingMysticAmulet(block.timestamp, msg.sender);
        mysticAmuletStakings[tokenId] = staking;
        mysticAmuletStakingsByOwner[msg.sender].push(tokenId);
        numberOfStakedMysticAmulets[msg.sender]++;

        mysticAmulet.transferFrom(msg.sender, address(this), tokenId);

        stakedMysticAmuletsCount++;
    }

    function batchStakeMysticAmulets(uint256[] memory tokenIds) external checkIfPaused{
        for (uint8 i = 0; i < tokenIds.length; i++) {
            stakeMysticAmulet(tokenIds[i]);
        }
    }

    function unstakeMysticAmulet(uint256 tokenId) public {
        require(mysticAmulet.ownerOf(tokenId) == address(this), "Mystic amulet must be staked");
        StakingMysticAmulet storage staking = mysticAmuletStakings[tokenId];
        require(staking.owner == msg.sender, "You must own that mystic amulet");
        uint256[] storage stakedMysticAmulet = mysticAmuletStakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedMysticAmulet.length; index++) {
            if (stakedMysticAmulet[index] == tokenId) {
                break;
            }
        }
        require(index < stakedMysticAmulet.length, "Magic wand not found");
        stakedMysticAmulet[index] = stakedMysticAmulet[stakedMysticAmulet.length - 1];
        stakedMysticAmulet.pop();
        numberOfStakedMysticAmulets[msg.sender]--;
        staking.owner = address(0);
        mysticAmulet.transferFrom(address(this), msg.sender, tokenId);
        stakedMysticAmuletsCount--;
    }

    function batchUnstakeMysticAmulets(uint256[] memory tokenIds) external {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            unstakeMysticAmulet(tokenIds[i]);
        }
    }

    function calculateAmuletReward(StakingMysticAmulet memory staking) public view returns (uint256) {
        uint256 amount = ((block.timestamp - staking.timestamp) * DAILY_SPELLPOWER_RATE_AMULET) / 1 days;

        if(spellpower.totalSupply() + amount >= MAXIMUM_SPELLPOWER_FOR_MINT){
            return MAXIMUM_SPELLPOWER_FOR_MINT - spellpower.totalSupply();
        }
        else{
            return amount;
        }
    }

    function _claimAmuletRewards(uint256 tokenId, bool unstake) internal returns (uint256 calculatedRewards) {
        StakingMysticAmulet storage staking = mysticAmuletStakings[tokenId];

        require(staking.owner == msg.sender, "You must be the owner of that staked mystic amulet.");

        calculatedRewards = calculateAmuletReward(staking);

        if (unstake) {
            unstakeMysticAmulet(tokenId);
        }
        else {
            staking.timestamp = block.timestamp;
        }
    }

    function claimAmuletRewards(uint16[] calldata tokenIds, bool unstake) external checkIfPaused{
        require(spellpower.totalSupply() < MAXIMUM_SPELLPOWER_FOR_MINT, "Spellpower token supply depleted.");
        require(tx.origin == msg.sender);

        uint256 calculatedRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            calculatedRewards += _claimAmuletRewards(tokenIds[i], unstake);
        }

        if (calculatedRewards == 0){
            return;
        }

        spellpower.mint(msg.sender, calculatedRewards);
    }

    ///////////////////////////////////////////////////////////////////////////////

    function setMagicWandCollection(address collection) external onlyOwner{
        magicWand = MagicWand(collection);
    }

    function setMysticAmuletCollection(address collection) external onlyOwner{
        mysticAmulet = MagicWand(collection);
    }

    function setRewardCollection(address collection) external onlyOwner{
        spellpower = SPELLPOWER(collection);
    }

    function changeDailySpellpowerRateWand(uint256 amount) external onlyOwner{
        DAILY_SPELLPOWER_RATE_WAND = amount;
    }

    function changeDailySpellpowerRateAmulet(uint256 amount) external onlyOwner{
        DAILY_SPELLPOWER_RATE_AMULET = amount;
    }

    function togglePause() external onlyOwner{
        paused = !paused;
    }

    modifier checkIfPaused() {
        require(!paused, "Contract paused");
        _;
    }

}