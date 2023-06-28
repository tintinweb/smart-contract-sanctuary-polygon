/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract Goose {
    address public fundManager;
    address public investmentWallet ;
    address public marketingWallet;
    uint256 public totalInvested;
    uint256 public totalProfit;
    uint256 public totalProfitAvailableForWithdraw;
    address[] public investors; 
    mapping(address => uint256) public investedAmount;
    mapping(address => uint256) public profitsPaidToInvestor;

    // Some variables
    uint256 private FUNDMANAGER_FEE = 20 ;
    uint256 private REFERRAL_FEE = 2;
    uint256 private MINIMUM_TOTAL_INVESTMENT; // The minimum total investment for a user
    uint256 private START_DATE; 

    // a record for each investment made by the investor
    struct InvestmentHistoryByInvestor {
        address investorWallet;
        uint256 investmentDate;
        uint256 investmentAmount;
    }
    InvestmentHistoryByInvestor[] private investmentHistoryByInvestor;

    // a record for each profit payout made to the investor
    struct ProfitPayoutHistoryByInvestor {
        address investorWallet;
        uint256 payoutDate;
        uint256 payoutAmount;
    }
    ProfitPayoutHistoryByInvestor[] private profitPayoutHistoryByInvestor;

    // a record for each profit earned by the investor (and was stored in the contract)
    struct ProfitEarnedHistoryByInvestor {
        address investorWallet;
        uint256 profitEarnedDate;
        uint256 profitEarnedAmount;
    }
    ProfitEarnedHistoryByInvestor[] private profitEarnedHistoryByInvestor;

    // a record for total profit payout for a date
    struct ProfitPayoutHistory {
        uint256 payoutDate;
        uint256 payoutAmount;
    }
    ProfitPayoutHistory[] private profitPayoutHistory;

    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public profitAvailable;
    mapping(address => bool) public requestedWithdraw;

    mapping(address => address) public referrals;

    modifier onlyInvestment() {
        require(msg.sender == investmentWallet, "Only the team can call this function");
        _;
    }

    
    constructor(address _fundManager, address _marketingWallet){
        fundManager = _fundManager;
        marketingWallet = _marketingWallet;
        investmentWallet = msg.sender;
        
    }
    
    function setReferrer(address referrer) external {
       require(referrals[msg.sender] ==  marketingWallet, "Only allowed if referred is marketing wallet"); 
       require(referrer != msg.sender, "Cannot set own address as referrer"); 
       require(investedAmount[msg.sender] > 0, "User must be invested");
       referrals[msg.sender] = referrer;
    }

    function invest(uint256 amount, address referrer) external payable{
        // require start date to be reached
        // require(block.timestamp >= 1685620800, "Not yet started");

        // make sure they're actually putting in cash dollar
        require(amount > 0, "Invalid investment amount");

        // requires the investor to have a minimum total investment
        require(investedAmount[msg.sender] + amount >= MINIMUM_TOTAL_INVESTMENT, "Minimum total investment not reached");

        // make sure they have not already requested a withdraw
        require(!requestedWithdraw[msg.sender], "Withdraw requested by investor");

        // check if they have invested before
        if (investedAmount[msg.sender] == 0) {
            // if not, add them to the investors array
            investors.push(msg.sender); 

            // if someone self refers, set their referrer to marketingWallet
            if(referrer == msg.sender) {
                referrals[msg.sender] = marketingWallet;
            }

            // set their referrer
            if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
                referrals[msg.sender] = referrer;
            } 
            else {
                referrals[msg.sender] = marketingWallet;
            }
        }

        // set their last investment time to now
        lastInvestmentTime[msg.sender] = block.timestamp;

        // add the investment to the investment history
        investmentHistoryByInvestor.push(InvestmentHistoryByInvestor(msg.sender, block.timestamp, amount));

    

        // add the investment to the total invested for the investor
        investedAmount[msg.sender] += amount;

        // add the investment to the total invested for the platform
        totalInvested += amount;
    }

    function requestWithdrawOfInitialInvestment() external {
        // make sure they have funds invested
        require(investedAmount[msg.sender] > 0, "You have no funds invested");

        // make sure they have not already requested a withdraw
        require(!requestedWithdraw[msg.sender], "Withdraw already requested by investor");

        // reduce the total invested here so that the profit share calculations are correct.
        uint256 capital = investedAmount[msg.sender];

        // reduced the total invested in the platform
        totalInvested -= capital;

        // set the flag to true (so the repayInvestorCapital function will work)
        requestedWithdraw[msg.sender] = true;

        // set the timestamp
        lastInvestmentTime[msg.sender] = block.timestamp;
    }

    function cancelRequestForWithdrawOfInitialInvestment() external {
        // make sure they have funds invested
        require(investedAmount[msg.sender] > 0, "You have no funds invested");

        // make sure they have already requested a withdraw
        require(requestedWithdraw[msg.sender], "Withdraw not requested by investor");

        // set the flag to false (so the repayInvestorCapital function will work)
        requestedWithdraw[msg.sender] = false;

        // add the capital back to the total invested here for the investor
        totalInvested += investedAmount[msg.sender];

        // set the timestamp
        lastInvestmentTime[msg.sender] = block.timestamp;
    }

    function repayInvestorCapital(address investor) external onlyInvestment {
        // check that they have requested a withdraw
        require(requestedWithdraw[investor], "Withdraw not requested");

        // get the capital invested by the investor
        uint256 capital = investedAmount[investor];

      

        // reduce the total invested here for the investor
        investedAmount[investor] = 0;

        // set the capital as not requested (incase they want to invest again)
        requestedWithdraw[investor] = false;

        // send them their cash dollar
        payable(investor).transfer(capital);

    }

    function teamWithdraw() external onlyInvestment {
        // get the balance of the token in the contract
        uint256 contractBalance = address(this).balance;

        // subtract the totalProfitAvailableForWithdraw from the contract balance (so the investors can always withdraw their profit)
        uint256 contractBalanceLessAvailable = contractBalance - totalProfitAvailableForWithdraw;

        // check there is enough to withdraw
        require (contractBalanceLessAvailable > 0, "No funds available for withdraw");

        // transfer the funds to the investment wallet, leaving enough to payout all profits
        payable(investmentWallet).transfer(contractBalanceLessAvailable);
    }


    function withdrawProfit() external {
        require(investedAmount[msg.sender] > 0, "You have no funds invested");
        require(profitAvailable[msg.sender] > 0, "No profit available for withdraw");

        // get the available profit for the investor
        uint256 profit = profitAvailable[msg.sender];

        // set their profit available to 0
        profitAvailable[msg.sender] = 0;
        
        // reduce the total profit available for withdraw for all investors
        totalProfitAvailableForWithdraw -= profit;

        // add the profit to the total profits paid to the investor
        profitsPaidToInvestor[msg.sender] += profit;

        // add the profit to the invested payout struct (for the investor)
        profitPayoutHistoryByInvestor.push(ProfitPayoutHistoryByInvestor(msg.sender, block.timestamp, profit));

        // send the cash dollar to the investor
        payable(msg.sender).transfer(profit);
    }

    

    function compoundProfit() external {
        require(investedAmount[msg.sender] > 0, "You have no funds invested");
        require(profitAvailable[msg.sender] > 0, "No profit available for compound");

        // get the available profit for the investor
        uint256 profit = profitAvailable[msg.sender];

        // set their profit available to 0
        profitAvailable[msg.sender] = 0;
        
        // reduce the total profit available for withdraw for all investors
        totalProfitAvailableForWithdraw -= profit;

        // add the profit to the total profits paid to the investor
        profitsPaidToInvestor[msg.sender] += profit;

        // add the profit to the invested payout struct (for the investor)
        // I'm leaving this in as technically they were paid out and then reinvested
        profitPayoutHistoryByInvestor.push(ProfitPayoutHistoryByInvestor(msg.sender, block.timestamp, profit));

        // set the last investment time to now
        lastInvestmentTime[msg.sender] = block.timestamp;

        // add the profit to the invested amount struct (for the investor)
        investmentHistoryByInvestor.push(InvestmentHistoryByInvestor(msg.sender, block.timestamp, profit));
        
        // add the profit to the total invested for the investor
        investedAmount[msg.sender] += profit;

        // add the profit to the total invested
        totalInvested += profit;
    }

    function getTotalInvested() public view returns (uint256) {
        return totalInvested;
    }

    function getTotalProfit() public view returns (uint256) {
        return totalProfit;
    }

    function getTotalInvestors() public view returns (uint256) {
        return investors.length;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getInvestedAmountByInvestor(address investor) public view returns (uint256) {
        return investedAmount[investor];
    }

    function getProfitsPaidToInvestor(address investor) public view returns (uint256) {
        return profitsPaidToInvestor[investor];
    }

    function getLastInvestedTimeByInvestor(address investor) public view returns (uint256) {
        return lastInvestmentTime[investor];
    }

    function getRequestedWithdrawByInvestor(address investor) public view returns (bool) {
        return requestedWithdraw[investor];
    }

    function getInvestmentHistoryByInvestor() public view returns (InvestmentHistoryByInvestor[] memory) {
        return investmentHistoryByInvestor;
    }

    function getPayoutHistoryByInvestor() public view returns (ProfitPayoutHistoryByInvestor[] memory) {
        return profitPayoutHistoryByInvestor;
    }

    function getProfitEarnedHistoryByInvestor() public view returns (ProfitEarnedHistoryByInvestor[] memory) {
        return profitEarnedHistoryByInvestor;
    }

    function getInvestor(uint256 index) public view returns (address) {
        return investors[index];
    }

    function getProfitAvailable(address invsetor) public  view returns(uint256) {
        return   profitAvailable[invsetor];
    }

    function setinvestmentWallet(address _investmentWallet) external onlyInvestment{
        investmentWallet = _investmentWallet;
    }
    
    function setfundManager(address _fundManager)external onlyInvestment{
        fundManager = _fundManager;
    }
    
    function setmarketingWallet(address _marketingWallet) external onlyInvestment{
        marketingWallet = _marketingWallet;
    }
    
    
     // set MINIMUM_TOTAL_INVESTMENT
    function setMinimumTotalInvestment(uint256 amount) external onlyInvestment {
        MINIMUM_TOTAL_INVESTMENT = amount;
    }
    
    
    function setFUNDMANAGER_FEE(uint256 _fee) external onlyInvestment{
        FUNDMANAGER_FEE = _fee;
    }
    
    function setREFERRAL_FEE(uint256 _fee) external onlyInvestment{
        REFERRAL_FEE = _fee;
    }


    function getWeeklyProfit() external view returns (uint256[] memory) {
        uint256 currentWeek = (block.timestamp - START_DATE) / 604800; // 604800 seconds in a week
        uint256[] memory weeklyProfits = new uint256[](currentWeek + 1);

        for (uint256 i = 0; i <= currentWeek; i++) {
            uint256 startOfWeek = START_DATE + (i * 604800);
            uint256 endOfWeek = startOfWeek + 604800;

            for (uint256 j = 0; j < profitEarnedHistoryByInvestor.length; j++) {
                if (profitEarnedHistoryByInvestor[j].profitEarnedDate >= startOfWeek && profitEarnedHistoryByInvestor[j].profitEarnedDate < endOfWeek) {
                    weeklyProfits[i] += profitEarnedHistoryByInvestor[j].profitEarnedAmount;
                }
            }
        }

        return weeklyProfits;
    }



    // Inject Profit By Investor Amount
    function simulateInjectProfit(uint256 profit) external view returns (address[] memory, uint256[] memory) {
        require(profit > 0, "Invalid profit amount");
        require(investors.length > 0, "No investors");

        uint256[] memory investorProfitForInvestor = new uint256[](investors.length);

        uint256 investorCount = investors.length;
        uint256 investorProfitForAll = profit - (profit * FUNDMANAGER_FEE / 100) - (profit * REFERRAL_FEE / 100);

        for (uint256 i = 0; i < investorCount; i++) {
            if (!requestedWithdraw[msg.sender]) {
                address investor = investors[i];
                uint256 invested = investedAmount[investor];
                uint256 profitForInvestor = (invested * investorProfitForAll) / totalInvested;
                investorProfitForInvestor[i] = profitForInvestor;
            }
        }

        return (investors, investorProfitForInvestor);
    }

    function injectProfit(uint256 profit) external onlyInvestment {
        require(profit > 0, "Invalid profit amount");
        require (investors.length > 0, "No investors");


        // calculate the profit share for the development team and the fund manager
        uint256 fundManagerFee = (profit * FUNDMANAGER_FEE) / 100;

        // calculate the referral amount available
        uint256 referralAmountForAll = (profit * REFERRAL_FEE) / 100;

        // calculate the profit share remaining for the investors
        uint256 investorProfitForAll = profit  - fundManagerFee - referralAmountForAll;

        // add the profit to the total profit
        totalProfit += profit;

        // calculate the profit share for each investor
        for (uint256 i = 0; i < investors.length; i++) {
            if (!requestedWithdraw[msg.sender]) {
                // get the next investor
                address investor = investors[i];

                // get how much he has invested
                uint256 invested = investedAmount[investor];

                // figure out his share of the profits (based on what he has invested vs total invested)
                uint256 investorProfitForInvestor = (invested * investorProfitForAll) / totalInvested;

                // add the profit to the total profits earned by the investor
                profitEarnedHistoryByInvestor.push(ProfitEarnedHistoryByInvestor(investor, block.timestamp, investorProfitForInvestor));

                // set the profitAvailable for the investor (i.e. what he can withdraw)
                profitAvailable[investor] += investorProfitForInvestor;

                // add the profit to the total profit available for withdraw for all investors
                totalProfitAvailableForWithdraw += investorProfitForInvestor;

                // calculate the referralAmount for this investor
                uint256 referralAmount = (invested * referralAmountForAll) / totalInvested;

                // add the referralAmount to the profitAvailable for the referrer
                profitAvailable[referrals[investor]] += referralAmount;

                // add the referralAmount to the total profit available for withdraw for all investors
                totalProfitAvailableForWithdraw += referralAmount;
            }    
        }

        // send the development team and fund manager their share of the profits
        payable(fundManager).transfer(fundManagerFee);

    }    

    function injectProfitForSingleInvestor(address investorAddress, uint256 profit) external onlyInvestment {
        profitEarnedHistoryByInvestor.push(ProfitEarnedHistoryByInvestor(investorAddress, block.timestamp, profit));
        profitAvailable[investorAddress] += profit;
        totalProfitAvailableForWithdraw += profit;
    }


}