/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface Token {
    function mintFor(address engineer,uint256 amount) external;
    function balanceOf(address _owner) external returns(uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
}

contract ProjectContractMultipleEngineer{

    address owner = 0x1e93d96DfE65DA1eEf049904ab90318D03a634f0;
    address tokenContract = 0xfae76E9726e9074676aD0D3c4065D5dBebaDed80;
    address govenorContract = 0x464EE03D724fFC17461cFC7025DE441B7844ea13;

    uint128 rewardRatePercentage;

    enum Status { Active, Paid, Dispute, Refund }

    struct Project{
        address employer;
        address payable[] engineers;
        address payable reviewer;
        address validator;
        uint128[] engineerFeesToken;
        uint128 engineerTotalFeeToken;
        uint128 reviewerFeeToken;
        uint16[] engineerFeesUSD;
        uint16 reviewerFeeUSD;
        Status jobStatus;
    }

    mapping(uint => Project) public projects;

    event statusUpdated(uint32 projectId, Status status);

    function mintTokenFor(address engineer,uint256 amount) internal {
        Token(tokenContract).mintFor(engineer,amount);
    }

    function getBalance(address user) internal returns(uint balance) {
        return Token(tokenContract).balanceOf(user);
    }

    function createJob(uint32 projectId,address payable[] calldata engineers,address payable reviewer,uint128 reviewerFeeToken,uint16[] calldata engineerFeesUSD,uint16 reviewerFeeUSD) public payable{

        uint128 engineerTotalPriceToken = 0;
        uint128[] memory engineerFeesToken;
        uint128 engineerFeeToken;

        for (uint i=0; i<engineerFeesUSD.length; i++) {
            
            engineerFeeToken = engineerFeesUSD[i]*rewardRatePercentage/100;
            engineerFeesToken[i] = engineerFeeToken;
            engineerTotalPriceToken = engineerTotalPriceToken + engineerFeeToken;
        }

        //No need to check balance because enginner is paid with new coins
        //require(getBalance(msg.sender) >= engineerTotalPrice, "Employer have to pay full job price");
        require(msg.sender != address(0), "Employer address not valid");
        require(projects[projectId].employer == address(0), "Project Id already in use");

        Project memory newProject = Project(msg.sender,engineers,reviewer,address(0),engineerFeesToken,engineerTotalPriceToken,reviewerFeeToken,engineerFeesUSD,reviewerFeeUSD,Status.Active);
        projects[projectId] = newProject;

        emit statusUpdated(projectId, newProject.jobStatus);
    }

    function acceptJob(uint32 projectId) public {
        require(msg.sender == projects[projectId].employer, "Only registered employer can verify the Job");

        for (uint i=0; i<projects[projectId].engineers.length; i++) {
            mintTokenFor(projects[projectId].engineers[i],projects[projectId].engineerFeesToken[i]);
        }

        if(projects[projectId].reviewer != address(0) && projects[projectId].reviewerFeeToken > 0){

            projects[projectId].reviewer.transfer(projects[projectId].reviewerFeeToken);

        }

        projects[projectId].jobStatus = Status.Paid;

        emit statusUpdated(projectId, Status.Paid);
    }

    function openDispute(uint32 projectId,address validator) public {
        //require(msg.sender == projects[projectId].employer || msg.sender == projects[projectId].engineers , "Only registered Employer or Enginner can dispute the Job");

        projects[projectId].validator = validator;

        projects[projectId].jobStatus = Status.Dispute;

        emit statusUpdated(projectId, Status.Dispute);
    }

    function markAsPass(uint32 projectId) public {
        require(projects[projectId].jobStatus == Status.Dispute, "Job has to be in dispute state");
        require(msg.sender == projects[projectId].validator, "Only registered validator can pass the job");

        for (uint i=0; i<projects[projectId].engineers.length; i++) {
            uint128 engineerFee = projects[projectId].engineerFeesToken[i];
            if(engineerFee > 0){
                mintTokenFor(projects[projectId].engineers[i],engineerFee);
            }
        }

        if(projects[projectId].reviewer != address(0) && projects[projectId].reviewerFeeToken > 0){

            mintTokenFor(projects[projectId].reviewer,projects[projectId].reviewerFeeToken);

        }

        projects[projectId].jobStatus = Status.Paid;

        emit statusUpdated(projectId, Status.Paid);
    }

    function markAsFail(uint32 projectId) public {
        require(projects[projectId].jobStatus == Status.Dispute, "Job has to be in dispute state");
        require(msg.sender == projects[projectId].validator, "Only registered validator can Refund");

        if(projects[projectId].reviewer != address(0)){

            mintTokenFor(projects[projectId].reviewer,projects[projectId].reviewerFeeToken);

        }
        
        projects[projectId].jobStatus = Status.Refund;

        emit statusUpdated(projectId, Status.Refund);
    }


    function updateRewardRate(uint128 newRewardRatePercentage) public {
        require(msg.sender == govenorContract, "Only govenor can change reward rate");

        rewardRatePercentage = newRewardRatePercentage;
    }

}