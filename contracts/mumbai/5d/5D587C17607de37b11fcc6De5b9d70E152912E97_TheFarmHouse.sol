// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TheFarmHouse is Context, Ownable {

    uint256 private SEEDS_TO_PLANT_1MINERS = 1080000; //for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 2;
    bool private initialized = false;
    address payable private recAddr;
    mapping(address => uint256) private seedMiners;
    mapping(address => uint256) private claimedSeeds;
    mapping(address => uint256) private lastPlanted;
    mapping(address => address) private referrals;
    mapping(uint256 => ReferralData) public referralsData;
    mapping(address => uint256) public refIndex;
    mapping(address => uint256) public refferalsAmountData;
    uint256 public totalRefferalCount;
    uint256 private marketSeeds;

    struct ReferralData {
        address refAddress;
        uint256 amount;
        uint256 refCount;
    }

    constructor() {
        recAddr = payable(msg.sender); //_benificiaryAddress;
    }

    function replantSeeds(address ref) public {
        require(initialized);

        if (ref == msg.sender) {
            ref = address(0);
        }

        if (
            referrals[msg.sender] == address(0) &&
            referrals[msg.sender] != msg.sender
        ) {
            referrals[msg.sender] = ref;
        }

        uint256 seedsUsed = getMySeeds(msg.sender);
        uint256 newMiners = seedsUsed / SEEDS_TO_PLANT_1MINERS;
        seedMiners[msg.sender] += newMiners;
        claimedSeeds[msg.sender] = 0;
        lastPlanted[msg.sender] = block.timestamp;

        //send referral seeds
        claimedSeeds[referrals[msg.sender]] += (seedsUsed * 100000000) / 740740741;

        if (
            referrals[msg.sender] != address(0) &&
            refferalsAmountData[referrals[msg.sender]] == 0
        ) {
            totalRefferalCount++;
            refIndex[referrals[msg.sender]] = totalRefferalCount;
        }
        if (referrals[msg.sender] != address(0)) {
            uint256 currentIndex = refIndex[referrals[msg.sender]];
            refferalsAmountData[referrals[msg.sender]] += claimedSeeds[referrals[msg.sender]];
            referralsData[currentIndex] = ReferralData({
                refAddress: referrals[msg.sender],
                amount: referralsData[currentIndex].amount + (seedsUsed * 100000000) / 740740741,
                refCount: referralsData[currentIndex].refCount + 1
            });
        }
        //boost market to nerf miners hoarding
        marketSeeds += seedsUsed / 5;
    }

    function harvestSeeds() public {
        require(initialized);
        uint256 hasSeeds = getMySeeds(msg.sender);
        uint256 seedValue = calculateSeedSell(hasSeeds);
        uint256 fee = devFee(seedValue);
        claimedSeeds[msg.sender] = 0;
        lastPlanted[msg.sender] = block.timestamp;
        marketSeeds = marketSeeds + hasSeeds;
        recAddr.transfer(fee);
        payable(msg.sender).transfer(seedValue - fee);
    }

    function seedRewards(address adr) public view returns (uint256) {
        uint256 hasSeeds = getMySeeds(adr);
        uint256 seedValue = calculateSeedSell(hasSeeds);
        return seedValue;
    }

    function plantSeeds(address ref) public payable {
        require(initialized);
        uint256 seedsBought = calculateSeedBuy(
            msg.value,
            address(this).balance - msg.value
        );
        seedsBought = seedsBought - devFee(seedsBought);
        uint256 fee = devFee(msg.value);
        recAddr.transfer(fee);
        claimedSeeds[msg.sender] += seedsBought;
        replantSeeds(ref);
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        return (PSN * bs) / (PSNH + ((PSN * rs) + (PSNH * rt)) / rt);
    }

    function calculateSeedSell(uint256 seeds) public view returns (uint256) {
        return calculateTrade(seeds, marketSeeds, address(this).balance);
    }

    function calculateSeedBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketSeeds);
    }

    function calculateSeedBuySimple(uint256 eth) public view returns (uint256) {
        return calculateSeedBuy(eth, address(this).balance);
    }

    function devFee(uint256 amount) private view returns (uint256) {
        return amount * devFeeVal / 100;
    }

    function seedMarket() public payable onlyOwner {
        require(marketSeeds == 0);
        initialized = true;
        marketSeeds = 108000000000;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners(address adr) public view returns (uint256) {
        return seedMiners[adr];
    }

    function getMySeeds(address adr) public view returns (uint256) {
        return claimedSeeds[adr] + getSeedsSincelastPlanted(adr);
    }

    function getSeedsSincelastPlanted(address adr)
        public
        view
        returns (uint256)
    {
        uint256 secondsPassed = min(
            SEEDS_TO_PLANT_1MINERS,
            block.timestamp - lastPlanted[adr]);

        return secondsPassed * seedMiners[adr];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function reset() external onlyOwner {
        initialized = false;
        payable(msg.sender).transfer(address(this).balance);
    }
}