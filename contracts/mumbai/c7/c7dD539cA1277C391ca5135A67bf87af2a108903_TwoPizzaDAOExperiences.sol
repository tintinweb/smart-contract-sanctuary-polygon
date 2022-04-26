/**
 *Submitted for verification at polygonscan.com on 2022-04-25
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

contract TwoPizzaDAOExperiences {
    address public tokenAddress;
    // Number times the contract has been used, used to calculate tracker trackerID
    uint256 public counter;
    // Everything about the tracker
    struct trackerData {
        // Basic parameters
        address owner;
        uint256 balance;
        uint256 votingPayout;
        // Counters
        uint256 upVote;
        uint256 downVote;
        uint256 oneStar;
        uint256 twoStar;
        uint256 threeStar;
        uint256 fourStar;
        uint256 fiveStar;
    }
    // Contains tracker parameters and counters
    mapping(bytes32 => trackerData) public trackers;
    // Voting database: tx hash: keccak256(sender+trackerId) => voting value
    mapping(bytes32 => bytes1) public votes;
    // Contains trackers associated to a user, for easy retrieval
    mapping(address => bytes32[]) public profile;
    // Contains trackers associated to a user, for easy retrieval
    mapping(address => uint256) public profileCounter;
    // Emited when a new vote is generated
    event voteEvent(trackerData indexed data, bytes32 indexed txid, bytes2 indexed txType);
    constructor () {
        tokenAddress = 0xAE43022521b2E5f4daf626D39A898330825b28E2;
    }
    function fundTracker(bytes32 trackerId, uint256 amount) public returns (bool result) {
        // make sure there is enough balance
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amount, "Not enough balance");
        // make sure there is enough allowance
        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
        // update tracker balance
        trackers[trackerId].balance += amount;
        // transfer to contract
        bool sent = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        require(sent, "Failed to send tokens");
        return sent;
    }
    function newTracker(uint256 votingPayout) public returns (bytes32 trackerId) {
        // Generate a new unique tracker ID based on the sender + counter
        trackerId = keccak256(abi.encode(msg.sender, ++counter));
        // Associate the new tracker with the sender
        trackers[trackerId].owner = msg.sender;
        // Set payout value
        trackers[trackerId].votingPayout = votingPayout;
        // Update the user profile, for easy access
        profile[msg.sender].push(trackerId);
        // Update the user profile, for easy access
        ++profileCounter[msg.sender];
        // Return tracker ID to the user
        return trackerId;
    }
    function vote(
        bytes32 trackerId,
        bytes1 txType
    ) public returns (bytes32 txhash) {
        // make sure the owner has enough balance left to pay voter
        require(trackers[trackerId].balance >= trackers[trackerId].votingPayout, "Not enough balance"); 
        // deduct balance
        trackers[trackerId].balance -= trackers[trackerId].votingPayout;
        // create new tx hash based on sender + tracker
        txhash = keccak256(abi.encode(msg.sender, trackerId));
        // check if user already voted
        require(votes[txhash] == 0x00 , "You can only vote once.");
        // store the tx hash and result
        votes[txhash] = txType;
        // Update counters
        if (txType == 0x01) {
            ++trackers[trackerId].oneStar;
        } else if (txType == 0x02) {
            ++trackers[trackerId].twoStar;
        } else if (txType == 0x03) {
            ++trackers[trackerId].threeStar;
        } else if (txType == 0x04) {
            ++trackers[trackerId].fourStar;
        } else if (txType == 0x05) {
            ++trackers[trackerId].fiveStar;
        } else if (txType == 0x06) {
            ++trackers[trackerId].upVote;
        } else if (txType == 0x07) {
            ++trackers[trackerId].downVote;
        }
        // Pay voter
        bool sent = IERC20(tokenAddress).transfer(msg.sender, trackers[trackerId].votingPayout);
        require(sent, "Failed to send tokens");
        // emit event
        emit voteEvent(trackers[trackerId], txhash, txType );
        // Return tx hash to the user
        return txhash;
    }
    function updateVotingPayout(
        bytes32 trackerId, 
        uint256 votingPayout 
    ) public {
         // Can only modify if you own the tracker
        require(msg.sender == trackers[trackerId].owner,  "You don't own that tracker.");
        // Update payouts
        trackers[trackerId].votingPayout = votingPayout;
    }
}