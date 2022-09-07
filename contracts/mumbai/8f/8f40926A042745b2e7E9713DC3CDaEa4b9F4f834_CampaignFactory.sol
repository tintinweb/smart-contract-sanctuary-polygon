// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract CampaignFactory {
    Campaign[] public deployedCampaigns;

    function createCampaign(uint minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);

        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (Campaign[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
    }

    uint256 public approveID;
    mapping(uint256 => mapping(address => bool)) public approvals;
    Request[] public requests;
    address public manager;
    uint public minimunContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint minimum, address creator) {
        manager = creator;
        minimunContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimunContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string memory description,
        uint value,
        address recipient
    ) public restricted {
        Request memory newRequst = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });
        requests.push(newRequst);
        approveID++;
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];
        require(approvers[msg.sender]);
        //require(!request.approvals[msg.sender]);
        require(!approvals[approveID][msg.sender]);

        //request.approvals[msg.sender] = true;
        approvals[approveID][msg.sender] = true;
        request.approvalCount++;
    }

    function finalizedRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        address payable recipient = payable(request.recipient);
        recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary()
        public
        view
        returns (
            uint,
            uint,
            uint,
            uint,
            address
        )
    {
        return (
            minimunContribution,
            address(this).balance,
            requests.length,
            approversCount,
            manager
        );
    }
}