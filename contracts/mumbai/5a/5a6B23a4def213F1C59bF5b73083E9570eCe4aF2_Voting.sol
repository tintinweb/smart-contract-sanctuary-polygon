// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting {

    // error messages
    error alreadyVoted();
    error notEnoughBalanceToCastVote();
    error notEnoughBalanceToCreateProposal();
    error justForTest();

    // state variables
    uint private proposalNotStarted = 0;
    uint private proposalInProgress = 1;
    uint private proposalPassed = 2;
    uint private proposalfailed = 3;
    uint private proposalDrawn = 4;
    uint public MIN_TOK_CREATEPROPOSAL;
    uint public MIN_TOK_VOTE;
    uint[] private allIds;
    uint public ascending = 1;
    uint public descending = 2;
    uint private generateVotingId = 0;

    struct proposalDetails {
        string title;
        string description;
        uint setQuorum;
        uint proposalId;
        uint timestamp;
        uint startDate;
        uint endDate;
    }

    struct proposalParams {
        string title;
        string description;
        uint setQuorum;
        uint startDate;
        uint endDate;
    }

    struct votersDecision {
        uint proposalId;
        bool voteStatus;
        uint timestamp;
    }

    struct forVotedData{
        address _add;
        uint _timeStamp;
        uint _balance;
    }

    struct againstVotedData{
        address _add;
        uint _timeStamp;
        uint _balance;
    }

    struct allProposals {
        proposalDetails ps;
        uint forVotes;
        uint againstVotes;
        uint status;
    }

    struct voteResult {
        string notStarted;
        string inprogress;
        string passed;
        string failed;
        string drawn;
    }

    mapping(uint => proposalDetails) private proposal;
    mapping(uint => mapping(address => votersDecision)) private voteState;
    mapping(uint => string) private titleDetails;
    mapping(uint => mapping(address => bool)) private userStatus;
    mapping(uint => uint) private votedFor;
    mapping(uint => uint) private votesAgainst;
    mapping(uint => uint) public totalVotes;
    mapping(uint => address[]) private votedYes;
    mapping(uint => address[]) private votedNo;
    mapping(uint => forVotedData[]) private onlyForVotes;
    mapping(uint => againstVotedData[]) private onlyAgainstVotes;

    event ProposalCreated(
        address indexed _ad,
        uint indexed _proposalId,
        string indexed _title
    );

    event Voted(
        address indexed _ad,
        uint indexed _proposalId,
        bool indexed _vote
    );

    constructor(uint _minTokCreateProposal, uint _minTokVoting) {
        MIN_TOK_CREATEPROPOSAL = _minTokCreateProposal * 10  ** decimals();
        MIN_TOK_VOTE = _minTokVoting * 10 ** decimals();
    }

    /**
     * createProposal
     * @param _data - title, description, setQuorum(Wei format), endDate(Unix format).
     * @dev - Check the requirement to create a proposal.
     * setQuorum is expected as whole value.
     * startDate and endDate - unix format.
     * proposalId is pushed to array.
     * function emits and event
     */
    function createProposal(proposalParams memory _data) external {
        if (
            msg.sender.balance <
            MIN_TOK_CREATEPROPOSAL
        ) {
            revert notEnoughBalanceToCastVote();
        }
        require(
            _data.setQuorum > 0 && _data.setQuorum < 100000000000000000000,
            " percentage value must be within 0 and 100"
        );
        generateVotingId = generateVotingId + 1;
        proposal[generateVotingId].proposalId = generateVotingId;
        // description data is hashed
        string memory local = string(abi.encodePacked(_data.description));
        proposal[generateVotingId].description = local;
        proposal[generateVotingId].title = _data.title;
        proposal[generateVotingId].setQuorum = _data.setQuorum; // geting value as wei
        proposal[generateVotingId].timestamp = block.timestamp;
        proposal[generateVotingId].startDate = _data.startDate;
        proposal[generateVotingId].endDate = _data.endDate;
        titleDetails[generateVotingId] = _data.title;
        allIds.push(generateVotingId);
        emit ProposalCreated(msg.sender, generateVotingId, _data.title);
    }

    /**
     * Total votes setup
     * create an mapping that specifiecs to an proposal id to get total votes.
     * mapping(uint => uint) private allVotesPerProposal
     * create an mapping that calculates sum of all for votes
     * mapping balance of user mapping(uint => uint) = id = msg.sender.balance++
     * 
     */
    struct weightedAvg{
        uint total_weight;  // total weight calc is completed
        uint sumOfFor;      // 
        uint sumOfAgainst;
        uint weightedAvgOfForVotes;
        uint weightedAvgOfAgainstVotes;
        uint totalFor;
        uint totalAgainst;
    }

    struct justVotes{
        uint forVotes;
        uint AgainstVotes;
    }

    mapping(uint => weightedAvg) private calculateWeightedAvg;
    mapping(uint => justVotes) private votesPerProposal;

    function VotePercentagePerProposal(uint _proposalId) external view returns (justVotes memory){
        return votesPerProposal[_proposalId];
    }

    /**
     * castVote
     * @param _decision - Enter either true or false.
     * @param _proposalId - Enter the proposal id.
     * @dev - Check the requirement to vote on proposal.
     * Check whether the user already voted.
     * Setting the voting period.
     * Getting the voter decision in bool format.
     * Returns totalVotes, voteState and userStatus.
     * Exceeded voting period.
     */
    function castVote(bool _decision, uint _proposalId) external {
        if (msg.sender.balance  < MIN_TOK_VOTE) {
            revert notEnoughBalanceToCastVote();
        }
        if (userStatus[_proposalId][msg.sender]) {
            revert alreadyVoted();
        }
        if (
            block.timestamp > proposal[_proposalId].startDate &&
            block.timestamp < proposal[_proposalId].endDate
        ) {
            if (_decision) {
                votedFor[_proposalId] = votedFor[_proposalId] + 1;
                voteState[_proposalId][msg.sender].voteStatus = true;
                voteState[_proposalId][msg.sender].timestamp = block.timestamp;
                onlyForVotes[_proposalId].push(forVotedData(msg.sender, block.timestamp, msg.sender.balance));
                votedYes[_proposalId].push(msg.sender);

                calculateWeightedAvg[_proposalId].total_weight += msg.sender.balance;
                calculateWeightedAvg[_proposalId].sumOfFor = msg.sender.balance;

                calculateWeightedAvg[_proposalId].weightedAvgOfForVotes = 
                calculateWeightedAvg[_proposalId].sumOfFor / calculateWeightedAvg[_proposalId].total_weight;

                votesPerProposal[_proposalId].forVotes = calculateWeightedAvg[_proposalId].weightedAvgOfForVotes;

                emit Voted(msg.sender, _proposalId, _decision);
            } else {
                votesAgainst[_proposalId] = votesAgainst[_proposalId] + 1;
                voteState[_proposalId][msg.sender].voteStatus = false;
                voteState[_proposalId][msg.sender].timestamp = block.timestamp;
                onlyAgainstVotes[_proposalId].push(againstVotedData(msg.sender, block.timestamp, msg.sender.balance));
                votedNo[_proposalId].push(msg.sender);

                calculateWeightedAvg[_proposalId].total_weight += msg.sender.balance;
                calculateWeightedAvg[_proposalId].sumOfAgainst = msg.sender.balance;

                calculateWeightedAvg[_proposalId].weightedAvgOfAgainstVotes = 
                calculateWeightedAvg[_proposalId].sumOfAgainst / calculateWeightedAvg[_proposalId].total_weight;

                votesPerProposal[_proposalId].AgainstVotes = calculateWeightedAvg[_proposalId].weightedAvgOfAgainstVotes;

                emit Voted(msg.sender, _proposalId, false);
            }
            totalVotes[_proposalId] = totalVotes[_proposalId] + 1;
            voteState[_proposalId][msg.sender].proposalId = _proposalId;
            userStatus[_proposalId][msg.sender] = true;
        } else {
            revert("Either voting is not started or already ended");
        }
    }

    /**
     * getProposalDetails
     * @param _proposalId - pass the proposalId.
     * Returns the proposal details.
     */
    function getProposalDetails(
        uint _proposalId
    )
        public
        view
        returns (
            proposalDetails memory details,
            uint totalVotesForProposal,
            address[] memory accepters,
            address[] memory rejecters
        )
    {
        return (
            proposal[_proposalId],
            totalVotes[_proposalId],
            votedYes[_proposalId],
            votedNo[_proposalId]
        );
    }

    /**
     * getVotingStatus
     * @param _voter - pass the voter wallet address.
     * @param _proposalId - Enter the proposalId.
     * Returns Voters details based on proposals.
     */
    function getVotingStatus(
        address _voter,
        uint _proposalId
    ) public view returns (votersDecision memory votingStatus) {
        return voteState[_proposalId][_voter];
    }

    /**
     * isUserVoted
     * @param _voter - Enter the voter wallet address.
     * @param _proposalId - Enter the proposalId.
     * Check whether the user already voted.
     */
    function isUserVoted(
        address _voter,
        uint _proposalId
    ) external view returns (bool status) {
        return userStatus[_proposalId][_voter];
    }

    /**
     * proposalResult
     * @param _proposalId - Enter the proposalId.
     * Returns the proposalResult based on given conditions.
     */
    function proposalResult(
        uint _proposalId
    ) public view returns (uint result) {
        if (block.timestamp < proposal[_proposalId].startDate) {
            return proposalNotStarted;
        } else if (block.timestamp < proposal[_proposalId].endDate) {
            return proposalInProgress;
        } else if (totalVotes[_proposalId] > 0) {
            /**
             * calculating the percentage of forVotes: (Sample)
             * If quorum = 40 %
             * consider totalVotes for a proposal is 10, how many forVotes needed for the proposal to succeed
             * we need 40% of forVotes to get the proposal succeed.
             * The below formula calculated the % of forVotes =>  5 (forVotes) * 100/ 10 (totalVotes) = 50% enough to make the proposal pass.
             * 50% (forVotes from totalVotes) > 40% (quorum)
             */
            uint percentage = ((votedFor[_proposalId] * (10 ** 18)) * (100 * (10 ** 18))) / (totalVotes[_proposalId] * (10 ** 18));
            if(percentage >= proposal[_proposalId].setQuorum){
                return proposalPassed;
            } else if (votedFor[_proposalId] == votesAgainst[_proposalId]) {
                return proposalDrawn;
            } else {
                return proposalfailed;
            }
        } else {
            return proposalfailed;
        }
    }
    
    /**
     * allProposalDetailsAscendingOrder
     * Returns the details of all proposal in ascending order.
     */
    function allProposalDetailsAscendingOrder()
        public
        view
        returns (allProposals[] memory proposals)
    {
        allProposals[] memory proposalss = new allProposals[](allIds.length);
        for (uint i = 0; i < allIds.length; i++) {
            allProposals memory proposalInfo;
            proposalInfo.ps = proposal[allIds[i]];
            proposalInfo.forVotes = votedFor[allIds[i]];
            proposalInfo.againstVotes = votesAgainst[allIds[i]];
            proposalInfo.status = proposalResult(allIds[i]);
            proposalss[i] = proposalInfo;
        }
        return proposalss;
    }

    /**
     * allProposalDetailsDescendingOrder
     * Returns the details of all proposal in decending order.
     */
    function allProposalDetailsDescendingOrder()
        public
        view
        returns (allProposals[] memory proposals)
    {
        allProposals[] memory proposalsList = new allProposals[](allIds.length);
        for (uint i = allIds.length; i > 0; i--) {
            allProposals memory proposalInfo;
            proposalInfo.ps = proposal[allIds[i - 1]];
            proposalInfo.forVotes = votedFor[allIds[i - 1]];
            proposalInfo.againstVotes = votesAgainst[allIds[i - 1]];
            proposalInfo.status = proposalResult(allIds[i - 1]);
            proposalsList[allIds.length - i] = proposalInfo;
        }
        return proposalsList;
    }

    /**
     * allProposalDetails
     * @param _sort - Enter "0" or "any" for descending order / Enter "1" for ascending order.
     * Returns the details of all proposals.
     */
    function allProposalDetails(uint _sort) 
    public 
    view 
    returns (allProposals[] memory proposals) {
        allProposals[] memory proposalsList = new allProposals[](allIds.length);
        if (_sort == 1) {
            for (uint i = 0; i < allIds.length; i++) {
                allProposals memory proposalInfo;
                proposalInfo.ps = proposal[allIds[i]];
                proposalInfo.forVotes = votedFor[allIds[i]];
                proposalInfo.againstVotes = votesAgainst[allIds[i]];
                proposalInfo.status = proposalResult(allIds[i]);
                proposalsList[i] = proposalInfo;
            }
        } else {
            for (uint i = allIds.length; i > 0; i--) {
                allProposals memory proposalInfo;
                proposalInfo.ps = proposal[allIds[i - 1]];
                proposalInfo.forVotes = votedFor[allIds[i - 1]];
                proposalInfo.againstVotes = votesAgainst[allIds[i - 1]];
                proposalInfo.status = proposalResult(allIds[i - 1]);
                proposalsList[allIds.length - i] = proposalInfo;
            }
        }
        return proposalsList;
    }

    /**
     * activeProposals
     * @param _sort - Enter "0" or "any" for descending order / Enter "1" for ascending order.
     * Returns the details of all active proposals.
     */
    function activeProposals(uint _sort) 
    public 
    view 
    returns (allProposals[] memory proposals) {
        uint count = 0;
        uint proposalCount = 0;
        uint time = block.timestamp;
        for (uint i = 0; i < allIds.length; i++) {
            if (time < proposal[allIds[i]].endDate) {
                count++;
            }
        }
        allProposals[] memory proposalsList = new allProposals[](count);
        if (_sort == 1) {
            for (uint i = 0; i < allIds.length; i++) {
                if (time < proposal[allIds[i]].endDate) {
                    allProposals memory proposalInfo;
                    proposalInfo.ps = proposal[allIds[i]];
                    proposalInfo.forVotes = votedFor[allIds[i]];
                    proposalInfo.againstVotes = votesAgainst[allIds[i]];
                    proposalInfo.status = proposalResult(allIds[i]);
                    proposalsList[proposalCount] = proposalInfo;
                    proposalCount++;
                }
            }
        } else {
            for (uint i = allIds.length; i > 0; i--) {
                if (time < proposal[allIds[i - 1]].endDate) {
                    allProposals memory proposalInfo;
                    proposalInfo.ps = proposal[allIds[i - 1]];
                    proposalInfo.forVotes = votedFor[allIds[i - 1]];
                    proposalInfo.againstVotes = votesAgainst[allIds[i - 1]];
                    proposalInfo.status = proposalResult(allIds[i - 1]);
                    proposalsList[proposalCount] = proposalInfo;
                    proposalCount++;
                }
            }
        }
        return proposalsList;
    }

    /**
     * completedProposals
     * @param _sort - Enter "0" or "any" for descending order / Enter "1" for ascending order.
     * Returns the details of all completed proposals.
     */
    function completedProposals(uint _sort) 
    public 
    view 
    returns (allProposals[] memory proposals){
        uint count = 0;
        uint proposalCount = 0;
        uint time = block.timestamp;
        for (uint i = 0; i < allIds.length; i++) {
            if (time > proposal[allIds[i]].endDate) {
                count++;
            }
        }
        allProposals[] memory proposalsList = new allProposals[](count);
        if (_sort == 1) {
            for (uint i = 0; i < allIds.length; i++) {
                if (time > proposal[allIds[i]].endDate) {
                    allProposals memory proposalInfo;
                    proposalInfo.ps = proposal[allIds[i]];
                    proposalInfo.forVotes = votedFor[allIds[i]];
                    proposalInfo.againstVotes = votesAgainst[allIds[i]];
                    proposalInfo.status = proposalResult(allIds[i]);
                    proposalsList[proposalCount] = proposalInfo;
                    proposalCount++;
                }
            }
        } else {
            for (uint i = allIds.length; i > 0; i--) {
                if (time > proposal[allIds[i - 1]].endDate) {
                    allProposals memory proposalInfo;
                    proposalInfo.ps = proposal[allIds[i - 1]];
                    proposalInfo.forVotes = votedFor[allIds[i - 1]];
                    proposalInfo.againstVotes = votesAgainst[allIds[i - 1]];
                    proposalInfo.status = proposalResult(allIds[i - 1]);
                    proposalsList[proposalCount] = proposalInfo;
                    proposalCount++;
                }
            }
        }
        return proposalsList;
    }

    /**
     * votingIdState
     * Returns the details of proposal status.
     */
    function votingIdState()
        external
        pure
        returns (voteResult memory showVotingResult)
    {
        voteResult memory vs;
        vs.notStarted = " 0 :: Not Started ";
        vs.inprogress = " 1 :: In Progress ";
        vs.passed = " 2 :: Passed ";
        vs.failed = " 3 :: Failed ";
        vs.drawn = " 4 :: Drawn ";
        return vs;
    }

    /**
     * returnAllForVoteDetails
     * @param _proposalId - Pass the proposalId of the contract.
     * @return onlyForVotes - array of struct is returned.
     */
    function returnAllForVoteDetails(uint _proposalId) external view returns(forVotedData[] memory){
        return onlyForVotes[_proposalId];
    }

    /**
     * returnAllAgainstVoteDetails
     * @param _proposalId - Pass the proposalId of the contract.
     * @return onlyAgainstVotes - array of struct is returned.
     */
    function returnAllAgainstVoteDetails(uint _proposalId) external view returns(againstVotedData[] memory){
        return onlyAgainstVotes[_proposalId];
    }

    function decimals() internal view virtual returns (uint8) {
        return 18;
    }

    function getNativeBalance(address account) public view returns (uint256) {
        return account.balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}