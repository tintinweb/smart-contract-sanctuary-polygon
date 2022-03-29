// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./Whitelist.sol";
import "./Kyc.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract KnotStore  is Whitelist,Kyc,ReentrancyGuard{
    using SafeMath for uint256;
    event ClaimEvent(address addr,uint256 amount);
    struct ClaimLog {
        uint256 claimTime;
        address addr;
        uint256 amount;
    }
    struct Batch {
        uint8 batchNo;
        address[] addresses;
        uint256 releaseTime;
        mapping(address => uint256) userClaimable;
    }
    struct personalStatus{
        bool isValid;
        uint256 totalGrant;
        uint256 totalClaimed;
        bool claimed;

    }
    uint256[] public batchTimes;
    address public rewardToken;
    mapping(uint8 => Batch) public batchs;
    mapping(uint8 => mapping(address => personalStatus)) public personalData;
    mapping(address => ClaimLog[]) claimLogs;
    bool public claimable;
    uint256 public batchLength;

    constructor(address token,uint256[] memory releaseTimes) {
        batchLength=releaseTimes.length;
        require(releaseTimes.length==batchLength, "releaseTimes length must equal to batchLength");
        require(token != address(0), "token must not be 0x0");
        rewardToken = token;
        batchTimes=releaseTimes;
        claimable=true;
    }
    modifier claimOpened {
        require(claimable==true,"claimable is not open");
        _;
    }
    modifier validBatchNo(uint8 batchNo) {
        require(batchNo>=1&&batchNo<=batchLength,"batchNo should be 1-batchLength");
        _;
    }
    function getCurrentBatch() public view returns(uint8){
        uint8 currentBatch =0;
        for (uint8 i=0; i<batchTimes.length; i++) {
            if(batchTimes[i]<=block.timestamp){
                currentBatch =i+1;
            }
        }
        return currentBatch;
    }
    function withdrawNativeToken(uint256 amount) public
    onlyOwner{
        require(address(this).balance>=amount,"not sufficient funds");
        payable(msg.sender).transfer(amount);
    }
    function withdrawContractToken(IERC20 token,uint256 amount) public
    onlyOwner{
        token.transfer(msg.sender, amount);
    }
    function replaceAddress(uint8 batchNo,address oldAddr,address newAddr) public
    onlyOwner
    validBatchNo(batchNo)
    nonReentrant{
        batchs[batchNo].userClaimable[newAddr]=batchs[batchNo].userClaimable[oldAddr];
        batchs[batchNo].userClaimable[oldAddr]=0;

        personalData[batchNo][newAddr]=personalData[batchNo][oldAddr];
        personalData[batchNo][oldAddr]=personalStatus({
        isValid:true,
        totalGrant:0,
        totalClaimed:0,
        claimed:true
        });

        claimLogs[newAddr]=claimLogs[oldAddr];



    }
    function updateReleaseTime(uint8 batchNo,uint256 time) public
    onlyOwner
    validBatchNo(batchNo){
        batchTimes[batchNo-1]=time;

    }
    function updateRewardToken(address token) public
    onlyOwner{
        rewardToken=token;
    }
    function updateAmount(uint8 batchNo,address addr,uint256 amount) public
    onlyOwner
    nonReentrant
    validBatchNo(batchNo){
        batchs[batchNo].userClaimable[addr]=amount;
        personalData[batchNo][addr].totalGrant=amount;
    }
    function updateKyc(address addr,uint8 kycValue) public onlyOwner{
        if(kycValue==1){
            addAddressToKycMap(addr);
        }else{
            removeAddressFromKycMap(addr);
        }
    }
    function updateClaimStatus(bool flag) public onlyOwner{
        claimable=flag;
    }
    function getPersonalStatistics() public view onlyWhitelisted returns (uint256[4] memory statistics){
        uint8 currentBatch= getCurrentBatch();
        for (uint8 i=1; i<=batchLength; i++) {
            if(i<=currentBatch){
                //claimed
                statistics[0]=statistics[0].add(personalData[i][msg.sender].totalClaimed);
                //granted
                statistics[1]=statistics[1].add(personalData[i][msg.sender].totalGrant);
            }
            //totalGrant
            statistics[2]=statistics[2].add(personalData[i][msg.sender].totalGrant);
        }
        //granted batch
        statistics[3]=currentBatch;
        return statistics;
    }
    function getPersonalClaimLog() public view onlyWhitelisted returns (ClaimLog[] memory){
        return claimLogs[msg.sender];
    }
    function getClaimable() public view onlyWhitelisted returns (uint256){
        uint256 claimAmount=0;
        uint8 currentBatch= getCurrentBatch();
        for (uint8 i=1; i<=currentBatch; i++) {
            //claimable
            claimAmount=claimAmount.add(batchs[i].userClaimable[msg.sender]);
        }
        return claimAmount;
    }
    function claim() public
    onlyWhitelisted
    onlyKYCed
    claimOpened
    returns (uint256){
        uint256 claimAmount=0;
        uint8 currentBatch= getCurrentBatch();
        require(currentBatch>0&&currentBatch<=batchLength,"currentBatch not right");
        require(personalData[currentBatch][msg.sender].isValid==true,"isValid must be true");
        require(personalData[currentBatch][msg.sender].claimed==false,"claimed must be false");
        for (uint8 i=1; i<=currentBatch; i++) {
            //claimable
            claimAmount=claimAmount.add(batchs[i].userClaimable[msg.sender]);
            batchs[i].userClaimable[msg.sender]=0;
            personalData[i][msg.sender].isValid=true;
            personalData[i][msg.sender].claimed=true;
            personalData[i][msg.sender].totalClaimed=personalData[i][msg.sender].totalGrant;
        }
        require(claimAmount>0,"claimAmount must > 0");
        require(IERC20(rewardToken).transfer(msg.sender,claimAmount),"claim failed");
        claimLogs[msg.sender].push(ClaimLog({
        claimTime:block.timestamp,
        addr:msg.sender,
        amount:claimAmount
        }));
        emit ClaimEvent(msg.sender,claimAmount);
        return claimAmount;
    }
    function importBatch(uint8 batchNo,address[] memory addresses, uint256[] memory amounts,uint8[] memory kyc) public
    onlyOwner
    nonReentrant
    validBatchNo(batchNo){
        require(addresses.length==amounts.length&&addresses.length==kyc.length,"3 arrays length should be equal");
        for (uint8 i=0; i<kyc.length; i++) {
            if (kyc[i]==1){
                addAddressToKycMap(addresses[i]);
            }
            addAddressToWhitelist(addresses[i]);
            batchs[batchNo].userClaimable[addresses[i]]=amounts[i];
            batchs[batchNo].addresses.push(addresses[i]);
            if (personalData[batchNo][addresses[i]].isValid==true){
                personalData[batchNo][addresses[i]].totalGrant=personalData[batchNo][addresses[i]].totalGrant.add(amounts[i]);
            }else{
                personalData[batchNo][addresses[i]]=personalStatus({
                isValid:true,
                totalGrant:amounts[i],
                totalClaimed:0,
                claimed:false
                });
            }
        }
        batchs[batchNo].batchNo=batchNo;
        batchs[batchNo].releaseTime=batchTimes[batchNo-1];

    }

}