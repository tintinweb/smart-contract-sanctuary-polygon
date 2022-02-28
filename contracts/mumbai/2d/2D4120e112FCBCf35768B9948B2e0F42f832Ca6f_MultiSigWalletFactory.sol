/**
 *Submitted for verification at polygonscan.com on 2022-02-27
*/

// File: contracts/MultiSigWallet.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MultiSigWallet {
	enum UserRoles {
		Member,
		Voter
	}
	
	struct Transaction {
		address destination;
		uint value;
		bytes data;
		bool executed;
	}

	struct Proposal {
		address proposer;
		address deleting_address;
		bool executed;
	}

	struct ChangeProposal {
		address proposer;
		uint required_votes;
		bool executed;
	}

	struct User {
        uint id;
		address owner;
		uint amount_invested;
		UserRoles user_role;
	}

	mapping(uint => Transaction) public transactions;
	mapping(uint => mapping(address => bool)) public confirmations;
	mapping(address => bool) public isMember;
	mapping(address => bool) public isVoter;
	mapping(address => User) public musers;
	uint public transactionCount;
	User[] public users;

	mapping(uint => Proposal) public proposals;
	mapping(uint => mapping(address => bool)) public proposal_confirmations;
	uint public proposalCount;

	mapping(uint => ChangeProposal) public change_proposals;
	mapping(uint => mapping(address => bool)) public change_proposal_confirmations;
	uint changeProposalCount;
	
	address public owner;
	// uint public amount_above_voter;
	uint public required_votes;

	// Events

	event UserAdd(uint id, address indexed user, uint amount_invested, UserRoles user_role);
	event UserUpdate(uint id, uint amount_invested);
	event UserRemove(uint id, address indexed user);

	event TransactionAdd(uint indexed transactionId, address destination, uint value, bytes data, bool executed);
	event TransactionRemove(uint indexed transactionId, address destination, uint value, bytes data, bool executed);
	event TransactionSuccess(uint indexed transactionId, address destination, uint value, bytes data, bool executed);
	event TransactionFailure(uint indexed transactionId, address destination, uint value, bytes data, bool executed);
	
	event Deposit(address indexed sender, uint value);
	
	event ChangeRoleAmount(uint amount_above_owner);
	event ChangeMaxVote(uint required_votes);
	
	event UserRemoveProposal(uint proposalId, address indexed proposer, address indexed user, bool executed);
	event ProposalConfirm(uint indexed proposalId, address indexed user);
	event ProposalRevoke(uint indexed proposalId, address indexed user);
	
	event TransactionConfirm(uint indexed transactionId, address indexed user);
	event TransactionRevoke(uint indexed transactionId, address indexed user);
	
	event AddChangeProposal(uint indexed proposalId, address indexed proposer, uint required_votes, bool executed);
	event ChangeProposalConfirm(uint indexed proposalId, address indexed user);
	event ChangeProposalRevoke(uint indexed proposalId, address indexed user);
	event ChangeProposalExecuted(uint indexed proposalId);

	modifier notAnOwner() {
		require(!isVoter[msg.sender] && !isMember[msg.sender], "notAnOwner");
		_;
	}

	modifier onlyOwner(address _owner) {
		require(msg.sender == owner, "onlyOwner");
		_;
	}

	modifier anOwner() {
		require(isVoter[msg.sender] || isMember[msg.sender], "anOwner");
		_;
	}

	modifier anVoter() {
		require(isVoter[msg.sender], "anVoter");
		_;
	}

	modifier transactionExists(uint transactionId) {
		require(transactions[transactionId].destination != address(0), "transactionExists");
		_;
	}

	modifier proposalExists(uint proposalId) {
		require(proposals[proposalId].proposer != address(0), "proposalExists");
		_;
	}

	modifier proposal_confirmed(uint proposalId, address _owner) {
		require(proposal_confirmations[proposalId][_owner], "proposal_confirmed");
		_;
	}

	modifier not_proposal_confirmed(uint proposalId, address _owner) {
		require(!proposal_confirmations[proposalId][_owner], "not_proposal_confirmed");
		_;
	}

	modifier proposal_executed(uint proposalId) {
		require(proposals[proposalId].executed, "proposal_executed");
		_;
	}

	modifier not_proposal_executed(uint proposalId) {
		require(!proposals[proposalId].executed, "not_proposal_executed");
		_;
	}

	modifier notConfirmed(uint transactionId, address _owner) {
		require(!confirmations[transactionId][_owner], "notConfirmed");
		_;
	}

	modifier confirmed(uint transactionId, address _owner) {
		require(confirmations[transactionId][_owner], "confirmed");
		_;
	}

	modifier notNull(address destination) {
		require(!(destination == address(0)), "notNull");
		_;
	}

	modifier notExecuted(uint transactionId) {
		require(!transactions[transactionId].executed, "notExecuted");
		_;
	}

	modifier executed(uint transactionId) {
		require(transactions[transactionId].executed, "executed");
		_;
	}

    modifier checkBalance(uint value) {
        require(address(this).balance > value, "Balance is Low");
        _;
    }

	modifier changeProposalExists(uint _changeProposalId) {
		require(change_proposals[_changeProposalId].proposer != address(0), "Proposal Doesn't Exists");
		_;
	} 

	modifier notChangeProposalExists(uint _changeProposalId) {
		require(change_proposals[_changeProposalId].proposer == address(0), "Proposal Doesn't Exists");
		_;
	} 
	
	modifier changeProposalConfirmed(uint _changeProposalId, address sender) {
		require(change_proposal_confirmations[_changeProposalId][sender], "Proposal is not confirmed by sender!");
		_;
	}
	
	modifier notChangeProposalConfirmed(uint _changeProposalId, address sender) {
		require(!change_proposal_confirmations[_changeProposalId][sender], "Proposal already confirmed by sender!");
		_;
	}
	
	modifier changeProposalExecuted(uint _changeProposalId) {
		require(change_proposals[_changeProposalId].executed, "Proposal not executed");
		_;
	}
	
	modifier notChangeProposalExecuted(uint _changeProposalId) {
		require(!change_proposals[_changeProposalId].executed, "Proposal already executed");
		_;
	}

	// Functions

	/// @dev - will create a new user along with a new wallet
	constructor (uint _required_votes, address _owner, address[] memory _members) payable {
        require(msg.value > 0, "Please Pay your Share in the investment fund!");
		
		owner = _owner;
		// amount_above_voter = _amount_above_voter;
		required_votes = _required_votes;
		User memory user = User(users.length, _owner, msg.value, UserRoles.Voter);

		users.push(user);
		musers[msg.sender] = user;
		isVoter[msg.sender] = true;
		emit UserAdd(users.length - 1, msg.sender, msg.value, UserRoles.Voter);

		for(uint i=0;i<_members.length;i++) {
			User memory _user = User(users.length, _members[i], 0, UserRoles.Voter);
			users.push(_user);
			musers[_members[i]] = _user;
			isVoter[_members[i]] = true;

			emit UserAdd(users.length - 1, _members[i], 0, UserRoles.Voter);
		}
	}

	function deposit() external payable {
		require(msg.value > 0, "Send Some money to SAFE");
		if(isVoter[msg.sender]) {
			musers[msg.sender].amount_invested = msg.value;
			emit UserUpdate(musers[msg.sender].id, msg.value);
		}
		emit Deposit(msg.sender, msg.value);
	}

	/// @dev - will add members or voters
	function addUser() public payable notAnOwner {
		require(msg.value > 0, "You need to send some money to the SAFE");
		
		UserRoles role;
		
		role = UserRoles.Voter;
		isVoter[msg.sender] = true;
		
		User memory user = User(users.length, msg.sender, msg.value, role);
		users.push(user);
		musers[msg.sender] = user;

		emit UserAdd(users.length - 1, msg.sender, msg.value, role);
	}

	/// @dev - will add a proposal to remove members or voters
	function removeUserProposal(address _user) public anVoter {
		Proposal memory deleting_proposal = Proposal(msg.sender, _user, false);
		
		proposals[proposalCount] = deleting_proposal;
		addConfirmationProposal(proposalCount);
		emit UserRemoveProposal(proposalCount, msg.sender, _user, false);
		proposalCount += 1;
	}

	/// @dev will remove members or voters
	function removeUser(uint _proposalId) public {
		require(isProposalConfirmed(_proposalId), "Proposal Not Confirmed Yet");
		
		Proposal storage deleting_proposal = proposals[_proposalId];
		User memory user = musers[deleting_proposal.deleting_address]; 

		isVoter[deleting_proposal.deleting_address] = false;

		uint user_id;

		for(uint i=0;i<users.length;i++) {
			if(users[i].owner == deleting_proposal.deleting_address) {
				user_id = i;
				users[i] = users[users.length - 1];
				break;
			}
		}
		users.pop();

		if(required_votes > users.length) {
			required_votes = users.length;
		}

		emit UserRemove(user_id, deleting_proposal.deleting_address);

		deleting_proposal.executed = true;
	}

	/// @dev - add proposal confirmation
	function addConfirmationProposal(uint _proposalId) public anOwner anVoter proposalExists(_proposalId) not_proposal_confirmed(_proposalId, msg.sender) {
		proposal_confirmations[_proposalId][msg.sender] = true;
		emit ProposalConfirm(_proposalId, msg.sender);
		if(isProposalConfirmed(_proposalId)) {
			removeUser(_proposalId);
		}
	}

	/// @dev - revoke proposal confirmation proposal 
	function revokeConfirmationProposal(uint _proposalId) public anOwner anVoter proposalExists(_proposalId) proposal_confirmed(_proposalId, msg.sender) not_proposal_executed(_proposalId) {
		proposal_confirmations[_proposalId][msg.sender] = false;
		emit ProposalRevoke(_proposalId, msg.sender);
	}

	/// @dev - check if a proposal is confirmed
	function isProposalConfirmed(uint _proposalId) internal view proposalExists(_proposalId) returns (bool) {
		uint count = 0;
		
		for(uint i=0;i<users.length;i++) {
			address usr = users[i].owner;
			if(proposal_confirmations[_proposalId][usr]) {
				count += 1;
			}

			if(count == required_votes) {
				return true;
			}
		}

		if(count == required_votes) return true;
		else return false;
	}

	/// @dev Creates a Proposal to change required_votes and amount_to_vote
	function changeConstants(uint _required_votes) public anOwner {
		ChangeProposal memory proposal = ChangeProposal(msg.sender, _required_votes, false);
		change_proposals[changeProposalCount] = proposal;
		addConfirmationChangeProposal(changeProposalCount);
		emit AddChangeProposal(changeProposalCount, msg.sender, _required_votes, false);
		changeProposalCount += 1;
	}

	/// @dev add confirmation for changing constants
	function addConfirmationChangeProposal(uint _changeProposalId) public anVoter changeProposalExists(_changeProposalId) notChangeProposalConfirmed(_changeProposalId, msg.sender) notChangeProposalExecuted(_changeProposalId) {
		change_proposal_confirmations[_changeProposalId][msg.sender] = true;
		emit ChangeProposalConfirm(_changeProposalId, msg.sender);
		if(isChangeProposalConfirmed(_changeProposalId)) {
			executeChangeProposal(_changeProposalId);
		}
	}

	/// @dev revoke confirmation for changing constants
	function revokeConfirmationChangeProposal(uint _changeProposalId) public anVoter changeProposalExists(_changeProposalId) changeProposalConfirmed(_changeProposalId, msg.sender) notChangeProposalExecuted(_changeProposalId) {
		change_proposal_confirmations[_changeProposalId][msg.sender] = false;
		emit ChangeProposalRevoke(_changeProposalId, msg.sender);
	}

	/// @dev Check if a proposal is confirmed
	function isChangeProposalConfirmed(uint _changeProposalId) public view changeProposalExists(_changeProposalId) notChangeProposalExecuted(_changeProposalId) returns (bool) {
		uint count = 0;
		
		for(uint i=0;i<users.length;i++) {
			address usr = users[i].owner;
			if(change_proposal_confirmations[_changeProposalId][usr]) {
				count += 1;
			}

			if(count == required_votes) {
				return true;
			}
		}

		if(count == required_votes) return true;
		else return false;
	}

	/// @dev execute changes if change proposal is confirmed
	function executeChangeProposal(uint _changeProposalId) public anVoter changeProposalExists(_changeProposalId) notChangeProposalExecuted(_changeProposalId) {
		require(isChangeProposalConfirmed(_changeProposalId), "Change Proposal not confirmed yet");

		required_votes = change_proposals[_changeProposalId].required_votes;

		change_proposals[_changeProposalId].executed = true;

		emit ChangeProposalExecuted(_changeProposalId);
	}

	/// @dev - submit a transaction
	function submitTransaction(address _destination, uint _value, bytes memory _data) public checkBalance(_value) returns (uint transactionId) {
		transactionId = addTransaction(_destination, _value, _data);
		confirmTransaction(transactionId);
	}

	/// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public anOwner anVoter transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        emit TransactionConfirm(transactionId, msg.sender);
        if(isConfirmed(transactionId)) {
			executeTransaction(transactionId);
		}
    }

	/// @dev Allows an owner to reject a transaction.
    /// @param transactionId Transaction ID.
    function rejectTransaction(uint transactionId) public anOwner anVoter transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = false;
        emit TransactionRevoke(transactionId, msg.sender);
    }

	/// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public anOwner confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit TransactionSuccess(transactionId, txn.destination, txn.value, txn.data, txn.executed);
            else {
                txn.executed = false;
                emit TransactionFailure(transactionId, txn.destination, txn.value, txn.data, txn.executed);
            }
        }
    }

	// call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

	/// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) public view returns (bool)
    {
        uint count = 0;
        
		for(uint i=0;i<users.length;i++) {
			address usr = users[i].owner;
			if(confirmations[transactionId][usr]) {
				count += 1;
			}

			if(count == required_votes) {
				return true;
			}
		}

		if(count == required_votes) return true;
		else return false;
    }

	/// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    // @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data) internal notNull(destination) returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        emit TransactionAdd(transactionId, destination, value, data, false);
        transactionCount += 1;
    }
}
// File: contracts/MultiSigWalletFactory.sol

pragma solidity ^0.8.0;


contract MultiSigWalletFactory {
	MultiSigWallet[] public deployed_wallets;
	
	event WalletCreated(MultiSigWallet wallet);

	function create_wallet(uint required_votes, address[] memory _members) public payable {
		MultiSigWallet wallet = new MultiSigWallet{value: msg.value}(required_votes, msg.sender, _members);
		deployed_wallets.push(wallet);
		emit WalletCreated(wallet);
	}
}