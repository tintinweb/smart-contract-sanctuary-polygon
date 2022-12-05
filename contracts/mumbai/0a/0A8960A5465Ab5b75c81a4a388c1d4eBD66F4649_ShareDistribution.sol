/**
 *Submitted for verification at polygonscan.com on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract ShareDistribution {

    address owner;
    uint voteRequiredPercent=50;

    mapping(uint => Partner) public partners;
    mapping(address=>uint) public partnerIds;
    uint public total_share;
    uint public total_partners;

    struct Partner {
        uint id;
        address partner_address;
        bool isVoted;
        uint share;
        uint totalIncome;
    }

    constructor () {
        owner = msg.sender;
        modify_partners_pv(owner,100*1000);
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only owner");
        _;
    }

    modifier onlyPartners {
        require(partnerIds[msg.sender]>0,"Only partners");
        _;
    }

    modifier isPartnersVoted {
        bool isVotedToAddPartner = false;
        uint votedShares;
        for(uint i=1;i<=total_partners;i++){
            if(partners[i].isVoted){
                votedShares += partners[i].share;
                if(votedShares>=voteRequiredPercent)
                {
                    isVotedToAddPartner = true;
                    break;
                }
            }
        }
        require(isVotedToAddPartner,"Not enough vote");
        _;
    }

    function claim_income (address token_address) public {
        //get balance
        IERC20 token = IERC20(token_address);
        uint balance = token.balanceOf(address(this));

        for(uint8 i;i<total_partners;i++){
            uint payable_shares = balance * ( partners[i].share / total_share );
            token.transfer(partners[i].partner_address,payable_shares);
        }
    }

    function updateLockStatus(bool vote) public onlyPartners{
        partners[partnerIds[msg.sender]].isVoted = vote;
    }

    function modify_partners (address partnerAddress, uint share) public onlyOwner isPartnersVoted{
        return modify_partners_pv(partnerAddress, share);
    }

    function modify_partners_pv (address partnerAddress, uint share) private{

        require(share >= 1);
        uint partnerId = partnerIds[partnerAddress];
        if (partners[partnerId].share > 0)
        {
            total_share -= partners[partnerId].share;
            total_share += share;
            partners[partnerId].share = share;
        }else{
            total_partners++;
            partnerId = total_partners;
            partnerIds[partnerAddress] = total_partners;

            total_share += share;
            partners[partnerId].share = share;
            partners[partnerId].partner_address = partnerAddress;
            partnerIds[partnerAddress] = total_partners;
        }
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}