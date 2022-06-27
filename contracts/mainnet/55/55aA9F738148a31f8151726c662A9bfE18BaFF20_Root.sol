/**
 *Submitted for verification at polygonscan.com on 2022-06-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Root{
    address public owner;
    mapping(address=>bool) ownerContract;
    constructor(address _owner) {
        owner = _owner;
    }
    struct Campaign{
        address owner;
        uint lowPrice;
        uint startReg;
        uint startCharity;
        uint startApprove;
        uint startDisbur;
        uint total;
    }

    struct Donate{
        address owner;
        uint count;
    }
     struct Form{
        address owner;
        string pdf;
    }

    Campaign[] campaign;
    mapping(uint=>Donate[]) donate;
    mapping(uint=>Form[]) form;

    // Event
    event createLaunch(address owner,uint index);
    event startCharity(address owner,uint index);
    event startApprove(address owner,uint index);
    event startDisbur(address owner,uint index);

    // Create campaign
    function createCampaign(address _owner,
        uint _lowPrice,
        uint _startReg,
        uint _startCharity,
        uint _startApprove,
        uint _startDisbur,
        uint _total) external {
        require(ownerContract[msg.sender],"Not Approve");
        Campaign memory camp = Campaign(_owner,_lowPrice,_startReg,_startCharity,_startApprove,_startDisbur,_total);
        campaign.push(camp);
    }
    function pushTotal(uint index,uint _total) external {
        require(ownerContract[msg.sender],"Not Approve");
         campaign[index].total = _total;
    }

    function add(address addContract) public{
        require(msg.sender==owner,"Not Owner");
        ownerContract[addContract] = true;
    }

    function getAllCampaign() public view returns(Campaign[] memory camp){
        return campaign;
    }
    function getCampaign(uint index) public view returns(Campaign memory camp){
        return campaign[index];
    }

    // Sign up form
    function addForm(address from,uint index,string memory pdf) public {
        require(ownerContract[msg.sender],"Not Approve");
        Form memory f = Form(from,pdf);
        form[index].push(f);
    }

    function getAllForm(uint index) public view returns(Form[] memory f){
        return form[index];
    }

    function getForm(uint iCampain,uint iForm) public view returns(Form memory f){
        return form[iCampain][iForm];
    }

    function addDonate(address _owner,uint _amount,uint index) public {
        require(ownerContract[msg.sender],"Not Approve");
        Donate memory d = Donate(_owner,_amount);
        donate[index].push(d);
    }

    function getAllDonate(uint index) public view returns(Donate[] memory sup){
        return donate[index];
    }

    function getDonate(uint iCampain,uint iDonate) public view returns(Donate memory d){
        return donate[iCampain][iDonate];
    }
}