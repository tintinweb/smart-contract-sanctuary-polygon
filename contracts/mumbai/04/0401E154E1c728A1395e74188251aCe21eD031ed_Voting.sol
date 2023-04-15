// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Flexy is ERC20, Ownable {
    constructor() ERC20("Flexy", "FLX") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Import the IERC20 interface from an external Solidity file
import "./FlexyToken.sol";

contract Voting {
    // Define a token variable of type IERC20 to represent the token contract
    Flexy private token;
    uint256 public token_decimal;

    constructor(address _tokenAddress) {
        // Assign the token variable to an instance of the IERC20 contract at the specified address
        token = Flexy(_tokenAddress);
        token_decimal = token.decimals();
    }

    uint256 public proposalCounter;
    uint256 public proposalDeadlinePeriod = 5 days; //5 days period
    uint256 public distributePeriod = 30 days;
    uint256 public distributionPeriod = 375 days;

    struct Proposal {
        uint256 id;
        ProposalInfo proposalInfo;
        uint256 timestamp;
        bool pendingStatus;
        bool winningStatus;
        uint totalVote;
        uint256 approveCount;
        uint256 rejectCount;
        uint256 balance;
    }

    //Plan to remove this metadata on-chain
    struct ProposalInfo {
        address owner;
        string title;
        string description;
        string whitePaper;
        uint256 incentivePercentagePerMonth;
    }

    enum VoteOptionType {
        Approve,
        Reject
    }

    struct VotingState {
        uint256 proposalId;
        address[] voters;
    }

    struct Voter {
        address voter;
        uint256 voteRight;
        uint256[] proposal;
    }

    //map from voter address to list of proposal id
    mapping(address => uint[]) public voterProposals;

    //map from voter to proposal id to vote balance
    mapping(address => mapping(uint256 => uint256)) public voterToVoteBalance;

    //map from voter to proposal id to vote option
    mapping(address => mapping(uint256 => VoteOptionType))
        public voterToVoteOption;

    //map from voter to proposal id to each claim time stamp
    mapping(address => mapping(uint256 => uint256))
        public voterToClaimTimeStamp;

    //map from voter to proposl id to the claim status
    mapping(address => mapping(uint256 => bool)) public voterToClaimStatus;

    //map from proposal id to proposal struct
    mapping(uint => Proposal) public proposal;

    //map from proposalId to VotingState struct
    mapping(uint => VotingState) public votingState;

    //map from voter address to voter
    mapping(address => Voter) public voters;

    //map from proposal to voters state
    mapping(uint256 => mapping(address => bool)) public proposalToVoters;

    event ProposalEvent(
        uint indexed id,
        address owner,
        string title,
        string description,
        uint256 monthlyIncentive
    );

    event VoteEvent(
        uint256 indexed proposalId,
        address voter,
        string voteOption,
        string message
    );

    event WinningProposalEvent(
        uint256 indexed proposalId,
        bool winningStatus,
        string message
    );

    event TransferTokenForProposalRejection(
        uint256 indexed proposalId,
        address voters,
        uint256 totalTokenTransferred
    );

    event claimIncentiveEvent(address receiver, uint256 tokenAmount);

    modifier validateVoter(address voter, uint256 proposalId) {
        require(
            hasVoted(msg.sender, proposalId),
            "You have not voted on this proposal"
        );

        require(
            voterToVoteOption[msg.sender][proposalId] == VoteOptionType.Approve,
            // getVoterOptionByVoter(msg.sender, proposalId) == VoteOptionType.Approve,
            " Voter must vote approve"
        );
        require(
            voterToClaimStatus[msg.sender][proposalId] == false,
            // getVoterClaimStatus(msg.sender, proposalId) == false,
            "You have claimed this proposal"
        );
        _;
    }

    modifier voteDeadlineReach(uint256 proposalId, bool flag) {
        uint256 deadlinePeriodLeft = proposalVotingPeriod(proposalId);
        // If there is no time left, the deadline has been reached
        if (flag == true) {
            require(
                deadlinePeriodLeft == 0,
                "Proposal hasn't reached the deadline"
            );
        } else {
            require(
                deadlinePeriodLeft != 0,
                "Can't Vote, proposal had reached deadline"
            );
        }
        _;
    }

    modifier claimPeriodReached(uint256 proposalId, bool flag) {
        if (flag == true) {
            require(
                distrubutionDeadlinePeriod(proposalId) == 0,
                "Claim period reached"
            );
        } else {
            require(
                distrubutionDeadlinePeriod(proposalId) != 0,
                "Claim period hasn't reached yet"
            );
        }
        _;
    }

    modifier checkProposalStatus(uint256 proposalId) {
        require(
            getProposal(proposalId).winningStatus == true,
            "Proposal has been rejected!"
        );
        _;
    }

    function createProposal(
        string memory title,
        string memory description,
        string memory whitePaper,
        uint256 incentivePercentagePerMonth
    ) public {
        require(token.balanceOf(msg.sender) >= 100 * 10 ** token_decimal, "Must hold 100 tokens or more to create Proposal");
        require(incentivePercentagePerMonth >= 100,"Incentive must be greater than zero");

        ProposalInfo memory newProposalInfo = ProposalInfo({
            owner: msg.sender,
            title: title,
            description: description,
            whitePaper: whitePaper,
            incentivePercentagePerMonth: incentivePercentagePerMonth
        });

        Proposal memory newProposal = Proposal({
            id: proposalCounter++,
            proposalInfo: newProposalInfo,
            timestamp: block.timestamp,
            pendingStatus: true,
            winningStatus: false,
            totalVote: 0,
            approveCount: 0,
            rejectCount: 0,
            balance: 0
        });

        proposal[proposalCounter - 1] = newProposal;

        emit ProposalEvent(
            newProposal.id,
            msg.sender,
            title,
            description,
            incentivePercentagePerMonth
        );
    }

    //function to create and give rigth to voter
    function delegate(address to) public {
        require(msg.sender != address(0), "Address must exist");
        require(to != address(0), "Address must exist");
        Voter storage voter = voters[msg.sender];
        uint256 delegatorAddress = token.balanceOf(msg.sender);
        if (voter.voteRight == 0) {
            require(
                delegatorAddress >= 100,
                "Address must have at least 100 tokens"
            );
        } else {
            require(
                delegatorAddress >= (100 * voter.voteRight),
                "Address must have at least 100 tokens"
            );
        }
        voters[to].voter = to;
        voters[to].voteRight += 1;
    }

    function vote(
        uint256 proposalId,
        VoteOptionType voteOption,
        uint256 _tokenAmount
    ) public voteDeadlineReach(proposalId, false) {
        _tokenAmount *= (10 ** token_decimal);
        require(
            token.balanceOf(msg.sender) >= _tokenAmount,
            "Insufficient balance"
        );
        require(
            token.allowance(msg.sender, address(this)) >= _tokenAmount,
            "Token allowance not set"
        );

        Voter storage voter = voters[msg.sender];
        require(voter.voteRight >= 1, "You have no right to vote!!");

        Proposal storage prop = proposal[proposalId];
        require(
            getProposal(proposalId).proposalInfo.owner != address(0),
            "Proposal does not Exist"
        );

        require(
            !proposalToVoters[proposalId][msg.sender],
            "You have already voted for this proposal"
        );

        //set voter address to the proposal
        proposalToVoters[proposalId][msg.sender] = true;
        voter.voteRight--;
        prop.totalVote++;
        // addProposal(msg.sender, proposalId);
        voterProposals[msg.sender].push(proposalId);
        // addVoteBalance(msg.sender, proposalId, _tokenAmount);
        voterToVoteBalance[msg.sender][proposalId] = _tokenAmount;

        // addVoterOption(msg.sender, proposalId, voteOption);
        voterToVoteOption[msg.sender][proposalId] = voteOption;

        VotingState storage voting = votingState[proposalId];
        voting.proposalId = proposalId;
        voting.voters.push(msg.sender);

        voterToClaimTimeStamp[msg.sender][proposalId] = 0;

        //update proposal voting status
        if (voteOption == VoteOptionType.Approve) {
            prop.approveCount++;
        } else {
            prop.rejectCount++;
        }

        voter.proposal.push(proposalId);

        //transfer token only voter vote approve on the proposal
        if (voteOption == VoteOptionType.Approve) {
            prop.balance += _tokenAmount;
            // Transfer the specified amount of tokens from the sender to the contract
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            // Approve the voting contract (if it exists) to spend the transferred tokens
            if (address(this) != address(0)) {
                token.approve(msg.sender, _tokenAmount);
            }

            emit VoteEvent(
                proposalId,
                msg.sender,
                "Approve",
                "Vote successful"
            );
        } else {
            emit VoteEvent(proposalId, msg.sender, "Reject", "Vote successful");
        }
    }

    function declareWinningProposal(
        uint256 proposalId
    ) public voteDeadlineReach(proposalId, true) {
        //ensure that proposal owner put some collectural into this contract

        require(
            msg.sender == getProposal(proposalId).proposalInfo.owner,
            "You must be the owner of the proposal"
        );

        require(
            getProposal(proposalId).pendingStatus == true,
            "Proposal has already been evaluate"
        );

        require(
            getProposal(proposalId).totalVote != 0,
            "Proposal doesn't have any vote"
        );

        uint256 approveCount = getProposal(proposalId).approveCount;
        uint256 totalVote = getProposal(proposalId).totalVote;
        uint256 winningRate = (approveCount * 100) / totalVote;
        if (winningRate >= 50) {
            Proposal storage prop = proposal[proposalId];
            prop.pendingStatus = false;
            prop.winningStatus = true;
        } else {
            Proposal storage prop = proposal[proposalId];
            prop.pendingStatus = false;
            prop.winningStatus = false;
            //transfer all money back to voters
            transferRejectionCash(proposalId);
        }
        emit WinningProposalEvent(
            proposalId,
            getProposal(proposalId).winningStatus,
            "Proposal settled successfully"
        );
    }

    function hasVoted(
        address _voter,
        uint _proposalId
    ) public view returns (bool) {
        for (uint i = 0; i < voterProposals[_voter].length; i++) {
            if (voterProposals[_voter][i] == _proposalId) {
                return true;
            }
        }
        return false;
    }

    function claimVotingIncentive(
        uint256 proposalId
    )
        public
        validateVoter(msg.sender, proposalId)
        checkProposalStatus(proposalId)
        claimPeriodReached(proposalId, false)
    {
        uint256 transferredAmount = calculateIncentive(msg.sender, proposalId);

        sendingIncentive(msg.sender, transferredAmount);
        // addClaimTimeStamp(msg.sender, proposalId, block.timestamp);
        voterToClaimTimeStamp[msg.sender][proposalId] = block.timestamp;

        if (block.timestamp >= getProposal(proposalId).timestamp + 366 days) {
            voterToClaimStatus[msg.sender][proposalId] = true;
            // addVoterClaimStatus(msg.sender, proposalId, true);
        }
    }

    function calculateIncentive(
        address _voter,
        uint256 _proposalId
    ) internal view returns (uint256) {
        uint256 incentive = getProposal(_proposalId)
            .proposalInfo
            .incentivePercentagePerMonth;
        uint256 voteBalance = voterToVoteBalance[_voter][_proposalId];
        uint256 proposalTimeStamp = getProposal(_proposalId).timestamp + 5 days;
        uint256 lastClaimTimeStamp = voterToClaimTimeStamp[_voter][_proposalId];
        uint256 incentivePeriodInDay;
        uint256 incentiveAmount;
        require(block.timestamp < proposalTimeStamp + distributionPeriod,"Claim Period Reached");
        if (lastClaimTimeStamp == 0) {
            incentivePeriodInDay =
                (block.timestamp - proposalTimeStamp) /
                86400;
            //==== Formula incentive/30000 =====
            //divide by 100 as incentive is measured in BPS, 100 BPS = 1%
            //divide it by 100 to get the exact value from percentage
            //divide by 30 (days) to know interest rate per day
            incentiveAmount =
                (incentivePeriodInDay * incentive * (voteBalance)) /
                300000;
            return incentiveAmount;
        } else {
            incentivePeriodInDay =
                (block.timestamp - lastClaimTimeStamp) /
                86400;
            //==== Formula incentive/30000 =====
            //divide by 100 as incentive is measured in BPS, 100 BPS = 1%
            //divide it by 100 to get the exact value from percentage
            //divide by 30 (days) to know interest rate per day
            incentiveAmount =
                (incentivePeriodInDay * incentive * (voteBalance)) /
                300000;
            return incentiveAmount;
        }
    }

    function sendingIncentive(
        address receiver,
        uint256 transferAmount
    ) internal {
        token.transfer(receiver, transferAmount);
        emit claimIncentiveEvent(receiver, transferAmount);
    }

    function transferRejectionCash(uint256 proposalId) internal {
        address[] memory allVoters = getVotersByProposalId(proposalId);
        for (uint i = 0; i < allVoters.length; i++) {
            // if (voterState.votingOption[i] == VoteOptionType.Approve) {
            if (
                voterToVoteOption[allVoters[i]][proposalId] ==
                VoteOptionType.Approve
                // getVoterOptionByVoter(allVoters[i], proposalId) ==
                // VoteOptionType.Approve
            ) {
                uint256 balanceTransferred = voterToVoteBalance[allVoters[i]][
                    proposalId
                ];
                token.transfer(allVoters[i], balanceTransferred);
                emit TransferTokenForProposalRejection(
                    proposalId,
                    allVoters[i],
                    balanceTransferred
                );
            }
        }
    }

    function executeIncentive(uint256 proposalId)
        public
        validateVoter(msg.sender, proposalId)
        checkProposalStatus(proposalId)
        claimPeriodReached(proposalId, true)
    {
        require(msg.sender != address(0), "Address must be valid");

        uint256 incentive = getProposal(proposalId)
            .proposalInfo
            .incentivePercentagePerMonth;

        uint lastClaimTimeStamp = voterToClaimTimeStamp[msg.sender][proposalId];

        uint256 voteBalance = voterToVoteBalance[msg.sender][proposalId];

        uint256 oneYearPeriod = getProposal(proposalId).timestamp + 366 days;

        uint256 incentivePeriodInDay = (oneYearPeriod - lastClaimTimeStamp) /
            86400;

        //==== Formula incentive/30000 =====
        //divide by 100 as incentive is measured in BPS, 100 BPS = 1%
        //divide it by 100 to get the exact value from percentage
        //divide by 30 (days) to know interest rate per day
        uint256 incentiveAmount = (incentivePeriodInDay *
            incentive *
            (voteBalance)) / 300000;

        sendingIncentive(msg.sender, incentiveAmount);

        // addVoterClaimStatus(msg.sender, proposalId, true);
        voterToClaimStatus[msg.sender][proposalId] = true;
    }

    function proposalVotingPeriod(uint256 proposalId) public view returns (uint256) {
        // Proposal memory prop = proposal[proposalId];
        uint256 proposalTimeOut = proposal[proposalId].timestamp +
            proposalDeadlinePeriod;
        // Calculate the time left until the deadline
        if (block.timestamp >= proposalTimeOut) {
            return 0;
        } else {
            return proposalTimeOut - block.timestamp;
        }
    }

    function distrubutionDeadlinePeriod(uint256 proposalId) public view checkProposalStatus(proposalId) returns (uint256) {
        // require(prop.winningStatus == true, "Proposal has been rejected");
        uint256 claimPeriod = getProposal(proposalId).timestamp +
            (distributionPeriod) +
            5 days;

        if (block.timestamp >= claimPeriod) {
            return 0;
        } else {
            return claimPeriod - block.timestamp;
        }
    }

    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        return proposal[proposalId];
    }

    //for frontend looping purposes
    function getAllProposalsLength() public view returns (uint256) {
        return proposalCounter;
    }

    function getVotersByProposalId(uint256 proposalId) public view returns (address[] memory) {
        return votingState[proposalId].voters;
    }

}