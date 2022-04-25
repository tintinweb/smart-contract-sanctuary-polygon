/**
 *Submitted for verification at polygonscan.com on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Mintable {
    function mint(address account, uint256 amount) external;
}

contract Actions {

    uint256 public constant ONE_WEEK_IN_SECONDS = 604800;

    struct Action {
        address creator;
        uint256 creationDate;
        uint256 endDate;
        uint256 disputePeriodEnd;
        uint256 stakeAmount;
        string image;
        string metadata;

        uint256 amount;
        uint256 eligibleSubmittersCount;
        bool settled;
    }

    struct Proof {
        address submitter;
        string proof;
        bool failed;
    }

    struct Dispute {
        address creator;
        uint256 proofIndex;
        string disputeProof;
        uint256 disputeEndDate;
        bool settled;

        uint256 forVotes;
        uint256 againstVotes;
    }

    struct Votes {
        mapping(address => bool) voted;
    }

    address governanceToken;

    uint256 public actionIndex = 0;
    mapping(uint256 => Action) public actions;

    mapping(uint256 => Proof[]) public proofs;
    mapping(uint256 => Dispute[]) public disputes;
    mapping(uint256 => mapping(uint256 => Votes)) votes;

    constructor(address _governanceToken) {
        governanceToken = _governanceToken;
    }

    function createAction(
        uint256 _endDate,
        uint256 _stakeAmount,
        string memory _image,
        string memory _metadata
    ) public payable {
        Action memory action;
        action.creator = msg.sender;
        action.creationDate = block.timestamp;
        action.endDate = _endDate;
        action.disputePeriodEnd = _endDate + ONE_WEEK_IN_SECONDS;
        action.stakeAmount = _stakeAmount;
        action.image = _image;
        action.metadata = _metadata;
        action.amount = msg.value;
        action.eligibleSubmittersCount = 0;
        actions[actionIndex] = action;
        actionIndex++;
    }

    function contribute(uint256 actionId) public payable {
        Action storage action = actions[actionId];
        require(block.timestamp <= action.endDate, "Contributions after end date are not allowed");
        action.amount += msg.value;
        Mintable(governanceToken).mint(msg.sender, msg.value);
    }

    function submitProof(uint256 actionId, string memory proof) public payable {
        Action storage action = actions[actionId];
        require(block.timestamp <= action.endDate , "Can't submit a proof proof after end date");
        require(msg.value == action.stakeAmount, "Can't add a proof as stake amount is not valid");
        action.eligibleSubmittersCount++;
        // todo: not allow to submit proofs multiple times

        Proof memory newProof;
        newProof.submitter = msg.sender;
        newProof.proof = proof;
        proofs[actionId].push(newProof);
    }

    function openDispute(uint256 actionId, uint256 proofIndex, string memory proof) public payable {
        Action memory action = actions[actionId];
        require(action.disputePeriodEnd > block.timestamp, "Can't submit a proof proof after end of dispute period");
        require(msg.value == action.stakeAmount, "Can't add a proof as stake amount is not valid");
        // todo: not allow to open dispute multiple times

        Dispute memory dispute;
        dispute.creator = msg.sender;
        dispute.proofIndex = proofIndex;
        dispute.disputeProof = proof;
        dispute.disputeEndDate = block.timestamp + ONE_WEEK_IN_SECONDS;
        disputes[actionId].push(dispute);
    }

    function vote(uint256 actionId, uint256 disputeId, bool voteFor) public {
        uint256 votingPower = IERC20(governanceToken).balanceOf(msg.sender);
        require(votingPower > 0, "You can't vote without governance tokens");
        require(!votes[actionId][disputeId].voted[msg.sender], "You can't vote two times");
        votes[actionId][disputeId].voted[msg.sender] = true;

        Dispute storage dispute = disputes[actionId][disputeId];
        if (voteFor) {
            dispute.forVotes += votingPower;
        } else {
            dispute.againstVotes += votingPower;
        }
    }

    function settle() public {
        for (uint256 i = 0; i < actionIndex; i++) {
            Action memory a = actions[i];
            if (a.settled) {
                continue;
            }
            (bool ongoing, bool unsettled) = hasDisputes(i);
            if (unsettled) {
                settleDisputes(i);
            }

            if (!ongoing && block.timestamp > a.disputePeriodEnd) {// no ongoing disputes and dispute period ended settle action
                settleAction(i);
            }
        }
    }

    function settleAction(uint256 actionId) private {
        Action memory action = actions[actionId];
        Proof[] memory actionProofs = proofs[actionId];
        uint256 amountToPay = action.amount / action.eligibleSubmittersCount + action.stakeAmount;
        for (uint256 i = 0; i < actionProofs.length; i++) {
            if (!actionProofs[i].failed) {
                payable(actionProofs[i].submitter).transfer(amountToPay);
            }
        }
        actions[actionId].settled = true;
    }

    function settleDisputes(uint256 actionId) private {
        Dispute[] storage actionDisputes = disputes[actionId];
        for (uint256 i = 0; i < actionDisputes.length; i++) {
            Dispute storage current = actionDisputes[i];
            if (current.disputeEndDate > block.timestamp && !current.settled) {
                settleDispute(current, actionId);
            }
        }
    }

    function settleDispute(Dispute storage dispute, uint256 actionId) private {
        if (dispute.forVotes > dispute.againstVotes) {// challenger wins
            Proof storage proof = proofs[actionId][dispute.proofIndex];
            proof.failed = true;
            actions[actionId].eligibleSubmittersCount--;

            payable(dispute.creator).transfer(2 * actions[actionId].stakeAmount);
        } else {// proof submitter wins, challenger money stay with us
            dispute.settled = true;
        }
    }

    function hasUnsettled() public view returns (bool)  {
        for (uint256 i = 0; i < actionIndex; i++) {
            Action memory a = actions[i];
            if (a.settled) {
                continue;
            }
            // case one has unsettled disputes
            (bool ongoing, bool unsettled) = hasDisputes(i);
            if (unsettled || (!ongoing && block.timestamp > a.disputePeriodEnd)) {
                return true;
            }
        }

        return false;
    }

    // ongoing, unsettled
    function hasDisputes(uint256 actionId) private view returns (bool, bool) {
        Dispute[] memory actionDisputes = disputes[actionId];
        bool ongoing = false;
        bool unsettled = false;
        for (uint256 i = 0; i < actionDisputes.length; i++) {
            if (actionDisputes[i].disputeEndDate > block.timestamp) {
                ongoing = true;
            } else if (!actionDisputes[i].settled) {
                unsettled = true;
            }
        }

        return (ongoing, unsettled);
    }

    function hasVoted(uint256 actionId, uint256 disputeId, address voter) public view returns (bool) {
        return votes[actionId][disputeId].voted[voter];
    }

    function getProofs(uint256 actionId) public view returns (Proof[] memory) {
        Proof[] memory actionProofs = proofs[actionId];
        Proof[] memory result = new Proof[](actionProofs.length);
        for (uint256 i = 0; i < actionProofs.length; i++) {
            Proof memory current = actionProofs[i];
            result[i].submitter = current.submitter;
            result[i].proof = current.proof;
            result[i].failed = current.failed;
        }

        return result;
    }

    function getDisputes(uint256 actionId) public view returns (Dispute[] memory) {
        Dispute[] memory actionDisputes = disputes[actionId];
        Dispute[] memory result = new Dispute[](actionDisputes.length);
        for (uint256 i = 0; i < actionDisputes.length; i++) {
            Dispute memory current = actionDisputes[i];
            result[i].creator = current.creator;
            result[i].proofIndex = current.proofIndex;
            result[i].disputeProof = current.disputeProof;
            result[i].disputeEndDate = current.disputeEndDate;
            result[i].settled = current.settled;
            result[i].forVotes = current.forVotes;
            result[i].againstVotes = current.againstVotes;
        }

        return result;
    }
}