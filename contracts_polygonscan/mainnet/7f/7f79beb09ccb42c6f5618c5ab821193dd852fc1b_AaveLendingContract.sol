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

    function depositToPool(userInvestment memory investment, uint256 amount) private 
    {
        // userInvestment memory investment = getInvestment(assetAddress, addressFrom);
      
        giveApprovalForLending(investment.assetAddress, amount);
        depositFromLending(investment.assetAddress, amount);

        investment.totalInvestment = investment.totalInvestment + amount;
        investment.numberOfDeposits++;
        investment.lastUpdateDateInSecond = getDateTimeNowInSeconds();

        saveInvestment(investment);
        investmentsbyAssets[investment.assetAddress]= investmentsbyAssets[investment.assetAddress].add(amount);
    }

    function deposit(address assetAddress, uint256 amount, bool isauto) external {
       
        userInvestment memory investment = getInvestment(assetAddress, msg.sender);
      
        transferAssetToContract(assetAddress, amount, msg.sender);
        investment.isAuto=isauto;
        investment.walletAddress = msg.sender;

        depositToPool(investment,amount);
        
        saveInvestment(investment);
        investmentsbyAssets[assetAddress]= investmentsbyAssets[assetAddress].add(amount);
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

        if(getDateTimeNowInSeconds().sub(investment.lastClaimedDateInSecond) < 120)// 24 hr _ 86400
        {
            if(investment.acclaimedProfit > 0)
            {
                transferMoney(assetAddress, msg.sender, investment.acclaimedProfit);
                investment.acclaimedProfit=0;
                saveInvestment(investment);
            }
             revert("Investment time is minimum 24hr!, Your existing rewards have been transfered to your wallet");
        }

        uint256 balanceAtoken = getATokenBalance(assetAddress);

        uint256 amountDifference = balanceAtoken.sub(totalAtokenInvestment);

        uint256 masterWalletAmount = (amountDifference.mul(feePercentage)).div(100);
        
        // To master
        transferMoney(assetAddress, masterWallet, masterWalletAmount);

        uint256 clientsShare = amountDifference-masterWalletAmount;
        
        for(uint16 i = 0; i < investorslist.length; i ++)
        {
            address user = investorslist[i];
            userInvestment memory userDetails = getInvestment(assetAddress, user);
            uint256 userPercent = (userDetails.totalInvestment.mul(100)).div(totalAtokenInvestment);
            uint256 userShare = (clientsShare.mul(userPercent)).div(100);
            userDetails.lastClaimedDateInSecond=  getDateTimeNowInSeconds();
            if(!userDetails.isAuto)
            {
                userDetails.acclaimedProfit+=userShare;
                saveInvestment(userDetails);
            }
            else
            {
                depositToPool(userDetails, userShare);
            }

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

    function withdraw (address assetaddress) public {
        userInvestment memory investment = getInvestment(assetaddress, msg.sender);

        if(!investors[msg.sender]){
            revert("Doesn't exist");
        }

        if(withdrawFromLending(assetaddress, investment.totalInvestment) > 0){ 

            // To client
            transferMoney(assetaddress, msg.sender, investment.totalInvestment);

            investment.totalInvestment = 0;
            investment.lastWithdrawlDateInSecond = getDateTimeNowInSeconds();
            saveInvestment(investment);
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