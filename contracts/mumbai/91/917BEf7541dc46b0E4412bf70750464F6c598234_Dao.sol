// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "./IERC20.sol";
import { IBlacklist } from "./interfaces/IBlacklist.sol";


contract Dao is Ownable, Pausable {
    IBlacklist public blacklist; // blacklist smart contract

    //  voting structure
    struct ProposalVote {
        uint againstVotes;                      //  number of tokens "against"
        uint forVotes;                          //  number of "for" tokens
        uint abstainVotes;                      //  number of "abstain" tokens
        mapping(address => bool) hasVoted;      //  address => voted (true/false)
        mapping(address => uint256) amountVote; //  address => amount tokens
        mapping(address => bool) unlockToken;   //  address => unlocked the tokens (true/false)
        
    }

    // voting structure
    struct Proposal {
        uint votingStarts;      //  start of voting
        uint votingEnds;        //  end of voting
        bool executed;          //  whether the proposal has been carried
        bool isCanceled;        //  whether the proposal has been completed
        address ownerVotes;     //  voting creator
    }

    // voting status
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Canceled }

    mapping(bytes32 => Proposal) public proposals;          // proposalId => Proposal
    mapping(bytes32 => ProposalVote) public proposalVotes;  // proposalId => ProposalVote

    IERC20 public token;                        // voting token
    uint256 public VOTING_DURATION = 86400;     // voting time in seconds

    event ProposalAdded(bytes32 proposalId);
    event Sweep(IERC20 token, address recepient);
    event UnlockVote (bytes32 proposalId, address msgSender);

    constructor(IERC20 _token, IBlacklist _blacklist) {
        token = _token;
        blacklist = _blacklist;
    }

    modifier isNotBlackListed {
        require(!blacklist.check(msg.sender), "You're on the blacklist");
        _;
    }


    function createProposal(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        string calldata _description
    ) external isNotBlackListed returns(bytes32) {

        require(token.balanceOf(msg.sender) > 0, "not enough tokens");

        bytes32 proposalId = generateProposalId(
            _to, _value, _func, _data, keccak256(bytes(_description))
        );

        require(proposals[proposalId].votingStarts == 0, "proposal already exists");

        proposals[proposalId] = Proposal({
            votingStarts: block.timestamp,
            votingEnds: block.timestamp + VOTING_DURATION,
            executed: false,
            isCanceled:false,
            ownerVotes: msg.sender
        });

        emit ProposalAdded(proposalId);

        return proposalId;
    }

    function execute(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        bytes32 _descriptionHash
    ) external onlyOwner returns(bytes memory) {

        // check owner vote
        bytes32 proposalId = generateProposalId(
            _to, _value, _func, _data, _descriptionHash
        );

        require(state(proposalId) == ProposalState.Succeeded, "invalid state");

        Proposal storage proposal = proposals[proposalId];

        proposal.executed = true;

        bytes memory data;
        if (bytes(_func).length > 0) {
            data = abi.encodePacked(
                bytes4(keccak256(bytes(_func))), _data
            );
        } else {
            data = _data;
        }

        (bool success, bytes memory resp) = _to.call{value: _value}(data);
        require(success, "tx failed");

        return resp;
    }

    function lockVote(bytes32 proposalId, uint8 voteType, uint256 amount) external isNotBlackListed {
        require(state(proposalId) == ProposalState.Active, "invalid state");
        token.transferFrom(msg.sender, address(this), amount);

        ProposalVote storage proposalVote = proposalVotes[proposalId];

        require(!proposalVote.hasVoted[msg.sender], "already voted");

        if(voteType == 0) {
            proposalVote.againstVotes += amount;
        } else if(voteType == 1) {
            proposalVote.forVotes += amount;
        } else {
            proposalVote.abstainVotes += amount;
        }

        proposalVote.hasVoted[msg.sender] = true;
        proposalVote.amountVote[msg.sender] = amount;
    }

    function unlockVote(bytes32 proposalId) external {
        ProposalState proposalState = state(proposalId);

        require(proposalState == ProposalState.Succeeded || 
                proposalState == ProposalState.Defeated || 
                proposalState == ProposalState.Executed ||
                proposalState == ProposalState.Canceled , "invalid state");

        ProposalVote storage proposalVote = proposalVotes[proposalId];
        require(proposalVote.unlockToken[msg.sender] == false, "Unlocked already");

        token.transfer(msg.sender, proposalVote.amountVote[msg.sender]);
        proposalVote.unlockToken[msg.sender] = true;

        emit UnlockVote(proposalId, msg.sender);
    }

    function cancelVote(bytes32 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.ownerVotes, "You're not the maker of the proposal");
        proposal.isCanceled = true;
    }

    function setDuration (uint256 duration) external onlyOwner {
        VOTING_DURATION = duration;
    }

    function getVote(bytes32 proposalId) public view returns (uint, uint, uint) {
        ProposalVote storage vote = proposalVotes[proposalId];
        return (vote.againstVotes, vote.forVotes, vote.abstainVotes);
    }


    function state(bytes32 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        ProposalVote storage proposalVote = proposalVotes[proposalId];

        require(proposal.votingStarts > 0, "proposal doesnt exist");

        if (proposal.isCanceled) {
            return ProposalState.Canceled;
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (block.timestamp < proposal.votingStarts) {
            return ProposalState.Pending;
        }

        if(block.timestamp >= proposal.votingStarts &&
            proposal.votingEnds > block.timestamp) {
            return ProposalState.Active;
        }

        if(proposalVote.forVotes > proposalVote.againstVotes) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }


    function generateProposalId(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        bytes32 _descriptionHash
    ) internal pure returns(bytes32) {
        return keccak256(abi.encode(
            _to, _value, _func, _data, _descriptionHash
        ));
    }


    function sweep(IERC20 tokenAddress, address recipient) external onlyOwner {
        uint256 amount = tokenAddress.balanceOf(address(this));
        tokenAddress.transfer(recipient, amount);

        emit Sweep(tokenAddress, recipient);
    }

     receive() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBlacklist {
    function addToBlacklist(address user) external;
    function removeFromBlacklist(address user) external;
    function check(address user) external view returns (bool);
}