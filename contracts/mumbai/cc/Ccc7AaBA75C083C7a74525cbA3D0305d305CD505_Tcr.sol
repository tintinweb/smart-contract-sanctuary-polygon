/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/simple-tcr/TCR.sol


// Most of the code in this contract is derived from the generic TCR implementation from Mike Goldin and (the adChain) team
// This contract strips out most of the details and only keeps the basic TCR functionality (apply/propose, challenge, vote, resolve)
// Consider this to be the "hello world" for TCR implementation
// For real world usage, please refer to the generic TCR implementation
// https://github.com/skmgoldin/tcr

pragma solidity ^0.8.14;


contract Tcr {

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
    ) {
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
        listing.applicationExpiry = block.timestamp + applyStageLen;
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
        require(listing.applicationExpiry > block.timestamp, "Apply stage has passed.");

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
        Poll storage poll = polls[pollNonce];
        poll.votesFor = 0;
        poll.votesAgainst = 0;
        poll.passed = false;
        poll.commitEndDate = block.timestamp + commitStageLen;

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
        require(poll.commitEndDate > block.timestamp, "Commit period has passed.");

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
        if (appWasMade(_listingHash) && 
            listings[_listingHash].applicationExpiry < block.timestamp && 
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
        require(poll.commitEndDate < block.timestamp, "Commit period is active.");

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
            uint reward = (challenges[challengeId].rewardPool / challenges[challengeId].totalTokens) * voteInstance.stake;
            uint total = voteInstance.stake + reward;
            require(token.transfer(msg.sender, total), "Voting reward transfer failed.");
            emit _RewardClaimed(challengeId, total, msg.sender);
        }

        voteInstance.claimed = true;
    }
}