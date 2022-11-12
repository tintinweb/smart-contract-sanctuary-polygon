/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract PayRoll {
    event ProposalIDList(bytes32 indexed userID, uint256 indexed proposalID);

    event ProposalTable(
        address ngoAddress,
        uint256 indexed proposalID,
        string name,
        string title,
        uint256 noHoursWorked,
        string description,
        uint256 amt
    );

    event Transfer(
        address from,
        uint256 amount,
        uint256 timestamp
    );

    struct NGO {
        bytes32 _id;
        address wallet_address;
        bool ngoExists;
    }

    uint256 curr_id = 0;

    struct Proposal {
        uint256 id;
        address postOwner;
        string name;
        string title;
        uint256 noHoursWorked;
        string content;
        uint256 amt; // funds required
        bool proposalExists; // to check if proposal already exists
        bool closed; // true if proposal has raised required funds
    }

    // Map of all NGOs
    mapping(bytes32 => NGO) public userRegistry;
    mapping(uint256 => Proposal) public proposalRegistry;

    function createUser() public {
        bytes32 id = keccak256(abi.encode(msg.sender));
        userRegistry[id]._id = id;
        userRegistry[id].wallet_address = msg.sender;
        userRegistry[id].ngoExists = true;
    }

    // User create proposal
    function createProposal(
        string memory name,
        string memory title,
        uint256 noHoursWorked,
        string memory content,
        uint256 amt
    ) public returns (bool) {
            uint256 id = curr_id;
            curr_id += 1;

            proposalRegistry[id].proposalExists = true;
            proposalRegistry[id].closed = false;
            proposalRegistry[id].postOwner = msg.sender;
            proposalRegistry[id].id = id;
            proposalRegistry[id].name = name;
            proposalRegistry[id].title = title;
            proposalRegistry[id].noHoursWorked = noHoursWorked;
            proposalRegistry[id].content = content;
            proposalRegistry[id].amt = amt * (1 * 1e18);

            emit ProposalTable(msg.sender, id, name, title, noHoursWorked, content, amt);
            return true;
    }

    function transferFunds() public payable {}

    function acceptProposal(uint256 proposalId) public payable {
        if (proposalRegistry[proposalId].proposalExists && !proposalRegistry[proposalId].closed) {
            proposalRegistry[proposalId].closed = true;

            address userAddress = proposalRegistry[proposalId].postOwner;
            // payable(msg.sender).transfer(msg.value);
            // payable(address(this)).transfer(msg.value);
            emit Transfer(userAddress, msg.value, block.timestamp);
            payable(userAddress).transfer(msg.value);
        } 
    }

    function rejectProposal(uint256 proposalId) public {
        if (proposalRegistry[proposalId].proposalExists) {
            proposalRegistry[proposalId].closed = true;
        } 
    }

    function getProposal(uint256 proposalID)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            string memory,
            uint256,
            bool
        )
    {
        return (
            proposalRegistry[proposalID].postOwner,
            proposalRegistry[proposalID].name,
            proposalRegistry[proposalID].title,
            proposalRegistry[proposalID].noHoursWorked,
            proposalRegistry[proposalID].content,
            proposalRegistry[proposalID].amt,
            proposalRegistry[proposalID].closed
        );
    }
}