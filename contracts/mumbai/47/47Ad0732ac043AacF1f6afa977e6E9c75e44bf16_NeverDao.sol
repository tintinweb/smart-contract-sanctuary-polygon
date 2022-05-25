// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface INever is IVotes {
    function totalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function balanceOf(address _holder) external view returns (uint256);
}

interface IRoyalty {
    function changeRecepient(address receiver) external;
}

contract NeverDao is Ownable {
    enum Stages {
        VOTE_END,
        PROPOSAL,
        VOTE_PERIOD,
        VOTE_COUNT
    }

    enum Result {
        PENDING,
        SUCCEED,
        REJECTED,
        PROJECT_POSTPONED
    }

    struct Choice {
        uint256 abstain;
        uint256 yay;
        uint256 nay;
        uint256 kill;
    }

    struct Proposal {
        address charityReceiver;
        bytes4 metadataBase;
        bytes32 digestHex;
        bool end;
        bool executed;
        bool isOldProposal;
    }

    Stages public stage;

    mapping(uint256 => Proposal) public proposal;
    mapping(uint256 => Choice) public choice;
    mapping(uint256 => uint256) public voteStart;
    mapping(uint256 => mapping(address => bool)) private hasVoted;
    mapping(address => bool) private rejected;
    mapping(uint256 => Result) private voteResults;
    mapping(uint256 => mapping(address => uint256)) private _delegate;
    mapping(uint256 => mapping(address => bool)) private hasDelegated;

    uint256 public contractStart;
    uint256[] private blocktime;
    uint256[] private pendingProps;
    uint256 public tresshold = 30;

    bytes4[2] public basesProps;
    bytes32[2] public baseHex;

    address public NAddress;
    address public royaltyReceiver;
    address public royaltyDistributor;
    address public holderDistributor;

    bool postponeProject;

    constructor(
        address _never,
        address _rec,
        address _holder,
        address _royaltySplitter,
        bytes4 baseStart,
        bytes4 baseEnd,
        bytes32 hexStart,
        bytes32 hexEnd
    ) {
        royaltyReceiver = _rec;
        NAddress = _never;
        holderDistributor = _holder;
        royaltyDistributor = _royaltySplitter;
        contractStart = block.timestamp;
        basesProps[0] = baseStart;
        basesProps[1] = baseEnd;
        baseHex[0] = hexStart;
        baseHex[1] = hexEnd;
        blocktime.push(block.number - 1);
    }

    function setRoyaltyPayment(address _payment) public onlyOwner {
        royaltyDistributor = _payment;
    }

    function currentVoteOwned(address _holder) public view returns (uint256) {
        INever token = INever(NAddress);
        return token.balanceOf(_holder);
    }

    function totalVotingUnit(uint256 _b) public view returns (uint256) {
        INever token = INever(NAddress);
        return token.getPastTotalSupply(_b);
    }

    function currentTotalSupply() public view returns (uint256) {
        INever token = INever(NAddress);
        return token.totalSupply();
    }

    function getBlockLength() public view returns (uint256) {
        return blocktime.length;
    }

    function getBlock() public view returns (uint256) {
        require(getBlockLength() > 0, "no block time");
        return blocktime[getBlockLength() - 1];
    }

    function getBlockBefore() public view returns (uint256) {
        require(getBlockLength() > 1, "no proposal submited");
        return blocktime[getBlockLength() - 2];
    }

    function voteOwned(address _account) public view returns (uint256) {
        INever token = INever(NAddress);

        uint256 len = getBlockLength();
        uint256 pastBlocks = getBlockBefore();
        if (len < 2) {
            return 0;
        } else {
            if (hasDelegated[pastBlocks][_account]) {
                return 0;
            } else {
                return
                    token.getPastVotes(_account, getBlock()) +
                    _delegate[pastBlocks][_account];
            }
        }
    }

    function delegateSubmit(address _to, uint256 _b) public {
        require(_to != _msgSender(), "you can't delegate yourself");
        require(_to != address(0));
        require(
            currentVoteOwned(_to) > 0,
            "Address you delegated are not the owner of NFT"
        );
        require(stage == Stages.PROPOSAL, "not on the right stage");
        require(
            !hasDelegated[_b][_msgSender()],
            "You already delegate your voting unit"
        );
        hasDelegated[_b][_msgSender()] = true;

        uint256 delegateOwned = _delegate[_b][_msgSender()];

        _delegate[_b][_msgSender()] = 0;
        _delegate[_b][_to] += currentVoteOwned(_msgSender()) + delegateOwned;
    }

    function getTotalDelegate(address holder, uint256 _b)
        public
        view
        returns (uint256)
    {
        return _delegate[_b][holder];
    }

    function ifDelegated(address _holder, uint256 _b)
        public
        view
        returns (bool)
    {
        return hasDelegated[_b][_holder];
    }

    function _req(uint256 a, uint256 b) private pure returns (uint256) {
        return (a * b) / 100;
    }

    function submitReq(address _account, uint256 _b)
        public
        view
        returns (bool)
    {
        uint256 supply = currentTotalSupply();
        uint256 tress = tresshold;
        uint256 min = _req((tress + 15), supply);
        uint256 max = _req((tress - 10), supply);
        uint256 _requirement = currentVoteOwned(_account) +
            _delegate[_b][_account];

        if (supply >= 5000) {
            if (_requirement >= max) {
                return true;
            } else {
                return false;
            }
        } else {
            if (_requirement >= min) {
                return true;
            } else {
                return false;
            }
        }
    }

    function proposalEntry(
        address _recepient,
        bytes4 _base,
        bytes32 _metadata
    ) public {
        require(stage == Stages.PROPOSAL, "not on right Stage");
        require(rejected[_recepient] == false, "Proposal already rejected");
        require(
            submitReq(_msgSender(), getBlock()) || _msgSender() == owner(),
            "You must have at least reached minimun amount"
        );

        uint256 total = currentTotalSupply();
        uint256 weight = currentVoteOwned(_msgSender()) +
            _delegate[getBlock()][_msgSender()];
        uint256 b = block.number - 1;

        blocktime.push(b);
        proposal[b] = Proposal(
            _recepient,
            _base,
            _metadata,
            false,
            false,
            false
        );

        hasVoted[b][_msgSender()] = true;
        choice[b] = Choice(total - weight, weight, 0, 0);
        voteStart[b] = block.timestamp;
        nextStage();
    }

    function pendingEntry(uint256 _blck) public {
        require(stage == Stages.PROPOSAL);
        uint256 pastBlock = pendingProps[_blck];
        require(!proposal[pastBlock].executed, "proposal already executed");

        uint256 b = block.number - 1;
        uint256 _b = getBlock();
        require(
            !hasDelegated[_b][_msgSender()],
            "You already delegate your voting unit"
        );
        require(block.timestamp > voteStart[_b] + 74);

        uint256 total = currentTotalSupply();
        uint256 weight = currentVoteOwned(_msgSender());
        address rec = proposal[pastBlock].charityReceiver;
        bytes4 _base = proposal[pastBlock].metadataBase;
        bytes32 _hex = proposal[pastBlock].digestHex;

        blocktime.push(b);
        hasVoted[b][_msgSender()] = true;
        proposal[b] = Proposal(rec, _base, _hex, false, false, true);
        choice[b] = Choice(0, weight, total - weight, 0);
        voteStart[b] = block.timestamp;
        nextStage();
    }

    function getPendingData() public view returns (uint256) {
        return pendingProps.length;
    }

    function nextStage() private {
        if (stage == Stages.VOTE_COUNT) {
            stage = Stages(0);
        } else {
            stage = Stages(uint8(stage) + 1);
        }
    }

    function vote(uint256 _vote) public {
        require(stage == Stages.VOTE_PERIOD, "not on the right stage!");
        uint256 b = getBlock();
        require(hasVoted[b][_msgSender()] == false, "You already voted!");
        require(_vote < 3);

        uint256 votes = voteOwned(_msgSender());
        require(votes > 0, "you dont have any vote");

        hasVoted[b][_msgSender()] = true;

        if (proposal[b].isOldProposal == true) {
            if (_vote == 1) {
                choice[b].nay = choice[b].nay - votes;
                choice[b].yay += votes;
            }
            if (_vote == 0) {
                choice[b].nay = choice[b].nay - votes;
                choice[b].abstain += votes;
            }
        } else {
            if (_vote == 1) {
                choice[b].abstain = choice[b].abstain - votes;
                choice[b].yay += votes;
            }
            if (_vote == 2) {
                choice[b].abstain = choice[b].abstain - votes;
                choice[b].nay += votes;
            }
        }
    }

    function isProjectKilled() external view returns (bool) {
        return postponeProject;
    }

    function receiveCharity() public view returns (address) {
        return royaltyReceiver;
    }

    function killProject() public {
        require(stage == Stages.VOTE_PERIOD, "not on the right stage!");
        require(voteEqualTotal(), "supply nft not equal to max supply");

        uint256 b = getBlock();
        uint256 votes = voteOwned(_msgSender());
        require(hasVoted[b][msg.sender] == false, "You already voted!");
        require(votes > 0, "you dont have any vote");

        hasVoted[b][msg.sender] = true;

        if (proposal[b].isOldProposal == true) {
            choice[b].nay = choice[b].nay - votes;
            choice[b].kill += votes;
        } else {
            choice[b].abstain = choice[b].abstain - votes;
            choice[b].kill += votes;
        }
    }

    function isQorumReached(uint256 _b) public view returns (bool) {
        uint256 total = choice[_b].abstain;
        uint256 yay = choice[_b].yay;
        uint256 nay = choice[_b].nay;
        uint256 kill = choice[_b].kill;
        uint256 qorum = (tresshold * total) / 100;

        return qorum > yay + nay + kill ? false : true;
    }

    function voteResult(uint256 _b) public view returns (Result) {
        return voteResults[_b];
    }

    function countVote(uint256 _b) public {
        require(!proposal[_b].end, "proposal has ended");
        require(stage == Stages.VOTE_PERIOD);
        require(block.timestamp > voteStart[_b] + 14);

        address reciever = proposal[_b].charityReceiver;
        proposal[_b].end = true;

        if (!isQorumReached(_b)) {
            if (voteResults[_b] != Result.PENDING) {
                voteResults[_b] = Result(0);
                nextStage();
            } else {
                nextStage();
            }
        } else {
            uint256 yay = choice[_b].yay;
            uint256 nay = choice[_b].nay;
            uint256 kill = choice[_b].kill;

            if (yay > nay) {
                voteResults[_b] = Result(1);
                setRoyaltyReceiver(reciever);
            }
            if (nay > yay) {
                voteResults[_b] = Result(2);
                rejected[reciever] = true;
            }
            if (kill > yay + nay) {
                voteResults[_b] = Result(3);
                setRoyaltyReceiver(holderDistributor);
            }
            nextStage();
        }
    }

    function execute(uint256 _b) public {
        require(stage == Stages.VOTE_COUNT);
        require(proposal[_b].end == true && proposal[_b].executed == false);

        if (!isQorumReached(_b)) {
            if (!proposal[_b].isOldProposal) {
                pendingProps.push(_b);
                nextStage();
            } else {
                nextStage();
            }
        } else {
            IRoyalty royal = IRoyalty(royaltyDistributor);

            if (voteResults[_b] == Result.SUCCEED) {
                postponeProject = false;
                proposal[_b].executed = true;
                basesProps[1] = proposal[_b].metadataBase;
                baseHex[1] = proposal[_b].digestHex;
                royal.changeRecepient(receiveCharity());
            }

            if (voteResults[_b] == Result.REJECTED) {
                proposal[_b].executed = true;
            }

            if (voteResults[_b] == Result.PROJECT_POSTPONED) {
                postponeProject = true;
                proposal[_b].executed = true;
                royal.changeRecepient(receiveCharity());
            }
            nextStage();
        }
    }

    function setRoyaltyReceiver(address _rec) private {
        royaltyReceiver = _rec;
    }

    function maximumVotingUnit() public view returns (uint256) {
        INever token = INever(NAddress);
        return token.maxSupply();
    }

    function voteEqualTotal() public view returns (bool) {
        uint256 current = currentTotalSupply();
        uint256 max = maximumVotingUnit();
        if (current >= max) {
            return true;
        } else {
            return false;
        }
    }

    function allPending() external view returns (uint256[] memory) {
        return pendingProps;
    }

    function allBlock() external view returns (uint256[] memory) {
        return blocktime;
    }

    function choiceId(uint256 _id) external view returns (Choice[] memory) {
        Choice[] memory prop = new Choice[](1);
        Choice storage _prop = choice[_id];
        prop[0] = _prop;
        return prop;
    }

    function stageProposal() public {
        require(stage == Stages.VOTE_END);
        uint256 b = getBlock();
        uint256 time = voteStart[b];
        if (time < 1) {
            require(block.timestamp > contractStart + 60);
        } else {
            require(block.timestamp > time + 60);
        }
        nextStage();
    }

    function totalPendingExecuted() public view returns (uint256) {
        uint256 len = blocktime.length;
        uint256 total;
        for (uint256 i = 0; i < len; i++) {
            if (proposal[i].executed && proposal[i].isOldProposal) {
                total += 1;
            }
        }
        return total;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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