//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./libraries/SafeMath.sol";
import "./libraries/ECDSA.sol";
import "./Timelock.sol";

contract ClampGovernance {

    using SafeMath for uint;
    using ECDSA for bytes32;

    event NewProposal(uint proposalId, address proposer, uint startBlock, uint endBlock, address[] target,
    string[] signature, bytes[] calldatas);
    event NewVoter(uint proposalId, address Voter);
    event NewVoters(uint proposalId, address[] Voters);
    event ProposalQueued(uint proposalId, uint eta);
    event ProposalCanceled(uint proposalId);
    event ProposalExecuted(uint proposalId);
    event voteCasted(uint proposalId, address voter, bool isInFavour);

    ///@notice name of this contract
    string public constant name = "Clamp Governance Alpha";

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a proposal to succeed
    uint public quorumVotes = 1; //10

    /// @notice the number of blocks after which voting should end
    uint public votingPeriod = 100; //280000

    /// @notice The delay before voting on a proposal may take place, once proposed
    uint public votingDelay = 1; //1 block

    address public owner;

    Timelock public immutable timelockContract;

    constructor(address _owner, address _timelockContractAddress) {
        owner = _owner;
        timelockContract  = Timelock(_timelockContractAddress);
        
    }
 
    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;

        ///@notice name of the proposal
        string name;

        ///@notice description of the proposal
        string description;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice The ordered list of function signatures to be called
        string[] signatures;

        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        /// @notice The block at which voting begins
        uint startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        
    }

    mapping(uint => address[]) public forVotes;
    mapping(uint => address[]) public againstVotes;

    ///@notice receipts if user has voted for a proposal
    mapping(uint => mapping (address => Receipt)) public receipts; 

    /// @notice Ballot receipt record for a voter
    struct Receipt {
    
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;
    }


    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    ProposalState public proposalState;

    /// @notice The official record of all proposals ever proposed
    mapping(uint => Proposal) public proposals;

    /// @notice whitelist Addresses that are allowed to vote on a specific proposal
    mapping(uint => address[]) public whitelistedAddresses;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "CLAMP: NOT OWNER");
        _;
    }

    ///@return keccak256 hash of name description and proposer address
    function getHash(string calldata _name, string calldata _description, address _proposer) public pure 
    returns(bytes32) {
        return keccak256(abi.encodePacked(_name, _description, _proposer));
    }
    
    ///@notice - Propose function is used to propose a new proposal
    ///@param  _targets - targets are the addresses of the contract/EOA where function call to be made
    ///@param _signatures - is the signatures of the function which should be called
    ///@param calldatas - is an array of the arguments that should be passed in those function calls
    function Propose(string calldata _name, string calldata _description, address _proposer, bytes memory signature, 
    address[] calldata _targets, string[] memory _signatures, bytes[] memory calldatas) external onlyOwner{
        
        //calculate the hash of the fields
        bytes32 messageHash = getHash(_name, _description, _proposer);

        //convert it to signed message hash
        bytes32 signedMessageHash = messageHash.toEthSignedMessageHash();

        //extract the original sender
        address signer = signedMessageHash.recover(signature);

        require(_proposer == signer, "CLAMP: NOT PROPOSER");
        require(_targets.length == _signatures.length && _targets.length == calldatas.length && _targets.length <= 8,
        "CLAMP: MORE THAN 8 FUNCTION CALLS NOT ALLOWED");

        ///@notice only 1 proposal can stay active at a time
        if(proposalCount != 0) {
            ProposalState proposersLatestProposalState = state(proposalCount);
            require(proposersLatestProposalState == ProposalState.Executed || 
            proposersLatestProposalState == ProposalState.Canceled || 
            proposersLatestProposalState == ProposalState.Defeated ||
            proposersLatestProposalState == ProposalState.Expired, 
            "CLAMP: ANOTHER PROPOSAL EXIST");
        }

        proposalCount += 1;

        Proposal storage newProposal = proposals[proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer = _proposer;
        newProposal.name = _name;
        newProposal.description = _description;
        newProposal.startBlock = (block.number).add(votingDelay);
        newProposal.endBlock = (block.number).add(votingPeriod);
        newProposal.targets = _targets;
        newProposal.signatures = _signatures;
        newProposal.calldatas = calldatas;

        emit NewProposal(proposalCount, newProposal.proposer, newProposal.startBlock, newProposal.endBlock, 
        _targets, _signatures, calldatas);

    }

    ///@notice whitelist address that is allowed to vote based on CLAMP Voting mechanism
    function whitelistAddress(uint _proposalId, address _voter) external onlyOwner{
        require(_proposalId == proposalCount, "CLAMP: INVALID PROPOSAL ID");

        ProposalState proposersLatestProposalState = state(_proposalId);
        require(proposersLatestProposalState == ProposalState.Active || 
        proposersLatestProposalState == ProposalState.Pending, "CLAMP: PROPOSAL NOT AVAILABLE");

        bool isVoterExist =  voterExist(_proposalId, _voter);
        require(!isVoterExist, "CLAMP: VOTER ALREADY EXIST");

        whitelistedAddresses[_proposalId].push(_voter);

        emit NewVoter(_proposalId, _voter);
    }

    ///@notice check if the voter address is already whitelisted
    function voterExist(uint _proposalId, address _voter) internal view returns(bool) {
        address[] memory addresses = whitelistedAddresses[_proposalId];

        for(uint i = 0; i < addresses.length;) {
            if(addresses[i] == _voter) {
                return true;
            }

            unchecked {
                ++i;
            }
        }

        return false;
    }

    /// @param _proposalId is the id of the proposal
    /// @return returns the whitelisted addresses for that proposal
    function getWhitelistedAddresses(uint _proposalId) external view returns(address[] memory) {
        return whitelistedAddresses[_proposalId];
    }

    ///@notice current state of the Governance contract
    ///@notice only 1 Proposal can stay active at a time
    function state(uint _proposalId) public view returns (ProposalState) {
        require(_proposalId <= proposalCount && _proposalId > 0, "CLAMP: INVALID PROPOSAL ID");
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.add(timelockContract.GRACE_PERIOD())) {
           return ProposalState.Expired;
        } 
        else {
            return ProposalState.Queued;
        }
    }

    ///@dev allows voter to cast theri vote for or against a proposal
    ///@param _proposalId is the id of the latest proposal
    ///@param isInFavour is the boolean to check if a voter is in favour of proposal or not
    function castVote(uint _proposalId, bool isInFavour) external {
        require(_proposalId == proposalCount, "CLAMP: INVALID PROPOSAL ID");
        ProposalState proposersLatestProposalState = state(_proposalId);
        require(proposersLatestProposalState == ProposalState.Active, "CLAMP: PROPOSAL NOT ACTIVE");

        bool isExist = voterExist(_proposalId, msg.sender);
        require(isExist, "CLAMP: YOU ARE NOT ELIGIBLE");
        require(!receipts[_proposalId][msg.sender].hasVoted, "CLAMP: ALREADY VOTED");

        if(isInFavour) {
            receipts[_proposalId][msg.sender].hasVoted = true;
            receipts[_proposalId][msg.sender].support = true;
            proposals[_proposalId].forVotes += 1;
            forVotes[_proposalId].push(msg.sender);

        } else {
            receipts[_proposalId][msg.sender].hasVoted = true;
            receipts[_proposalId][msg.sender].support = false;
            proposals[_proposalId].againstVotes += 1;
            againstVotes[_proposalId].push(msg.sender);
        }

        emit voteCasted(_proposalId, msg.sender, isInFavour);
    }

    ///@notice cancels the proposal if needed - should only be called by the owner
    function cancelProposal(uint _proposalId) external onlyOwner {
        require(_proposalId <= proposalCount, "CLAMP: INVALID PROPOSAL ID");
        require(!proposals[_proposalId].canceled, "CLAMP: PROPOSAL ALREADY CANCELLED");
        require(!proposals[_proposalId].executed, "CLAMP: PROPOSAL ALREADY EXECUTED");

        proposals[_proposalId].canceled = true;

        emit ProposalCanceled(_proposalId);
    }

    ///@notice queue the proposal in the timelock contract for community validators to check if proposal is valid
    ///@notice queue function can be called by anyone
    function queue(uint _proposalId) external {
        require(_proposalId == proposalCount, "CLAMP: INVALID PROPOSAL ID");
        require(block.number >= proposals[_proposalId].endBlock, "CLAMP: VOTING NOT ENDED YET!");

        ProposalState proposersLatestProposalState = state(_proposalId);

        require(proposersLatestProposalState == ProposalState.Succeeded, "CLAMP: PROPOSAL NOT SUCCEEDED");

        Proposal memory proposalDetails = proposals[_proposalId];

        uint eta = block.timestamp.add(timelockContract.delay());

        timelockContract.queueTransaction(proposalDetails.targets, proposalDetails.signatures, 
        proposalDetails.calldatas, eta);

        proposals[_proposalId].eta = eta;

        emit ProposalQueued(_proposalId, eta);
    
    }


    ///@notice marks the function as executed by the owner
    function execute(uint _proposalId) external onlyOwner{
        require(_proposalId == proposalCount, "CLAMP: INVALID PROPOSAL ID");

        ProposalState proposersLatestProposalState = state(_proposalId);

        require(proposersLatestProposalState == ProposalState.Queued, "CLAMP: PROPOSAL NOT QUEUED");

        Proposal memory proposalDetails = proposals[_proposalId];

        timelockContract.executeTransaction(proposalDetails.targets, proposalDetails.signatures, 
        proposalDetails.calldatas, proposalDetails.eta);

        proposals[_proposalId].executed = true;

        emit ProposalExecuted(_proposalId);
    }

    function getReceipt(uint _proposalId, address _voter) external view returns(Receipt memory){
        return receipts[_proposalId][_voter];
    }

    function changeQuorumVotes(uint _quorumVotes) external onlyOwner {
        quorumVotes = _quorumVotes;
    }

    function changeVotingDelay(uint _votingDelay) external onlyOwner {
        votingDelay = _votingDelay;
    }

    ///@param _votingPeriod - should be in block number
    function changeVotingPeriod(uint _votingPeriod) external onlyOwner {
        votingPeriod = _votingPeriod;
    }

    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }

    function getForVotes(uint _proposalId) external view returns(address[] memory){
        return forVotes[_proposalId];
    }

    function getAgainstVotes(uint _proposalId) external view returns(address[] memory) {
        return againstVotes[_proposalId];       
    }

    function getAllProposals() external view returns(Proposal[] memory) {
        Proposal[] memory allProposals = new Proposal[](proposalCount);
        
        for(uint i = 1; i <= proposalCount; i++) {
            allProposals[i - 1] = proposals[i];
        }

        return allProposals;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./libraries/SafeMath.sol";

contract Timelock {

    using SafeMath for uint;

    event TransactionQueued(address[] targets, string[] signatures, bytes[] _calldatas, uint eta);
    event TransactionExecuted(address[] targets, string[] signatures, bytes[] _calldatas, 
    uint eta, uint timestamp);

    error ExecutionFailed(address target, string signature, bytes _calldata, uint eta);

    ///@notice transcation needs to be executed before current block.timestamp is less than eta + GRACE_PERIOD
    uint public constant GRACE_PERIOD = 4 days;

    ///@notice the amount of minimum days after which proposal should be executed
    uint public constant MINIMUM_DELAY = 10;
    
    ///@notice the amount of maximum days before which proposal should be executed
    uint public constant MAXIMUM_DELAY = 15 days;

    ///@notice address of the governance contract
    address public governanceAddress;

    address public owner;

    uint public delay;

    bytes32[] public currentlyQueuedTransactions;

    constructor(address _owner, uint _delay) {
        require(_delay >= MINIMUM_DELAY, "CLAMP: DELAY MUST EXCEED MINIMUM DELAY");
        require(_delay <= MAXIMUM_DELAY, "CLAMP: DELAY MUST NOT EXCEED MAXIMUM DELAY");

        owner = _owner;
        delay = _delay; //3days
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "CLAMP: NOT OWNER");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress && governanceAddress != address(0), "CLAMP: ONLY GOVERNANCE CONTRACT IS ALLOWED");
        _;
    }

    function getTxId(address _target, string memory _signature, bytes memory _calldata, 
    uint eta) public pure returns(bytes32 txId){

        return keccak256(abi.encode(_target, _signature, _calldata, eta));
    }

    ///@notice queues the transcation to be executed in future
    ///@notice only 1 transaction can be queued at a time
    function queueTransaction(address[] calldata _targets, string[] memory _signatures, bytes[] memory _calldatas, 
    uint eta) external onlyGovernance returns(bytes32[] memory) {
        require(eta >= block.timestamp.add(delay), "CLAMP: ESTIMATED EXECUTION BLOCK MUST SATISFY DELAY");
        require(currentlyQueuedTransactions.length == 0, "CLAMP: TRANSACTIONS ALREADY QUEUED");

        for(uint i =0; i<_targets.length;) {

            bytes32 txHash = getTxId(_targets[i], _signatures[i], _calldatas[i], eta);
            currentlyQueuedTransactions.push(txHash);
        
            unchecked {
                ++i;
            }
        }

        emit TransactionQueued(_targets, _signatures, _calldatas, eta);

        return currentlyQueuedTransactions;
    }

    ///@notice marks the transaction as executed
    ///@notice onlyGovernance contract is allowed to call this function
    ///@notice this should be marked as executed by owner only after they executes the proposal
    function executeTransaction(address[] calldata _targets, string[] memory _signatures, bytes[] memory _calldatas,
    uint eta) external onlyGovernance{
        require(currentlyQueuedTransactions.length == _targets.length, "CLAMP: INVALID NUMBER OF QUEUED TRANSACTION");
        require(block.timestamp >= eta, "CLAMP: TRANSACTION HAS NOT SURPASSED TIME LOCK");
        require(block.timestamp <= eta.add(GRACE_PERIOD), "CLAMP: TRANSACTION IS STALE");

        for(uint i = 0; i < currentlyQueuedTransactions.length; ) {

            bytes32 txHash = getTxId(_targets[i], _signatures[i], _calldatas[i], eta);
            if(currentlyQueuedTransactions[i] != txHash) {
                revert ExecutionFailed(_targets[i], _signatures[i], _calldatas[i], eta);
            }

            unchecked {
                ++i;
            }
        }

        delete currentlyQueuedTransactions;

        emit TransactionExecuted(_targets, _signatures, _calldatas, eta, block.timestamp);

    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function initializeGovernanceContract(address _governanceAddress) external onlyOwner {
        governanceAddress = _governanceAddress;
    }

    function updateDelay(uint256 _delay) external onlyOwner {
        require(_delay >= MINIMUM_DELAY, "CLAMP: DELAY MUST EXCEED MINIMUM DELAY");
        require(_delay <= MAXIMUM_DELAY, "CLAMP: DELAY MUST NOT EXCEED MAXIMUM DELAY");

        delay = _delay;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}