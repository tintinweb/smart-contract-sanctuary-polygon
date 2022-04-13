/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

/**
 *Submitted for verification at cronoscan.com on 2022-04-11
*/

// SPDX-License-Identifier: MIT

/**                                                                                                                                    
   _______     _______    ____________   _____  ______      _____       ___________      ____________ _____         ______   _____  
  /      /|   |\      \  /            \ /    / /     /|   /      |_     \          \     \           |\    \       |\     \ |     | 
 /      / |   | \      \|\___/\  \\___/|     |/     / |  /         \     \    /\    \     \           \\    \      \ \     \|     | 
|      /  |___|  \      |\|____\  \___||\____\\    / /  |     /\    \     |   \_\    |     |    /\     \\    \      \ \           | 
|      |  |   |  |      |      |  |     \|___|/   / /   |    |  |    \    |      ___/      |   |  |    |\|    | _____\ \____      | 
|       \ \   / /       | __  /   / __     /     /_/____|     \/      \   |      \  ____   |    \/     | |    |/      \|___/     /| 
|      |\\/   \//|      |/  \/   /_/  |   /     /\      |\      /\     \ /     /\ \/    \ /           /| /            |   /     / | 
|\_____\|\_____/|/_____/|____________/|  /_____/ /_____/| \_____\ \_____/_____/ |\______|/___________/ |/_____/\_____/|  /_____/  / 
| |     | |   | |     | |           | /  |    |/|     | | |     | |     |     | | |     |           | /|      | |    ||  |     | /  
 \|_____|\|___|/|_____|/|___________|/   |____| |_____|/ \|_____|\|_____|_____|/ \|_____|___________|/ |______|/|____|/  |_____|/   

    https://wizardly.finance/                    

*/

// Made with love by Tennogi of https://kittyfinance.io <3

pragma solidity 0.8.12;

contract Frenchy {

    // 12.5 days for miners to double
    // after this period, rewards do NOT accumulate anymore though!
    uint256 private constant FRY_REQ_PER_MINER = 1_080_000; 
    uint256 private constant INITIAL_MARKET_FRIES = 108_000_000_000;
    uint256 public constant START_TIME = 1649689200;
    
    uint256 private constant PSN = 10000;
    uint256 private constant PSNH = 5000;

    uint256 private constant getDevFeeVal = 100;
    uint256 private constant getMarketingFeeVal = 100;

    uint256 private marketFries = INITIAL_MARKET_FRIES;

    uint256 public uniqueUsers;

    address public immutable owner;
    address payable private devFeeReceiver;
    address payable immutable private marketingFeeReceiver;

    mapping (address => uint256) private miners;
    mapping (address => uint256) private claimedFries;
    mapping (address => uint256) private lastFried;
    mapping (address => bool) private hasParticipated;

    mapping (address => address) private referrals;

    error OnlyOwner(address);
    error NonZeromarketFries(uint);
    error FeeTooLow();
    error NotStarted(uint);

    event FriesBought(address indexed user, uint256 amount, uint256 friesBought);
    event FriesSold(address indexed user, uint256 owned, uint256 friesValue);

    modifier hasStarted() {
        if(block.timestamp < START_TIME) revert NotStarted(block.timestamp);
        _;
    }
    
    ///@dev infuse some intitial native coin deposit here
    constructor(address _devFeeReceiver, address _marketingFeeReceiver) payable {
        owner = msg.sender;
        devFeeReceiver = payable(_devFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function changeDevFeeReceiver(address newReceiver) external {
        if(msg.sender != owner) revert OnlyOwner(msg.sender);
        devFeeReceiver = payable(newReceiver);
    }

    ///@dev should market fries be 0 we can resest to initial state and also (re-)fund the contract again if needed
    function init() external payable {
        if(msg.sender != owner) revert OnlyOwner(msg.sender);
        if(marketFries > 0 ) revert NonZeromarketFries(marketFries);
    }

    function fund() external payable {
        if(msg.sender != owner) revert OnlyOwner(msg.sender);
    }

    // buy token from the contract
    function buyFries(address ref) public payable hasStarted {
       
        uint256 friesBought = calculateFryBuy(msg.value, address(this).balance - msg.value);

        uint256 devFee = getDevFee(friesBought);
        uint256 marketingFee = getMarketingFee(friesBought);

        if(marketingFee == 0) revert FeeTooLow();

        friesBought = friesBought - devFee - marketingFee;

        devFeeReceiver.transfer(getDevFee(msg.value));
        marketingFeeReceiver.transfer(getMarketingFee(msg.value));

        claimedFries[msg.sender] += friesBought;

        if(!hasParticipated[msg.sender]) {
            hasParticipated[msg.sender] = true;
            uniqueUsers++;
        }

        emit FriesBought(msg.sender, msg.value, friesBought);
        
        reFry(ref);
    }
    
    ///Handles referrals
    function reFry(address ref) public hasStarted {
      
        if(ref == msg.sender) ref = address(0);
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
            if(!hasParticipated[ref]) {
                hasParticipated[ref] = true;
                uniqueUsers++;
            }
        }
        
        uint256 friesUsed = getMyFries(ref);
        uint256 myFryRewards = getFrysSinceLastHatch(ref);
        claimedFries[msg.sender] += myFryRewards;

        uint256 newMiners = claimedFries[msg.sender] / FRY_REQ_PER_MINER;
        claimedFries[msg.sender] -= (FRY_REQ_PER_MINER * newMiners);
        miners[msg.sender] += newMiners;
        lastFried[msg.sender] = block.timestamp;
        
        // send referral fries
        claimedFries[referrals[msg.sender]] += (friesUsed / 8);
        
        // boost market to nerf miners hoarding
        marketFries += (friesUsed / 5);
    }
    
    // sells token to the contract
    function sellFries() external hasStarted {

        uint256 ownedFries = getMyFries(msg.sender);
        uint256 friesValue = calculateFrySell(ownedFries);

        uint256 devFee = getDevFee(friesValue);
        uint256 marketingFee = getMarketingFee(friesValue);

        if(miners[msg.sender] == 0) uniqueUsers--;
        claimedFries[msg.sender] = 0;
        lastFried[msg.sender] = block.timestamp;
        marketFries += ownedFries;

        devFeeReceiver.transfer(devFee);
        marketingFeeReceiver.transfer(marketingFee);

        emit FriesSold(msg.sender, ownedFries, friesValue);

        payable (msg.sender).transfer(friesValue - devFee - marketingFee);
    }

    // ################################## view functions ########################################

    function friesRewards(address adr) external view returns(uint256) {
        return calculateFrySell(getMyFries(adr));
    }
    
    function calculateFrySell(uint256 fries) public view returns(uint256) {
        return calculateTrade(fries, marketFries, address(this).balance);
    }
    
    function calculateFryBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketFries);
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function getMyMiners() external view returns(uint256) {
        return miners[msg.sender];
    }
    
    function getMyFries(address adr) public view returns(uint256) {
      
        return claimedFries[adr] + getFrysSinceLastHatch(adr);
    }
    
    function getFrysSinceLastHatch(address adr) public view returns(uint256) {
        // 1 fry per second per miner
        return min(FRY_REQ_PER_MINER, block.timestamp - lastFried[adr]) * miners[adr];
    }

    // private ones

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private pure returns(uint256) {
        return (PSN * bs) / (PSNH + (((rs * PSN) + (rt * PSNH)) / rt));
    }

    function getDevFee(uint256 amount) private pure returns(uint256) {
        return amount * getDevFeeVal / 10000;
    }
    
    function getMarketingFee(uint256 amount) private pure returns(uint256) {
        return amount * getMarketingFeeVal / 10000;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}