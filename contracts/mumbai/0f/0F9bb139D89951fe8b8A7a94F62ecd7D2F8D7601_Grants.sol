/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
    contract Grants{
    address public owner;
	struct Agency{
		string id;
		address owner;
		uint256 balance;
		uint256 NoOfGrants;
		string InfoLink;
	}

	struct Organization{
		string id;
		string InfoLink;
	}

	struct Grant{
		string id;
		string agencyId;
		address Approver;
		uint256 Budget;
		address Creator;
		bool Approved;
		address[] Selected;
		string InfoLink;
	}

	struct GrantSpent{
		string grantId;
		string orgId;
		uint256 Balance;
		uint256 TotalBudgetAppointed;
	}
	
	mapping (address => Agency) public AllAgency;
	mapping (address => Organization) public AllOrganization;
	mapping (string => Grant) public AllGrant;
	mapping (string => GrantSpent) public AllGrantSpent;

    event AgencyAdded(string text);
    event OrgAdded(string text);
    event GrantCreated(string text);
    event GrantUpdated(string text);

    modifier onlyOwner() {
        require(msg.sender == owner,"You Are Not The Owner!");
        _;
    }
    constructor(){
        owner = msg.sender;
    }
	// function transfer(address from, address to) internal {

	// }

	// function ApproveGrant(uint256 _grantId,address _orgAddress) onlyAgencyOwner {
	// 	AllGrant[_grantId].Approved = true;
		

	// 	}
	// }

	// function ReleaseFunds(grantId) onlyAgencyOwner

	// function InstantGrantFunding(grantId)

	//getter and setter for all the structs
    function addAgency(
        address _agencyAddress, 
        string memory _id,
		address _owner,
		uint256 _balance,
		uint256 _noOfGrants,
		string memory _infoLink) 
        public
        onlyOwner
    {
        AllAgency[_agencyAddress].id = _id;
        AllAgency[_agencyAddress].owner = _owner;
        AllAgency[_agencyAddress].balance = _balance;
        AllAgency[_agencyAddress].NoOfGrants = _noOfGrants;
        AllAgency[_agencyAddress].InfoLink = _infoLink;
        emit AgencyAdded("New Agency Added");
    }
    function addOrg(
        address _owner,
        string memory _id,
		string memory _infoLink) 
        public
        onlyOwner
    {
        AllOrganization[_owner].id = _id;
        AllOrganization[_owner].InfoLink = _infoLink;
        emit AgencyAdded("New Organization Added");
    }
    // function addGrant(
    //     uint256 _id,
	// 	uint256 _agencyId,
	// 	address _approver,
	// 	uint256 _budget,
	// 	address _creator,
	// 	bool _approved,
	// 	address _selected,
	// 	bytes32 _infoLink,
    //     address _agencyAddress,
    //     address owner 
    //     ) 
    //     public
    //     onlyOwner
    // {
    //     AllAgency[_agencyAddress].id = _id;
    //     AllAgency[_agencyAddress].owner = _agencyId;
    //     AllAgency[_agencyAddress].balance = _approver;
    //     AllAgency[_agencyAddress].NoOfGrants = _budget;
    //     AllAgency[_agencyAddress].InfoLink = _creator;
    //     AllAgency[_agencyAddress].InfoLink = _approved;
    //     AllAgency[_agencyAddress].InfoLink = _selected;
    //     AllAgency[_agencyAddress].InfoLink = _infoLink;
    //     emit AgencyAdded("New Agency Added");
    // }
    function updateGrantSpent(
        address _agencyAddress, 
        string memory _id,
		address _owner,
		uint256 _balance,
		uint256 _noOfGrants,
		string memory _infoLink) 
        public
        onlyOwner
    {
        AllAgency[_agencyAddress].id = _id;
        AllAgency[_agencyAddress].owner = _owner;
        AllAgency[_agencyAddress].balance = _balance;
        AllAgency[_agencyAddress].NoOfGrants = _noOfGrants;
        AllAgency[_agencyAddress].InfoLink = _infoLink;
        emit AgencyAdded("New Agency Added");
    }
}