/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

// SPDX-License-Identifier: MIT

/**                                                                                                                                    
    https://wagmatic.io/                    
*/

pragma solidity 0.8.9;

contract wagmatic {

    // 12.5 days for miners to double
    // after this period, rewards do NOT accumulate anymore though!
    uint256 private constant WAG_REQ_PER_MINER = 1_080_000; 
    uint256 private constant INITIAL_MARKET_WAGS = 108_000_000_000;
    uint256 public constant START_TIME = 1631186800;
    uint256 public constant MIN_DEPOST_AMOUNT = 1 ether;
    
    uint256 private constant PSN = 10000;
    uint256 private constant PSNH = 5000;

    uint256 private getDevFeeVal = 50;
    uint256 private getMarketingFeeVal = 450;

    uint256 private marketWags = INITIAL_MARKET_WAGS;

    uint256 public uniqueUsers;

    address payable private devFeeReceiver;
    address payable immutable private marketingFeeReceiver;

    mapping (address => uint256) private academyMiners;
    mapping (address => uint256) private claimedWags;
    mapping (address => uint256) private lastInfusion;
    mapping (address => bool) private hasParticipated;

    mapping (address => address) private referrals;
    mapping (address => bool) private managers;

    error OnlyManager(address);
    error NonZeroMarketWags(uint);
    error FeeTooLow();
    error NotStarted(uint);

    modifier hasStarted() {
        if(block.timestamp < START_TIME) revert NotStarted(block.timestamp);
        _;
    }
    
    ///@dev infuse some intitial native coin deposit here
    constructor(address _devFeeReceiver, address _marketingFeeReceiver) payable {
        devFeeReceiver = payable(_devFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);

        managers[msg.sender] = true;
        managers[_devFeeReceiver] = true;
        managers[_marketingFeeReceiver] = true;
    }

    function addManager(address _address) external {
        if(managers[msg.sender] != true) revert OnlyManager(msg.sender);
        managers[_address] = true;
    }

    function changeDevFeeReceiver(address newReceiver) external {
        if(managers[msg.sender] != true) revert OnlyManager(msg.sender);
        devFeeReceiver = payable(newReceiver);
    }

    function changeDevFee(uint256 feeVal) external {
        if(managers[msg.sender] != true) revert OnlyManager(msg.sender);
        getDevFeeVal = feeVal;
    }

    ///@dev should market wags be 0 we can resest to initial state and also (re-)fund the contract again if needed
    function init() external payable {
        if(managers[msg.sender] != true) revert OnlyManager(msg.sender);
        if(marketWags > 0 ) revert NonZeroMarketWags(marketWags);
    }

    function fund() external payable {
        if(managers[msg.sender] != true) revert OnlyManager(msg.sender);
    }

    // buy token from the contract
    function absolve(address ref) public payable hasStarted {
        require(msg.value >= MIN_DEPOST_AMOUNT, "Too small amount");

        uint256 wagsBought = calculateWagBuy(msg.value, address(this).balance - msg.value);

        uint256 marketingFee = getMarketingFee(wagsBought);
        if(marketingFee == 0) revert FeeTooLow();
        wagsBought = wagsBought - marketingFee;

        devFeeReceiver.transfer(getDevFee(msg.value));
        marketingFeeReceiver.transfer(getMarketingFee(msg.value));

        claimedWags[msg.sender] += wagsBought;

        if(!hasParticipated[msg.sender]) {
            hasParticipated[msg.sender] = true;
            uniqueUsers++;
        }

        infuse(ref);
    }
    
    ///@dev handles referrals
    function infuse(address ref) public hasStarted {
        
        if(ref == msg.sender) ref = address(0);
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
            if(!hasParticipated[ref]) {
                hasParticipated[ref] = true;
                uniqueUsers++;
            }
        }
        
        uint256 wagsUsed = getMyWags(msg.sender);
        uint256 myWagRewards = getWagsSinceLastInfusion(msg.sender);
        claimedWags[msg.sender] += myWagRewards;

        uint256 newMiners = claimedWags[msg.sender] / WAG_REQ_PER_MINER;
        claimedWags[msg.sender] -= (WAG_REQ_PER_MINER * newMiners);
        academyMiners[msg.sender] += newMiners;
        lastInfusion[msg.sender] = block.timestamp;
        
        // send referral wags
        claimedWags[referrals[msg.sender]] += (wagsUsed / 8);
        
        // boost market to nerf miners hoarding
        marketWags += (wagsUsed / 5);
    }
    
    // sells token to the contract
    function enlighten() external hasStarted {

        uint256 ownedWags = getMyWags(msg.sender);
        uint256 wagValue = calculateWagSell(ownedWags);

        uint256 devFee = getDevFee(wagValue);
        uint256 marketingFee = getMarketingFee(wagValue);

        if(academyMiners[msg.sender] == 0) uniqueUsers--;
        claimedWags[msg.sender] = 0;
        lastInfusion[msg.sender] = block.timestamp;
        marketWags += ownedWags;

        devFeeReceiver.transfer(devFee);
        marketingFeeReceiver.transfer(marketingFee);

        payable (msg.sender).transfer(wagValue - devFee - marketingFee);
    }

    // ################################## view functions ########################################

    function wagRewards(address adr) external view returns(uint256) {
        return calculateWagSell(getMyWags(adr));
    }
    
    function calculateWagSell(uint256 wags) public view returns(uint256) {
        return calculateTrade(wags, marketWags, address(this).balance);
    }
    
    function calculateWagBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketWags);
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function getMyMiners() external view returns(uint256) {
        return academyMiners[msg.sender];
    }
    
    function getMyWags(address adr) public view returns(uint256) {
        return claimedWags[adr] + getWagsSinceLastInfusion(adr);
    }
    
    function getWagsSinceLastInfusion(address adr) public view returns(uint256) {
        // 1 wag per second per miner
        return min(WAG_REQ_PER_MINER, block.timestamp - lastInfusion[adr]) * academyMiners[adr];
    }

    // private ones

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private pure returns(uint256) {
        return (PSN * bs) / (PSNH + (((rs * PSN) + (rt * PSNH)) / rt));
    }

    function getDevFee(uint256 amount) private view returns(uint256) {
        return amount * getDevFeeVal / 10000;
    }
    
    function getMarketingFee(uint256 amount) private view returns(uint256) {
        return amount * getMarketingFeeVal / 10000;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}