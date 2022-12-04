/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

struct Proposal{
    uint _id;
    string _msg;
    uint _yes;
    uint _no;
    bool _passed;
}

contract DummyDao3 {
    string public DaoName="DAO-3";
    uint public idProposal;
    mapping(uint => Proposal) idToProposal;
    mapping(uint=> bool) isSnapShot;
    mapping(address=>uint) balance;

    uint public idSnapShot;
    mapping(uint => Proposal) idToSnapShot;


    address public owner;
    mapping(address=>bool) public representative;

    mapping(uint=>mapping(address=>bool)) proposalVote;
    mapping(uint=>mapping(address=>bool)) snapShotVote;


    constructor (){
        owner = msg.sender;
        representative[owner]=true;
        balance[0x67099d557997E3Ee308B3C49029C331A2d4569Dc]=100;
        balance[0x31B0F3eeD8cAFA7D09C862b7779AAc826F3c4468]=100;
        balance[0xE99DB9cf24e39901228bFa70D05e1aE8b41262e3]=100;
        balance[0x5aCE6dFcC53446F105F0721650573ae9F4531Af7]=10;
    }


    modifier onlyOwner(){
        require(msg.sender == owner,"sorry, you're not the owner of the DAO");
        _;
    }

    modifier onlyRepresentative(){
        require(representative[msg.sender],"sorry, you're not a representative of the DAO");
        _;
    }

    function checkBalance() external view returns(uint){
        return balance[msg.sender];
    }
    
    function addBalance(address _addr) public onlyRepresentative{
        balance[_addr]+=10;
    }

    function addRepresentative(address _addr) public onlyOwner{
        representative[_addr]=true;
    }

    function createProposal(string memory _msg) private {
        idProposal++;
        Proposal memory pr = Proposal(idProposal,_msg,0,0,false);
        idToProposal[idProposal] = pr;
    }

    function createSnapShot(string memory _msg) private {
        idSnapShot++;
        Proposal memory pr = Proposal(idSnapShot,_msg,0,0,false);
        idToSnapShot[idSnapShot] = pr;
    }


    function getAllProposals() external view returns(Proposal[] memory){
        Proposal[] memory pr = new Proposal[](idProposal);
        for(uint i=1;i<=idProposal;i++){
            pr[i-1] = idToProposal[i];
        }
        return pr;
    }

    function getAProposal(uint _id) external view returns(Proposal memory){
        require(_id<=idProposal,"No such proposal exists");
        return idToProposal[_id];
    }

    function getAllSnapShots() external view returns(Proposal[] memory){
        Proposal[] memory pr = new Proposal[](idSnapShot);
        for(uint i=1;i<=idSnapShot;i++){
            pr[i-1] = idToSnapShot[i];
        }
        return pr;
    }

    function getASnapShot(uint _id) external view returns(Proposal memory){
        require(_id<=idSnapShot,"No such snapshot exists");
        return idToSnapShot[_id];
    }

    function createRequestForProposal(string memory _msg) public onlyRepresentative{
        createProposal(_msg);
    }

    function createSnapShot(uint _id) public onlyRepresentative{
        bool passed = idToProposal[_id]._passed;
        require(passed,"The request for proposal is not passed yet");
        require(isSnapShot[_id]==false,"The request is already a snapshot");
        createSnapShot(idToProposal[_id]._msg);
    }

    function voteOnAProposal(uint _id, bool _vote) public{
        require(balance[msg.sender]>=1,"You don't have enough tokens");
        require(_id<=idProposal);
        require(proposalVote[_id][msg.sender]==false,"You have already voted on the proposal.");
        proposalVote[_id][msg.sender]=true;
        if(_vote){
            idToProposal[_id]._yes++;
        }
        else{
            idToProposal[_id]._no++;
        }

        if(idToProposal[_id]._yes > 1){
            idToProposal[_id]._passed=true;
        }
    }

    function voteOnASnapShot(uint _id, bool _vote) public{
        require(balance[msg.sender]>=1,"You don't have enough tokens");
        require(_id<=idSnapShot);
        require(snapShotVote[_id][msg.sender]==false,"You have already voted on the SnapShot.");
        snapShotVote[_id][msg.sender]=true;
        if(_vote){
            idToSnapShot[_id]._yes++;
        }
        else{
            idToSnapShot[_id]._no++;
        }

        if(idToSnapShot[_id]._yes > 2){
            idToSnapShot[_id]._passed=true;
        }
    }

}