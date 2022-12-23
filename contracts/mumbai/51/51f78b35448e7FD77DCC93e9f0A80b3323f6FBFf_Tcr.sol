/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.2.0/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.2.0/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.2.0/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.2;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

// File: contracts/TestTcr.sol



pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;



contract Tcr {

    using SafeMath for uint;

    struct Listing {
        uint applicationExpiry; // Expiration date of apply stage
        bool whitelisted;       // Indicates registry status
        address owner;          // Owner of Listing
        uint deposit;           // Number of tokens in the listing
        uint challengeId;       // the challenge id of the current challenge
        string data;            // name of listing (for UI)
        uint arrIndex;          // arrayIndex of listing in listingNames array (for deletion)
    }

    // instead of using the elegant PLCR voting, we are using just a list because this is *simple-TCR*
    struct Vote {
        bool value;
        uint stake;
        bool claimed;
    }

    struct Poll {
        uint votesFor;
        uint votesAgainst;
        uint commitEndDate;
        bool passed;
        mapping(address => Vote) votes; // revealed by default; no partial locking
    }

    struct Challenge {
        address challenger;     // Owner of Challenge
        bool resolved;          // Indication of if challenge is resolved
        uint stake;             // Number of tokens at stake for either party during challenge
        uint rewardPool;        // number of tokens from losing side - winning reward
        uint totalTokens;       // number of tokens from winning side - to be returned
    }

    // Maps challengeIDs to associated challenge data
    mapping(uint => Challenge) private challenges;

    // Maps listingHashes to associated listingHash data
    mapping(bytes32 => Listing) private listings;
    string[] public listingNames;

    // Maps polls to associated challenge
    mapping(uint => Poll) private polls;

    // Global Variables
    ERC20 public token;
    string public name;
    uint public minDeposit;
    uint public applyStageLen;
    uint public commitStageLen;

    uint constant private INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    // Events
    event _Application(bytes32 indexed listingHash, uint deposit, string data, address indexed applicant);
    event _Challenge(bytes32 indexed listingHash, uint challengeId, address indexed challenger);
    event _Vote(bytes32 indexed listingHash, uint challengeId, address indexed voter);
    event _ResolveChallenge(bytes32 indexed listingHash, uint challengeId, address indexed resolver);
    event _RewardClaimed(uint indexed challengeId, uint reward, address indexed voter);

    // using the constructor to initialize the TCR parameters
    // again, to keep it simple, skipping the Parameterizer and ParameterizerFactory
    constructor(
        string memory _name,
        address _token,
        uint[] memory _parameters
    ) public {
        require(_token != address(0), "Token address should not be 0 address.");

        token = ERC20(_token);
        name = _name;

        // minimum deposit for listing to be whitelisted
        minDeposit = _parameters[0];

        // period over which applicants wait to be whitelisted
        applyStageLen = _parameters[1];

        // length of commit period for voting
        commitStageLen = _parameters[2];

        // Initialize the poll nonce
        pollNonce = INITIAL_POLL_NONCE;
    }

    // returns whether a listing is already whitelisted
    function isWhitelisted(bytes32 _listingHash) public view returns (bool whitelisted) {
        return listings[_listingHash].whitelisted;
    }

    // returns if a listing is in apply stage
    function appWasMade(bytes32 _listingHash) public view returns (bool exists) {
        return listings[_listingHash].applicationExpiry > 0;
    }

    // get all listing names (for UI)
    // not to be used in a production use case
    function getAllListings() public view returns (string[] memory) {
        string[] memory listingArr = new string[](listingNames.length);
        for (uint256 i = 0; i < listingNames.length; i++) {
            listingArr[i] = listingNames[i];
        }
        return listingArr;
    }

    // get details of this registry (for UI)
    function getDetails() public view returns (string memory, address, uint, uint, uint) {
        string memory _name = name;
        return (_name, address(token), minDeposit, applyStageLen, commitStageLen);
    }

    // get details of a listing (for UI)
    function getListingDetails(bytes32 _listingHash) public view returns (bool, address, uint, uint, string memory) {
        Listing memory listingIns = listings[_listingHash];

        // Listing must be in apply stage or already on the whitelist
        require(appWasMade(_listingHash) || listingIns.whitelisted, "Listing does not exist.");

        return (listingIns.whitelisted, listingIns.owner, listingIns.deposit, listingIns.challengeId, listingIns.data);
    }

    // proposes a listing to be whitelisted
    function propose(bytes32 _listingHash, uint _amount, string calldata _data) external {
        require(!isWhitelisted(_listingHash), "Listing is already whitelisted.");
        require(!appWasMade(_listingHash), "Listing is already in apply stage.");
        require(_amount >= minDeposit, "Not enough stake for application.");

        // Sets owner
        Listing storage listing = listings[_listingHash];
        listing.owner = msg.sender;
        listing.data = _data;
        listingNames.push(listing.data);
        listing.arrIndex = listingNames.length - 1;

        // Sets apply stage end time
        // now or block.timestamp is safe here (can live with ~15 sec approximation)
        /* solium-disable-next-line security/no-block-members */
        listing.applicationExpiry = now.add(applyStageLen);
        listing.deposit = _amount;

        // Transfer tokens from user
        require(token.transferFrom(listing.owner, address(this), _amount), "Token transfer failed.");

        emit _Application(_listingHash, _amount, _data, msg.sender);
    }

    // challenges a listing from being whitelisted
    function challenge(bytes32 _listingHash, uint _amount)
        external returns (uint challengeId) {
        Listing storage listing = listings[_listingHash];

        // Listing must be in apply stage or already on the whitelist
        require(appWasMade(_listingHash) || listing.whitelisted, "Listing does not exist.");
        
        // Prevent multiple challenges
        require(listing.challengeId == 0 || challenges[listing.challengeId].resolved, "Listing is already challenged.");

        // check if apply stage is active
        /* solium-disable-next-line security/no-block-members */
        require(listing.applicationExpiry > now, "Apply stage has passed.");

        // check if enough amount is staked for challenge
        require(_amount >= listing.deposit, "Not enough stake passed for challenge.");
        
        pollNonce = pollNonce + 1;
        challenges[pollNonce] = Challenge({
            challenger: msg.sender,
            stake: _amount,
            resolved: false,
            totalTokens: 0,
            rewardPool: 0
        });

        // create a new poll for the challenge
        polls[pollNonce] = Poll({
            votesFor: 0,
            votesAgainst: 0,
            passed: false,
            commitEndDate: now.add(commitStageLen) /* solium-disable-line security/no-block-members */
        });

        // Updates listingHash to store most recent challenge
        listing.challengeId = pollNonce;

        // Transfer tokens from challenger
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");

        emit _Challenge(_listingHash, pollNonce, msg.sender);
        return pollNonce;
    }

    // commits a vote for/against a listing
    // plcr voting is not being used here
    // to keep it simple, we just store the choice as a bool - true is for and false is against
    function vote(bytes32 _listingHash, uint _amount, bool _choice) public {
        Listing storage listing = listings[_listingHash];

        // Listing must be in apply stage or already on the whitelist
        require(appWasMade(_listingHash) || listing.whitelisted, "Listing does not exist.");

        // Check if listing is challenged
        require(listing.challengeId > 0 && !challenges[listing.challengeId].resolved, "Listing is not challenged.");

        Poll storage poll = polls[listing.challengeId];

        // check if commit stage is active
        /* solium-disable-next-line security/no-block-members */
        require(poll.commitEndDate > now, "Commit period has passed.");

        // Transfer tokens from voter
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");

        if(_choice) {
            poll.votesFor += _amount;
        } else {
            poll.votesAgainst += _amount;
        }

        // TODO: fix vote override when same person is voing again
        poll.votes[msg.sender] = Vote({
            value: _choice,
            stake: _amount,
            claimed: false
        });

        emit _Vote(_listingHash, listing.challengeId, msg.sender);
    }

    // check if the listing can be whitelisted
    function canBeWhitelisted(bytes32 _listingHash) public view returns (bool) {
        uint challengeId = listings[_listingHash].challengeId;

        // Ensures that the application was made,
        // the application period has ended,
        // the listingHash can be whitelisted,
        // and either: the challengeId == 0, or the challenge has been resolved.
        /* solium-disable */
        if (appWasMade(_listingHash) && 
            listings[_listingHash].applicationExpiry < now && 
            !isWhitelisted(_listingHash) &&
            (challengeId == 0 || challenges[challengeId].resolved == true)) {
            return true; 
        }

        return false;
    }

    // updates the status of a listing
    function updateStatus(bytes32 _listingHash) public {
        if (canBeWhitelisted(_listingHash)) {
            listings[_listingHash].whitelisted = true;
        } else {
            resolveChallenge(_listingHash);
        }
    }

    // ends a poll and returns if the poll passed or not
    function endPoll(uint challengeId) private returns (bool didPass) {
        require(polls[challengeId].commitEndDate > 0, "Poll does not exist.");
        Poll storage poll = polls[challengeId];

        // check if commit stage is active
        /* solium-disable-next-line security/no-block-members */
        require(poll.commitEndDate < now, "Commit period is active.");

        if (poll.votesFor >= poll.votesAgainst) {
            poll.passed = true;
        } else {
            poll.passed = false;
        }

        return poll.passed;
    }

    // resolves a challenge and calculates rewards
    function resolveChallenge(bytes32 _listingHash) private {
        // Check if listing is challenged
        Listing memory listing = listings[_listingHash];
        require(listing.challengeId > 0 && !challenges[listing.challengeId].resolved, "Listing is not challenged.");

        uint challengeId = listing.challengeId;

        // end the poll
        bool pollPassed = endPoll(challengeId);

        // updated challenge status
        challenges[challengeId].resolved = true;

        address challenger = challenges[challengeId].challenger;

        // Case: challenge failed
        if (pollPassed) {
            challenges[challengeId].totalTokens = polls[challengeId].votesFor;
            challenges[challengeId].rewardPool = challenges[challengeId].stake + polls[challengeId].votesAgainst;
            listings[_listingHash].whitelisted = true;
        } else { // Case: challenge succeeded
            // give back the challenge stake to the challenger
            require(token.transfer(challenger, challenges[challengeId].stake), "Challenge stake return failed.");
            challenges[challengeId].totalTokens = polls[challengeId].votesAgainst;
            challenges[challengeId].rewardPool = listing.deposit + polls[challengeId].votesFor;
            delete listings[_listingHash];
            delete listingNames[listing.arrIndex];
        }

        emit _ResolveChallenge(_listingHash, challengeId, msg.sender);
    }

    // claim rewards for a vote
    function claimRewards(uint challengeId) public {
        // check if challenge is resolved
        require(challenges[challengeId].resolved == true, "Challenge is not resolved.");
        
        Poll storage poll = polls[challengeId];
        Vote storage voteInstance = poll.votes[msg.sender];
        
        // check if vote reward is already claimed
        require(voteInstance.claimed == false, "Vote reward is already claimed.");

        // if winning party, calculate reward and transfer
        if((poll.passed && voteInstance.value) || (!poll.passed && !voteInstance.value)) {
            uint reward = (challenges[challengeId].rewardPool.div(challenges[challengeId].totalTokens)).mul(voteInstance.stake);
            uint total = voteInstance.stake.add(reward);
            require(token.transfer(msg.sender, total), "Voting reward transfer failed.");
            emit _RewardClaimed(challengeId, total, msg.sender);
        }

        voteInstance.claimed = true;
    }
}