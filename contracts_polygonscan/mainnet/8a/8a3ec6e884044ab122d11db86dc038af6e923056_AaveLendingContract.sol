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

    struct userInvestment{
        address assetAddress;
        uint256 totalInvestment;
        uint256 numberOfDeposits;
        uint256 lastUpdateDateInSecond;
        uint256 lastClaimedDateInSecond;
    }

    mapping (bytes32 => userInvestment) public userInvestments;
    
    constructor(address masterWalletAddress, uint256 fee){
        myContractAddress = address(this);
        masterWallet = masterWalletAddress;
        feePercentage = fee;
    }

    function getPrivateUniqueKey(address assetAddress) private pure returns (bytes32){
        
        return keccak256(abi.encodePacked(assetAddress));
    }

    function getInvestment(address assetAddress) public view returns (userInvestment memory){
        
        return userInvestments[getPrivateUniqueKey(assetAddress)];
    }

    function saveInvestment(userInvestment memory investment) private returns (userInvestment memory){

        userInvestments[getPrivateUniqueKey(investment.assetAddress)] = investment;

        return investment;
    }

    function deposit(address assetAddress, uint256 amount) external onlyOwner{
       
        userInvestment memory investment = getInvestment(assetAddress);
      
        transferAssetToContract(assetAddress, amount, msg.sender);
        giveApprovalForLending(assetAddress, amount);
        depositFromLending(assetAddress, amount);

        investment.assetAddress = assetAddress;
        investment.totalInvestment = investment.totalInvestment + amount;
        investment.numberOfDeposits++;
        investment.lastUpdateDateInSecond = getDateTimeNowInSeconds();

        saveInvestment(investment);       
    }

    function claim(address assetAddress, address toAddress) external onlyOwner {

        userInvestment memory investment = getInvestment(assetAddress);

        if(investment.totalInvestment <= 0){
            revert("Your amount is less than or equal to Zero!");
        }

        if(getDateTimeNowInSeconds().sub(investment.lastUpdateDateInSecond) < 120)// 24 hr _ 86400
        {
             revert("Investment time is minimum 24hr!");
        }

        uint256 balanceAtoken = getATokenBalance(assetAddress);

        uint256 amountDifference = balanceAtoken.sub(investment.totalInvestment);

        uint256 masterWalletAmount = (amountDifference.mul(feePercentage)).div(100);

        // uint256 withdraw = withdrawFromLending(assetAddress, balanceAtoken);

        if(1 > 0){

            // To master
            // transferMoney(assetAddress, masterWallet, masterWalletAmount);
    
            // To client
            // transferMoney(assetAddress, toAddress, balanceAtoken.sub(masterWalletAmount));

            investment.totalInvestment = investment.totalInvestment.sub(balanceAtoken);
            investment.lastClaimedDateInSecond = getDateTimeNowInSeconds();

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