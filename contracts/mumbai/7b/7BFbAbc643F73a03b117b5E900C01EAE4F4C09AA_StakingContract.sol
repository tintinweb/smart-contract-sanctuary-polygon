// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";
import "./ElfOrcToken.sol";
import "./Mana.sol";

contract StakingContract is Ownable, VRFConsumerBase{
    bytes32 keyHash;
    uint256 fee;

    ElfOrcToken public elfOrc;
    Mana public mana;

    // 20 $Mana per day
    uint256 public DAILY_MANA_RATE = 20 ether;
    
    // Minimum 2 days to unstake
    uint256 public constant MINIMUM_TO_UNSTAKE = 2 days;

    // Minimum 1 day to claim rewards
    uint256 public constant MINIMUM_TO_CLAIM = 1 days;

    // Orcs get 25% of all claimed $Mana
    uint256 public constant MANA_TAX_PERCENTAGE = 25;

    // Maximum to be earned from staking is 5 million $Mana
    uint256 public constant MAXIMUM_MANA_FOR_MINT = 5000000 ether;

    // If claim elf rewards after 3 days, not paying tax
    uint256 public constant TAX_FREE_DAYS = 3 days;

    uint256[] public ambushPrices = [3 ether, 6 ether, 9 ether, 12 ether, 14 ether];

    bool public paused = true;

    struct StakingElf {
        uint256 timestamp;
        address owner;
        uint256 stolen;
    }

    struct StakingOrc {
        uint256 timestamp;
        address owner;
        uint256 tax;
    }

    uint256 public manaTaxPerOrc = 0;
    uint256 public unaccountedRewards = 0;

    mapping(uint256 => StakingElf) public elfStakings;
    mapping(address => uint8) public numberOfStakedElfs;
    mapping(address => uint256[]) public elfStakingsByOwner;

    mapping(uint256 => StakingOrc) public orcStakings;
    mapping(address => uint8) public numberOfStakedOrcs;
    mapping(address => uint256[]) public orcStakingsByOwner;
    mapping(uint256 => uint256) public orcAmbushCount;
    mapping(uint256 => uint256) public lastAmbushTime;

    mapping(bytes32 => uint256) ambushes;

    uint256 public stakedElfCount;
    uint256 public stakedOrcCount;
    
    constructor(address _mana, address _elfOrc,address _vrf, address _link, bytes32 _keyHash, uint256 _fee) VRFConsumerBase(_vrf, _link) {
        keyHash = _keyHash;
        fee = _fee;

        mana = Mana(_mana);
        elfOrc = ElfOrcToken(_elfOrc);
    }

    function stakeElf(uint256 tokenId) public checkIfPaused{
        require(elfOrc.ownerOf(tokenId) == msg.sender, "You must own that elf");
        require(!elfOrc.isOrc(tokenId), "You can only stake elfs here");
        require(elfOrc.isApprovedForAll(msg.sender, address(this)));

        StakingElf memory staking = StakingElf(block.timestamp, msg.sender, 0);
        elfStakings[tokenId] = staking;
        elfStakingsByOwner[msg.sender].push(tokenId);
        numberOfStakedElfs[msg.sender]++;

        elfOrc.transferFrom(msg.sender, address(this), tokenId);

        stakedElfCount++;
    }

    function batchStakeElf(uint256[] memory tokenIds) external checkIfPaused{
        for (uint8 i = 0; i < tokenIds.length; i++) {
            stakeElf(tokenIds[i]);
        }
    }

    function unstakeElf(uint256 tokenId) public {
        require(elfOrc.ownerOf(tokenId) == address(this), "The elf must be staked");
        StakingElf storage staking = elfStakings[tokenId];
        require(staking.owner == msg.sender, "You must own that elf");
        require(!(block.timestamp - staking.timestamp < MINIMUM_TO_UNSTAKE), "You can unstake after 2 days.");
        uint256[] storage stakedElf = elfStakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedElf.length; index++) {
            if (stakedElf[index] == tokenId) {
                break;
            }
        }
        require(index < stakedElf.length, "Elf not found");
        stakedElf[index] = stakedElf[stakedElf.length - 1];
        stakedElf.pop();
        numberOfStakedElfs[msg.sender]--;
        staking.owner = address(0);
        elfOrc.transferFrom(address(this), msg.sender, tokenId);
        stakedElfCount--;
    }

    function batchUnstakeElf(uint256[] memory tokenIds) external {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            unstakeElf(tokenIds[i]);
        }
    }

    function stakeOrc(uint256 tokenId) public checkIfPaused{
        require(elfOrc.ownerOf(tokenId) == msg.sender, "You must own that orc");
        require(elfOrc.isOrc(tokenId), "You can only stake orcs here");
        require(elfOrc.isApprovedForAll(msg.sender, address(this)));

        StakingOrc memory staking = StakingOrc(block.timestamp, msg.sender, manaTaxPerOrc);
        orcStakings[tokenId] = staking;
        orcStakingsByOwner[msg.sender].push(tokenId);
        numberOfStakedOrcs[msg.sender]++;

        elfOrc.transferFrom(msg.sender, address(this), tokenId);

        stakedOrcCount++;
    }

    function batchStakeOrc(uint256[] memory tokenIds) external checkIfPaused{
        for (uint8 i = 0; i < tokenIds.length; i++) {
            stakeOrc(tokenIds[i]);
        }
    }

    function unstakeOrc(uint256 tokenId) public {
        require(elfOrc.ownerOf(tokenId) == address(this), "The orc must be staked");
        StakingOrc storage staking = orcStakings[tokenId];
        require(staking.owner == msg.sender, "You must own that orc");
        uint256[] storage stakedOrc = orcStakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedOrc.length; index++) {
            if (stakedOrc[index] == tokenId) {
                break;
            }
        }
        require(index < stakedOrc.length, "Orc not found");
        stakedOrc[index] = stakedOrc[stakedOrc.length - 1];
        stakedOrc.pop();
        numberOfStakedOrcs[msg.sender]--;
        staking.owner = address(0);
        elfOrc.transferFrom(address(this), msg.sender, tokenId);
        stakedOrcCount--;
    }

    function batchUnstakeOrc(uint256[] memory tokenIds) external {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            unstakeOrc(tokenIds[i]);
        }
    }

    function claimManyRewards(uint16[] calldata tokenIds, bool unstake) external checkIfPaused{
        require(mana.totalSupply() < MAXIMUM_MANA_FOR_MINT, "Mana token supply depleted.");
        require(tx.origin == msg.sender);

        uint256 calculatedRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!checkIfIsOrc(tokenIds[i]))
                calculatedRewards += _claimElfRewards(tokenIds[i], unstake);
            else calculatedRewards += _claimOrcRewards(tokenIds[i], unstake);
        }

        if (calculatedRewards == 0){
            return;
        }

        mana.mint(msg.sender, calculatedRewards);
      
    }

    function calculateReward(StakingElf memory staking) public view returns (uint256) {
        uint256 amount = ((block.timestamp - staking.timestamp) * DAILY_MANA_RATE) / 1 days;

        if(mana.totalSupply() + amount >= MAXIMUM_MANA_FOR_MINT){
            return MAXIMUM_MANA_FOR_MINT - mana.totalSupply();
        }
        else{
            return amount;
        }
    }

    function _claimElfRewards(uint256 tokenId, bool unstake) internal returns (uint256 calculatedRewards) {
        StakingElf storage staking = elfStakings[tokenId];

        require(staking.owner == msg.sender, "You must be the owner of that staked elf.");
        require(!(unstake && block.timestamp - staking.timestamp < MINIMUM_TO_UNSTAKE), "You can unstake after 2 days.");
        require(!(block.timestamp - staking.timestamp < MINIMUM_TO_CLAIM), "You can claim rewards after 1 day.");

        calculatedRewards = calculateReward(staking) - staking.stolen;
        staking.stolen = 0;

        if(block.timestamp - staking.timestamp < TAX_FREE_DAYS){
            payTaxToOrcs((calculatedRewards * MANA_TAX_PERCENTAGE) / 100);
            calculatedRewards = (calculatedRewards * (100 - MANA_TAX_PERCENTAGE)) / 100;
        }
        
        staking.timestamp = block.timestamp;

        if (unstake) {
            unstakeElf(tokenId);
        }
    }

    function _claimOrcRewards(uint256 tokenId, bool unstake) internal returns (uint256 calculatedRewards){
        require(elfOrc.ownerOf(tokenId) == address(this), "The orc must be staked");
        
        StakingOrc storage staking = orcStakings[tokenId];

        require(staking.owner == msg.sender, "You must be the owner of that staked orc.");

        calculatedRewards = (manaTaxPerOrc - staking.tax);
        staking.tax = manaTaxPerOrc;

        if (unstake) {
            unstakeOrc(tokenId);
        }
    }
    
    function payTaxToOrcs(uint256 amount) internal {
        if (stakedOrcCount == 0) {
            unaccountedRewards += amount; 
            return;
        }

        manaTaxPerOrc += (amount + unaccountedRewards) / stakedOrcCount;
        unaccountedRewards = 0;
    }

    function ambushCost(uint256 tokenId) public view returns (uint256) {
        uint256 prevTime = block.timestamp - lastAmbushTime[tokenId];
        uint256 ind = prevTime > 1 days ? 0 : orcAmbushCount[tokenId];
        return ambushPrices[ind];
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        StakingOrc storage ambushingOrc = orcStakings[ambushes[requestId]];

        address orcOwner = ambushingOrc.owner;
        require(orcOwner != address(0));
        
        uint256 tokenIndex;
        uint256 elfId;
        uint256 randNum = randomness;

        do{
            randNum = uint256(keccak256(abi.encode(randNum, 7285)));
            tokenIndex = randNum % elfOrc.balanceOf(address(this));
        }
        while(elfOrc.isOrc(elfOrc.tokenOfOwnerByIndex(address(this), tokenIndex)));

        elfId = elfOrc.tokenOfOwnerByIndex(address(this), tokenIndex);
        StakingElf storage staking = elfStakings[elfId];

        uint256 stealAmount = calculateReward(staking);
        uint256 send = stealAmount - staking.stolen;

        staking.stolen = stealAmount;

        if (send > 0) {
            mana.mint(orcOwner, send);
        }
    }
    
    function startAmbush(uint256 tokenId) public payable checkIfPaused{
        require(msg.value > 0, "You must pay with MATIC");
        require(elfOrc.isOrc(tokenId), "You can only ambush with orcs");
        require(elfOrc.ownerOf(tokenId) == address(this), "The orc must be staked");

        StakingOrc storage staking = orcStakings[tokenId];

        require(staking.owner == msg.sender, "You must own that orc");
        require(orcAmbushCount[tokenId] < 5, "You can ambush a maximum of 5 times per day");

        if (lastAmbushTime[tokenId] == 0) {
            lastAmbushTime[tokenId] = block.timestamp;
        }
        
        uint256 cost = ambushCost(tokenId);

        require(msg.value >= cost, "You must pay the correct amount of MATIC");

        if (block.timestamp - lastAmbushTime[tokenId] > 1 days) {
            lastAmbushTime[tokenId] = block.timestamp;
            orcAmbushCount[tokenId] = 1;
        } else {
            orcAmbushCount[tokenId]++;
        }

        bytes32 requestId = requestRandomness(keyHash, fee);
        ambushes[requestId] = tokenId;
    }

    function stakedOrcTokenOwner(uint256 tokenId) public view returns(address){
        StakingOrc memory staking = orcStakings[tokenId];
        return staking.owner;
    }

    function checkIfIsOrc(uint256 tokenId) public view returns (bool){
        return elfOrc.isOrc(tokenId);
    }

    function allUnstaked(address _owner) external view returns (uint256[] memory) {
        return elfOrc.walletOfOwner(_owner);
    }

    function setMainCollection(address collection) external onlyOwner{
        elfOrc = ElfOrcToken(collection);
    }

    function setRewardCollection(address collection) external onlyOwner{
        mana = Mana(collection);
    }

    function withdraw_MATIC(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function balance_MATIC() external onlyOwner view returns(uint256){
        return address(this).balance;
    }

    function changeDailyManaRate(uint256 amount) external onlyOwner{
        DAILY_MANA_RATE = amount;
    }

    function togglePause() external onlyOwner{
        paused = !paused;
    }

    modifier checkIfPaused() {
        require(!paused, "Contract paused");
        _;
    }
}