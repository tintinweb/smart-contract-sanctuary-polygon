//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;


import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract AaveLendingContract is Ownable {

    using SafeMath for uint256;

    address private aaveProviderAddress = 0x7551b5D2763519d4e37e8B81929D336De671d46d;
    address private aaveLendingContractAddress = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address private masterWallet;
    address private myContractAddress;
    uint256 private feePercentage;
    address[] public investorslist;
    uint256 totalInvestors;

    struct userInvestment{
        address walletAddress;
        address assetAddress;
        uint256 totalInvestment;
        uint256 numberOfDeposits;
        uint256 lastUpdateDateInSecond;
        uint256 lastClaimedDateInSecond;
        uint256 lastWithdrawlDateInSecond;
        uint256 acclaimedProfit;
        bool isAuto;
    }

    event confirmWithdraw (address to, uint256 amount);
    event chkWithdraw(uint256 amount);
    event claimedRewards(uint256 rewards);
    event userReward(address user, uint256 share);

    mapping (bytes32 => userInvestment) public userInvestments;

    mapping (address => bool) private investors;

    mapping (address => uint256) private investmentsbyAssets;
    
    constructor(address masterWalletAddress, uint256 fee){
        myContractAddress = address(this);
        masterWallet = masterWalletAddress;
        feePercentage = fee;
    }

    function updateFeePercent  (uint256 fee) external onlyOwner{
        if(fee < 0 || fee > 20){
            revert("fee must be between 0 to 20");
        }

        feePercentage = fee;
    }

    function getPrivateUniqueKey(address assetAddress, address walletAddress) private pure returns (bytes32){
        
        return keccak256(abi.encodePacked(assetAddress, walletAddress));
    }

    function getInvestment(address assetAddress, address walletAddress) public view returns (userInvestment memory){
        
        return userInvestments[getPrivateUniqueKey(assetAddress, walletAddress)];
    }

    function saveInvestment(userInvestment memory investment) private returns (userInvestment memory){

        userInvestments[getPrivateUniqueKey(investment.assetAddress, investment.walletAddress)] = investment;

        return investment;
    }

    function depositToPool(userInvestment memory investment, uint256 amount) private {
        // userInvestment memory investment = getInvestment(assetAddress, addressFrom);
      
        giveApprovalForLending(investment.assetAddress, amount);
        depositFromLending(investment.assetAddress, amount);
        investment.totalInvestment = investment.totalInvestment + amount;
        investment.numberOfDeposits++;
        investment.lastUpdateDateInSecond = getDateTimeNowInSeconds();

        saveInvestment(investment);
        uint256 total = investmentsbyAssets[investment.assetAddress].add(amount);
        investmentsbyAssets[investment.assetAddress]= total;
    }

    function deposit(address assetAddress, uint256 amount, bool isauto) external {
       
        userInvestment memory investment = getInvestment(assetAddress, msg.sender);
      
        transferAssetToContract(assetAddress, amount, msg.sender);
        investment.isAuto=isauto;
        investment.walletAddress = msg.sender;
        investment.assetAddress=assetAddress;
        saveInvestment(investment);
        depositToPool(investment,amount);
        
        //saveInvestment(investment);
        //investmentsbyAssets[assetAddress]= investmentsbyAssets[assetAddress].add(amount);
        if(!investors[msg.sender])
        {
            investors[msg.sender]=true;
            investorslist.push(msg.sender);
            totalInvestors++;
        }     
    }

    function claim(address assetAddress) external {

        userInvestment memory investment = getInvestment(assetAddress, msg.sender);
        uint256 totalAtokenInvestment = investmentsbyAssets[assetAddress];

        if(investment.totalInvestment <= 0){
            revert("Your amount is less than or equal to Zero!");
        }

        
        // if(investment.acclaimedProfit > 0)
        // {
        //     transferMoney(assetAddress, msg.sender, investment.acclaimedProfit);
        //     investment.acclaimedProfit=0;
        //     saveInvestment(investment);
        // }

        if(getDateTimeNowInSeconds().sub(investment.lastUpdateDateInSecond) < 300)// 24 hr _ 86400
        { 
             revert("Investment time is minimum 24hr!");
        }

        uint256 balanceAtoken = getATokenBalance(assetAddress);
        uint256 amountDifference = balanceAtoken.sub(totalAtokenInvestment);
        uint256 rewards= withdrawFromLending(assetAddress, amountDifference);
        emit claimedRewards(rewards);

        //uint256 clientsShare = amountDifference-masterWalletAmount;
        
        
        for(uint16 i = 0; i < investorslist.length; i ++)
        {
            address user = investorslist[i];
            userInvestment memory userDetails = getInvestment(assetAddress, user);
            uint256 userPercent = (userDetails.totalInvestment.mul(100)).div(totalAtokenInvestment);
            uint256 userShare = (rewards.mul(userPercent)).div(100);
            uint256 masterWalletAmount = (userShare.mul(feePercentage)).div(100);
            // To master
            transferMoney(assetAddress, masterWallet, masterWalletAmount);

            emit userReward(user, userShare);
            userDetails.lastClaimedDateInSecond=  getDateTimeNowInSeconds();
            if(!userDetails.isAuto)
            {
                transferMoney(assetAddress, user, userShare);         
            }
            else
            {
                depositToPool(userDetails, userShare);
            }
            saveInvestment(userDetails);

           // transferMoney(assetAddress, user, userShare);
        }
       
        /*
        if(withdrawFromLending(assetAddress, balanceAtoken) > 0){ 

            // To master
            transferMoney(assetAddress, masterWallet, masterWalletAmount);
    
            // To client
            transferMoney(assetAddress, toAddress, balanceAtoken.sub(masterWalletAmount));

            investment.totalInvestment = 0;
            investment.lastClaimedDateInSecond = getDateTimeNowInSeconds();

            saveInvestment(investment, msg.sender);
        } 
        else{
            revert("Withdraw failed!");
        }*/
    }
     function getassetValue (address assetAddress) public view returns (uint256 volume) {
            return investmentsbyAssets[assetAddress];
    }
    function withdraw (address assetaddress, uint256 amount) public {
        userInvestment memory investment = getInvestment(assetaddress, msg.sender);

        if(!investors[msg.sender]){
            revert("Doesn't exist");
        }
        if(investment.totalInvestment< amount)
        {
            revert ("Requested amount is more than invested amount");
        }

        uint256 wamount = withdrawFromLending(assetaddress, amount);
        emit chkWithdraw(wamount);
        if(wamount > 0){ 

            // To client
            transferMoney(assetaddress, msg.sender, wamount);
            investmentsbyAssets[investment.assetAddress]= investmentsbyAssets[investment.assetAddress].sub(wamount);
            investment.totalInvestment =investment.totalInvestment.sub(wamount);
            investment.lastWithdrawlDateInSecond = getDateTimeNowInSeconds();
            saveInvestment(investment);
            emit confirmWithdraw(msg.sender, wamount);
        } 
        else{
            revert("Withdraw failed!");
        }
    }


    function transferAssetToContract(address assetAddress, uint256 amount, address senderAddress) private {
        
        IERC20(assetAddress).transferFrom(senderAddress, myContractAddress, amount);
    }

    function giveApprovalForLending(address assetAddress, uint256 amount) private {

        IERC20(assetAddress).approve(aaveLendingContractAddress, amount); 
    }

    function depositFromLending(address assetAddress, uint256 amount) private {

        IERC20(aaveLendingContractAddress).deposit(assetAddress, amount, myContractAddress, 0);    
    }

    function withdrawFromLending(address assetAddress, uint256 amount) private returns (uint256){

        return IERC20(aaveLendingContractAddress).withdraw(assetAddress, amount, myContractAddress);    
    }   

    function transferMoney(address assetAddress, address toAddress, uint256 amount) private {        
        
        IERC20(assetAddress).transfer(toAddress, amount);
    }

    function getDateTimeNowInSeconds() private view returns (uint256){

        return block.timestamp;
    }

    function getATokenBalance(address assetAddress) public view returns(uint256){
        (address aTokenAddress,,) = IERC20(aaveProviderAddress).getReserveTokensAddresses(assetAddress);
        
        return IERC20(aTokenAddress).balanceOf(myContractAddress);
    }

    function getBalance(address assetAddress) external view returns(uint256){      
        return IERC20(assetAddress).balanceOf(myContractAddress);
    }

}