// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";

contract FaucetApp is Context, Ownable {
    using SafeMath for uint256;

    uint256 constant public GAS_PER_FAUCET = 2880000; // 6 % a day, i.e. 1/0.06 days = 86400/0.06 = 1440000
    uint256 constant private PSN = 10000;
    uint256 constant private PSNH = 5000;
    uint256 constant public councilFee = 10; // 3% i.e.  (10*3)/10

    mapping (address => uint256) public faucet; // basis for display: 6 decimal places
    mapping (address => uint256) public claimedGas; // basis for display: 6 decimal places
    mapping (address => uint256) public lastConstruct;
    mapping (address => address) public referrals;
    uint256 public marketGas; // basis for display: 6 decimal places

    mapping (address => bool) public whitelisters;

    address payable public treasuryWallet;


    uint256 public whitelistUNIX;
    uint256 public publicUNIX;
    uint256 public nextInterventionUNIX;
    uint256 public interventionStep = 86400; // 1 day
    
    constructor(address _treasuryWallet, uint256 _whitelistUNIX, uint256 _whitelistLength) {
        treasuryWallet = payable(_treasuryWallet);

        
        whitelistUNIX = _whitelistUNIX;
        publicUNIX = SafeMath.add(whitelistUNIX, _whitelistLength);
        nextInterventionUNIX = SafeMath.add(publicUNIX, interventionStep);

        seedWhitelist();
    }
    
    function constructFaucet(address ref) public checkLaunchTime {        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 gasUsed = getMyGas(msg.sender);
        uint256 newFaucet = SafeMath.div(gasUsed,GAS_PER_FAUCET);
        faucet[msg.sender] = SafeMath.add(faucet[msg.sender],newFaucet);
        claimedGas[msg.sender] = 0;
        lastConstruct[msg.sender] = block.timestamp;
        
        //send referral gas
        claimedGas[referrals[msg.sender]] = SafeMath.add(claimedGas[referrals[msg.sender]],SafeMath.div(gasUsed,20));
        
        //boost market to nerf miners hoarding
        marketGas=SafeMath.add(marketGas, gasUsed.mul(15).div(100));
    }
    
    function sellGas() public checkLaunchTime {
        uint256 hasGas = getMyGas(msg.sender);
        uint256 gasValue = calculateGasSell(hasGas);
        uint256 fee = getCouncilFee(gasValue);
        claimedGas[msg.sender] = 0;
        lastConstruct[msg.sender] = block.timestamp;
        marketGas = SafeMath.add(marketGas,hasGas);

        treasuryWallet.transfer(fee.mul(3).div(10));

        
        payable (msg.sender).transfer(SafeMath.sub(gasValue,fee));
    }
    
    function buyGas(address ref) public payable checkLaunchTime {
        uint256 gasBought = calculateGasBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        gasBought = SafeMath.sub(gasBought,getCouncilFee(gasBought));
        uint256 fee = getCouncilFee(msg.value);
        
        treasuryWallet.transfer(fee.mul(3).div(10));

        
        claimedGas[msg.sender] = SafeMath.add(claimedGas[msg.sender],gasBought).mul(getProgressiveMultiplier()).div(10000);
        constructFaucet(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateGasSell(uint256 gas) public view returns(uint256) {
        return calculateTrade(gas,marketGas,address(this).balance);
    }
    
    function calculateGasBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketGas);
    }
    
    function calculateGasBuySimple(uint256 eth) public view returns(uint256) {
        return calculateGasBuy(eth,address(this).balance);
    }
    
    function getCouncilFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,councilFee),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketGas == 0, "Bad init: already initialized");
        require(msg.value == 1 ether, "Bad init: amount of MATIC");
        marketGas = GAS_PER_FAUCET.mul(100000);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyFaucet(address adr) public view returns(uint256) {
        return faucet[adr];
    }
    
    function getMyGas(address adr) public view returns(uint256) {
        return SafeMath.add(claimedGas[adr],getGasSinceLastConstruct(adr));
    }
    
    function getGasSinceLastConstruct(address adr) public view returns(uint256) {
        uint256 secondsPassed=SafeMath.sub(block.timestamp,lastConstruct[adr]);
        return SafeMath.mul(secondsPassed,faucet[adr]);
    }


    modifier checkLaunchTime() {
        require(block.timestamp >= whitelistUNIX, "Protocol not launched yet!");
        if(block.timestamp < publicUNIX) {
            require(whitelisters[msg.sender], "Wallet not whitelisted for early launch!");
        }
        _;
    }

    function getProgressiveMultiplier() public view returns(uint256) {
        uint256 x = block.timestamp;
        if(x <= publicUNIX) {
            return 10000;
        }
        x = x.sub(publicUNIX).mul(10000).div(6); // should be +1/6% after first month to become 7%
        return x.div(30).div(86400).add(10000);
    }

    function councilIntervention(uint256 interventionType) public onlyOwner {
        require(block.timestamp >= nextInterventionUNIX, "Cannot intervene yet!");
        require(interventionType <= 3, "Unrecognized type of intervention.");
        nextInterventionUNIX = SafeMath.add(block.timestamp, interventionStep);

        // interventionType == 0: waive (in balanced market)
        if(interventionType == 1) { // boost for new entrants (in recessionary market)
            marketGas = marketGas.mul(11).div(10);
        }
        if(interventionType == 2) { // burn (in very expansionary market)
            marketGas = marketGas.mul(9).div(10);
        }
        if(interventionType == 3) { // burn (in very expansionary market)
            marketGas = marketGas.mul(8).div(10);
        }
    }

    function whitelistAdd(address adr) public onlyOwner {
        whitelisters[adr] = true;
    }

    function whitelistRemove(address adr) public onlyOwner {
        whitelisters[adr] = false;
    }

    function seedWhitelist() internal {
        whitelistAdd(address(0x513CDC7297659e71845F76E7119566A957767c8F));
        
    }
}