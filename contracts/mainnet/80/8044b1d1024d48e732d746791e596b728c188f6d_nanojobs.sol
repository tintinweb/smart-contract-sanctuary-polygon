/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

// File: @openzeppelin/contracts/utils/Counters.sol


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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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

// File: nanojobs/nanojobs.sol

// contracts/GLDToken.sol

pragma solidity ^0.8.7;



contract nanojobs {
    event NanojobsPurchased(
        address indexed payer,
        uint256 usdAmount,
        uint256 tokenAmount
    );

    event NanojobsAdded(uint256 indexed idjob, address owner);

    event SolutionAdded(
        uint256 indexed idjob,
        uint256 indexed idsolution,
        address proponent
    );

    event SolutionClaimed(
        uint256 indexed idjob,
        uint256 indexed idsolution
    );

    event VoteProposalAdded(uint256 indexed idproposal, address owner);

    event NanojobsProcessProposal(
        address indexed payer,
        uint256 idx,
        uint256 proposalType,
        uint256 result
    );

    using Counters for Counters.Counter;
    Counters.Counter private _counter_jobs;
    Counters.Counter private _counter_proposals;

    mapping(uint256 => nanojobsProposal) public proposals;
    mapping(uint256 => NanoJobStruct) public jobs;

    mapping(uint256 => mapping(address => uint256)) private _votingpower;

    mapping(uint256 => mapping(address => bool)) private _jobWhitelisted;
    mapping(uint256 => conflictResolutorAddress) private _jobConflictResolutors;

    struct conflictResolutorAddress {
        mapping(address => bool) resolutors;
    }

    address public seller;
    uint256 public tokenSold;

    IERC20 public baseToken;
    IERC20 public usdToken;

    uint256 public currentExpires;

    uint256 public tokenPriceUsd;
    uint256 public minBuyVolume;
    uint256 public maxBuyVolume;

    uint256 public registerJobPrice;
    uint256 public registerJobUsdPrice;

    uint256 public registerJobMinStake;

    uint256 public addProposalMinStake;
    uint256 public voteProposalMinStake;

    uint256 public voteProposalsMinVotingPowerPercent;
    bool public useVotingPower;

    struct NanoJobStruct {
        uint256 timestamp;
        uint256 expires;
        uint256 jobtype;
        string jobdata;
        uint256 reward;
        uint256 paymenttype;
        uint256 maxsolutions;
        address owner;
        bool useWhitelist;
        bool useConflictResolution;
        NanoJobSolutionStruct[] solutions;
    }
    enum JobStatusEnum {
        WAITING,
        EXPIRED,
        CANCELED,
        COMPLETED
    }

    struct NanoJobSolutionStruct {
        uint256 timestamp;
        address proponent;
        string solution;
        uint256 solutionstatus;
    }
    enum SolutionStatusEnum {
        WAITING,
        REVIEWING,
        APPROVED,
        REWARDED
    }

    struct nanojobsProposal {
        uint256 timestamp;
        uint256 expires;
        address proponent;
        string title;
        string description;
        string ipfshash;
        uint256 proposalStatus;
        uint256 proposalType;
        uint256 proposalValue;
        uint256 proposalTask;
        uint256 timestamp_processed;
        nanojobsProposalVote[] votes;
    }

    enum nanojobsProposalTypeEnum {
        nothing,
        set_currentExpires,
        set_tokenPriceUsd,
        set_minBuyVolume,
        set_maxBuyVolume,
        set_registerJobPrice,
        set_updateJobPrice,
        set_cancelJobPrice,
        set_assumeJobPrice,
        set_completeJobPrice,
        set_registerJobUsdPrice,
        set_updateJobUsdPrice,
        set_cancelJobUsdPrice,
        set_assumeJobUsdPrice,
        set_completeJobUsdPrice,
        set_registerJobMinStake,
        set_assumeJobMinStake,
        set_completeJobMinStake,
        set_addProposalMinStake,
        set_voteProposalMinStake,
        set_voteProposalsMinVotingPowerPercent,
        set_useVotingPower,
        set_request_job_payment
    }
    enum nanojobsProposalStatusEnum {
        VOTING,
        COMPLETED,
        ABORTED
    }

    struct nanojobsProposalVote {
        uint256 timestamp;
        address voter;
        uint256 votepower;
        bool approved;
    }

    struct VoteStatus {
        uint256 vote_ok;
        uint256 vote_nok;
    }

    constructor(
        IERC20 _base_token,
        IERC20 _usd_payment_token,
        uint256 _tokenprice_usd,
        address _tokenSellerAddress
    ) {
        seller = _tokenSellerAddress;
        baseToken = _base_token;
        usdToken = _usd_payment_token;
        tokenPriceUsd = _tokenprice_usd;

        tokenSold = 0;

        currentExpires = 60; //60*24;

        minBuyVolume = 0;
        maxBuyVolume = 0;

        registerJobPrice = 0;

        registerJobUsdPrice = 0;

        registerJobMinStake = 0;

        addProposalMinStake = 0;
        voteProposalMinStake = 0;

        voteProposalsMinVotingPowerPercent = 10;
        useVotingPower = true;
    }

    function purchase(uint256 volume) public {
        require(volume >= minBuyVolume, "Sale: amount less than min");
        require(
            maxBuyVolume == 0 || volume <= maxBuyVolume,
            "Sale: amount greater than max"
        );
        uint256 sellerBalance = (IERC20(baseToken)).balanceOf(seller);
        require(volume > 0, "no volume");
        require(tokenPriceUsd > 0, "undefined USD price");
        require(
            volume <= sellerBalance,
            "seller address does not have enough tokens"
        );

        usdToken.transferFrom(
            msg.sender,
            seller,
            tokenPriceUsd * (volume / 1e18)
        );
        emit NanojobsPurchased(
            msg.sender,
            tokenPriceUsd * (volume / 1e18),
            volume
        );
        tokenSold += volume;
        baseToken.transferFrom(seller, msg.sender, volume);
    }

    function countProposals() public view returns (uint256) {
        return _counter_proposals.current();
    }

    function getProposal(uint256 idx)
        public
        view
        returns (nanojobsProposal memory)
    {
        return proposals[idx];
    }

    function addProposal(
        string memory title,
        string memory description,
        string memory ipfshash,
        uint256 propType,
        uint256 propValue,
        uint256 propTask
    ) public {
        require(
            (baseToken.balanceOf(msg.sender) >= addProposalMinStake),
            "not enough tokens in the wallet"
        );
        _counter_proposals.increment();
        proposals[_counter_proposals.current()].timestamp = block.timestamp;
        proposals[_counter_proposals.current()].proponent = msg.sender;
        proposals[_counter_proposals.current()].title = title;
        proposals[_counter_proposals.current()].description = description;
        proposals[_counter_proposals.current()].ipfshash = ipfshash;
        proposals[_counter_proposals.current()].proposalStatus = uint256(
            nanojobsProposalStatusEnum.VOTING
        );
        proposals[_counter_proposals.current()].proposalType = propType;
        proposals[_counter_proposals.current()].proposalValue = propValue;
        proposals[_counter_proposals.current()].expires =
            proposals[_counter_proposals.current()].timestamp +
            currentExpires;
        proposals[_counter_proposals.current()].timestamp_processed = 0;
        proposals[_counter_proposals.current()].proposalTask = propTask;

        emit VoteProposalAdded(_counter_proposals.current(), msg.sender);
    }

    function voteProposal(uint256 index, bool approved) public {
        uint256 vpower = baseToken.balanceOf(msg.sender);
        require(vpower > 0, "No voting power");
        require(
            vpower > voteProposalMinStake,
            "no voting power tokens in wallet"
        );
        if (_votingpower[index][msg.sender] > 0) {
            require(false, "address counted");
        } else {
            proposals[index].votes.push(
                nanojobsProposalVote(
                    block.timestamp,
                    msg.sender,
                    vpower,
                    approved
                )
            );
            _votingpower[index][msg.sender] = vpower;
        }
    }

    function getProposalVotingStatus(uint256 index, bool usingVotingPower)
        public
        view
        returns (VoteStatus memory)
    {
        VoteStatus memory stat;
        stat.vote_ok = 0;
        stat.vote_nok = 0;
        for (uint256 i = 0; i < proposals[index].votes.length; i++) {
            if (proposals[index].votes[i].approved) {
                if (usingVotingPower) {
                    stat.vote_ok += proposals[index].votes[i].votepower;
                } else {
                    stat.vote_ok += 1;
                }
            } else {
                if (usingVotingPower) {
                    stat.vote_nok += proposals[index].votes[i].votepower;
                } else {
                    stat.vote_nok += 1;
                }
            }
        }
        return stat;
    }

    function processProposal(uint256 index) public {
        require(block.timestamp >= proposals[index].expires, "not expired");
        require(proposals[index].proposalStatus == 0, "proposalStatus!=0");
        VoteStatus memory vstat = getProposalVotingStatus(
            index,
            useVotingPower
        );
        if (vstat.vote_ok > vstat.vote_nok) {
            proposals[index].proposalStatus = uint256(
                nanojobsProposalStatusEnum.COMPLETED
            );
            proposals[index].timestamp_processed = block.timestamp;

            if (
                proposals[index].proposalType !=
                uint256(nanojobsProposalTypeEnum.nothing)
            ) {
                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_currentExpires)
                ) {
                    currentExpires = proposals[index].proposalValue;
                }
                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_tokenPriceUsd)
                ) {
                    tokenPriceUsd = proposals[index].proposalValue;
                }
                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_minBuyVolume)
                ) {
                    minBuyVolume = proposals[index].proposalValue;
                }
                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_maxBuyVolume)
                ) {
                    maxBuyVolume = proposals[index].proposalValue;
                }
                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_registerJobPrice)
                ) {
                    registerJobPrice = proposals[index].proposalValue;
                }

                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_registerJobUsdPrice)
                ) {
                    registerJobUsdPrice = proposals[index].proposalValue;
                }

                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_registerJobMinStake)
                ) {
                    registerJobMinStake = proposals[index].proposalValue;
                }
                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_addProposalMinStake)
                ) {
                    addProposalMinStake = proposals[index].proposalValue;
                }
                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_voteProposalMinStake)
                ) {
                    voteProposalMinStake = proposals[index].proposalValue;
                }
                if (
                    proposals[index].proposalType ==
                    uint256(
                        nanojobsProposalTypeEnum
                            .set_voteProposalsMinVotingPowerPercent
                    )
                ) {
                    voteProposalsMinVotingPowerPercent = proposals[index]
                        .proposalValue;
                }
                if (
                    proposals[index].proposalType ==
                    uint256(nanojobsProposalTypeEnum.set_useVotingPower)
                ) {
                    if (proposals[index].proposalValue > 0) {
                        useVotingPower = true;
                    } else {
                        useVotingPower = false;
                    }
                }

                emit NanojobsProcessProposal(
                    msg.sender,
                    index,
                    proposals[index].proposalType,
                    uint256(nanojobsProposalStatusEnum.COMPLETED)
                );
            }
        } else {
            proposals[index].proposalStatus = uint256(
                nanojobsProposalStatusEnum.ABORTED
            );
            emit NanojobsProcessProposal(
                msg.sender,
                index,
                proposals[index].proposalType,
                uint256(nanojobsProposalStatusEnum.ABORTED)
            );
        }

        if (
            proposals[index].proposalType ==
            uint256(nanojobsProposalTypeEnum.set_request_job_payment)
        ) {
            if (
                jobs[proposals[index].proposalTask]
                    .solutions[proposals[index].proposalValue]
                    .solutionstatus == 5
            ) {
                if (vstat.vote_ok > vstat.vote_nok) {
                    jobs[proposals[index].proposalTask]
                        .solutions[proposals[index].proposalValue]
                        .solutionstatus = 3;

                    usdToken.transfer(
                        jobs[proposals[index].proposalTask]
                            .solutions[proposals[index].proposalValue]
                            .proponent,
                        jobs[proposals[index].proposalTask].reward
                    );
                    //pay
                } else {
                    jobs[proposals[index].proposalTask]
                        .solutions[proposals[index].proposalValue]
                        .solutionstatus = 6;
                    jobs[proposals[index].proposalTask].maxsolutions += 1;
                }
            }
        }
    }

    function setToNanojobWhitelist(
        uint256 index,
        address[] memory whitelist,
        bool inUse
    ) public {
        require(msg.sender == jobs[index].owner, "job owner only");
        require(whitelist.length > 0);
        jobs[index].useWhitelist = true;
        for (uint256 i = 0; i < whitelist.length; i++) {
            _jobWhitelisted[index][whitelist[i]] = inUse;
        }
    }

    function setToNanojobConflictResolutor(
        uint256 index,
        address[] memory conflictResolutor,
        bool inUse
    ) public {
        require(msg.sender == jobs[index].owner, "job owner only");
        require(conflictResolutor.length > 0);
        jobs[index].useConflictResolution = true;
        for (uint256 i = 0; i < conflictResolutor.length; i++) {
            _jobConflictResolutors[index].resolutors[
                conflictResolutor[i]
            ] = inUse;
        }
    }

    function disableNanojobConflictResolution(uint256 index) public {
        require(msg.sender == jobs[index].owner, "job owner only");
        jobs[index].useConflictResolution = false;
    }

    function disableNanojobWhitelist(uint256 index) public {
        require(msg.sender == jobs[index].owner, "job owner only");
        jobs[index].useWhitelist = false;
    }

    function addNanojob(
        uint256 jobtype,
        string memory jobdata,
        uint256 expires,
        uint256 reward,
        uint256 paymenttype,
        uint256 maxsolutions
    ) public returns (uint256) {
        require(maxsolutions > 0, "max solutions must be greater than 0");
        require(
            usdToken.balanceOf(msg.sender) >=
                registerJobUsdPrice + (reward * maxsolutions),
            "not enough usd tokens in the wallet"
        );
        require(
            usdToken.allowance(msg.sender, address(this)) >=
                registerJobUsdPrice + (reward * maxsolutions),
            "not enough usd tokens allowance in the wallet"
        );
        require(
            baseToken.balanceOf(msg.sender) >= registerJobPrice,
            "not enough tokens in the wallet"
        );
        require(
            baseToken.allowance(msg.sender, address(this)) >= registerJobPrice,
            "not enough tokens allowance in the wallet"
        );
        require(
            baseToken.balanceOf(msg.sender) >= registerJobMinStake,
            "not enough tokens staked in the wallet"
        );

        if (registerJobUsdPrice + (reward * maxsolutions) > 0) {
            usdToken.transferFrom(
                msg.sender,
                address(this),
                registerJobUsdPrice + (reward * maxsolutions)
            );
        }
        if (registerJobPrice > 0) {
            baseToken.transferFrom(msg.sender, address(this), registerJobPrice);
        }

        _counter_jobs.increment();
        jobs[_counter_jobs.current()].timestamp = block.timestamp;
        jobs[_counter_jobs.current()].expires = expires;
        jobs[_counter_jobs.current()].jobtype = jobtype;
        jobs[_counter_jobs.current()].jobdata = jobdata;
        jobs[_counter_jobs.current()].reward = reward;
        jobs[_counter_jobs.current()].owner = msg.sender;
        jobs[_counter_jobs.current()].paymenttype = paymenttype;
        jobs[_counter_jobs.current()].maxsolutions = maxsolutions;

        emit NanojobsAdded(_counter_jobs.current(), msg.sender);

        return _counter_jobs.current();
    }

    function getNanojob(uint256 index)
        public
        view
        returns (NanoJobStruct memory)
    {
        return jobs[index];
    }

    function countNanojobs() public view returns (uint256) {
        return _counter_jobs.current();
    }

    function addJobSolution(uint256 jobIndex, string memory solution) public {
        require(
            jobs[jobIndex].solutions.length < jobs[jobIndex].maxsolutions,
            "Max solutions for this job"
        );
        if (jobs[jobIndex].useWhitelist) {
            require(
                _jobWhitelisted[jobIndex][msg.sender],
                "You are not whitelisted for this job"
            );
        }

        uint256 solstat = 0;
        if (jobs[jobIndex].paymenttype == 1) {
            solstat = 2;
        }

        jobs[jobIndex].solutions.push(
            NanoJobSolutionStruct(
                block.timestamp,
                msg.sender,
                solution,
                solstat
            )
        );

        emit SolutionAdded(_counter_jobs.current(),jobs[jobIndex].solutions.length-1, msg.sender);
    }

    function claimJobReward(uint256 jobIndex, uint256 solutionIndex) public {
        require(
            jobs[jobIndex].solutions[solutionIndex].solutionstatus == 2,
            "not ready to claim"
        );
        require(
            jobs[jobIndex].solutions[solutionIndex].proponent == msg.sender,
            "not solution proponent"
        );

        usdToken.transfer(
            jobs[jobIndex].solutions[solutionIndex].proponent,
            jobs[jobIndex].reward
        );

        jobs[jobIndex].solutions[solutionIndex].solutionstatus = 3;
        emit SolutionClaimed(_counter_jobs.current(),jobs[jobIndex].solutions.length-1);
    }

    function setJobSolutionByIndex(
        uint256 jobIndex,
        uint256 solutionIndex,
        uint256 newState,
        uint256 newValue
    ) public {
        if (
            jobs[jobIndex].useConflictResolution &&
            msg.sender != jobs[jobIndex].owner
        ) {
            require(
                _jobConflictResolutors[jobIndex].resolutors[msg.sender],
                "You are not a conflict resolver for this job"
            );
        } else {
            require(msg.sender == jobs[jobIndex].owner, "job owner only");
        }

        //require(msg.sender == jobs[jobIndex].owner, "job owner only");
        require(
            jobs[jobIndex].solutions[solutionIndex].solutionstatus < 3,
            "invalid new state"
        );
        if (newState == 4) {
            require(
                newValue <= jobs[jobIndex].reward,
                "new value must be less than or equal job.reward"
            );

            usdToken.transfer(
                jobs[jobIndex].owner,
                jobs[jobIndex].reward - newValue
            );
            usdToken.transfer(
                jobs[jobIndex].solutions[solutionIndex].proponent,
                newValue
            );
            emit SolutionClaimed(jobIndex,solutionIndex);
        }
        if (newState == 3) {
            usdToken.transfer(
                jobs[jobIndex].solutions[solutionIndex].proponent,
                jobs[jobIndex].reward
            );
            emit SolutionClaimed(jobIndex,solutionIndex);
        }
        jobs[jobIndex].solutions[solutionIndex].solutionstatus = newState;
    }
}