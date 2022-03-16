/**
 *Submitted for verification at polygonscan.com on 2022-03-15
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/**
 * @title A simple smart contract which only records everyone’s voting on each proposal.
 */
contract PollVote {
    using SafeMath for uint256;

    // Meta data
    struct Meta {
        uint256 beginBlock;
        uint256 endBlock;
    }

    // Vote content
    enum Content { INVALID, FOR, AGAINST }

    // Min MCB rate of totalSupply for creating a new proposal
    uint256 public constant MIN_PROPOSAL_RATE = 10**16; // 1% according to https://github.com/mcdexio/documents/blob/master/en/Mai-Protocol-v3.pdf

    // Min voting period in blocks. 1 day for 15s/block
    uint256 public constant MIN_PERIOD = 5760;

    // MCB address
    uint256 public mcb;

    // All proposal meta data
    Meta[] public proposals;

    // Compatible with the old VoteBox
    uint256 public constant PROPOSAL_ID_OFFSET = 20;

    /**
     * @dev The new proposal is created
     */
    event Proposal(uint256 indexed id, string link, uint256 beginBlock, uint256 endBlock);

    /**
     * @dev Someone changes his/her vote on the proposal
     */
    event Vote(address indexed voter, uint256 indexed id, Content voteContent);

 
    /**
     * @dev    Accessor to the total number of proposal
     */
    function totalProposals()
        external view returns (uint256)
    {
        return proposals.length;
    }

    /**
     * @dev    Create a new proposal, need a proposal privilege
     * @param  link       The forum link of the proposal
     * @param  beginBlock Voting is enabled between [begin block, end block]
     * @param  endBlock   Voting is enabled between [begin block, end block]
     */
    function propose(string calldata link, uint256 beginBlock, uint256 endBlock)
        external
    {
       //  uint256 minProposalMCB = 100000;
        // require(mcb.balanceOf(msg.sender) >= minProposalMCB, "proposal privilege required");
        require(bytes(link).length > 0, "empty link");
        require(block.number <= beginBlock, "old proposal");
        require(beginBlock.add(MIN_PERIOD) <= endBlock, "period is too short");
        proposals.push(Meta({
            beginBlock: beginBlock,
            endBlock: endBlock
        }));
        emit Proposal(proposals.length - 1, link, beginBlock, endBlock);
    }

    /**
     * @notice  Vote for/against the proposal with id
     * @param   id          Proposal id
     * @param   voteContent Vote content
     */
    function vote(uint256 id, Content voteContent)
        external
    {
        require(id < proposals.length, "invalid id");
        require(voteContent != Content.INVALID, "invalid content");
        require(proposals[id].beginBlock <= block.number, "< begin");
        require(block.number <= proposals[id].endBlock, "> end");
        emit Vote(msg.sender, id, voteContent);
    }
}