// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC20.sol";

contract DAO is Context {
    mapping(address => bool) private _founders;
    string private _name;
    string private _description;
    ERC20 private _token;
    uint256 private _current_round;
    uint256 private _treasury_balance;

    /**
    * @dev Sets the values for {name} and {symbol} for the DAO and its token.
    * @param name the name of the DAO
    * @param symbol the symbol of the DAO's token
    */
    constructor(string memory name, string memory symbol, string memory description) {
        _founders[_msgSender()] = true;
        _name = name;
        _description = description;
        _token = new ERC20(name, symbol);
        _current_round = 0;
        _treasury_balance = 0;
    }

    // STRUCTS ---------------------------------------------------------------------------------------------------------

    struct Round {
        uint256 round_id;
        RoundStatus status;
        RoundTimeline timeline;
        string  name;
        string  description;
        uint256 valuation;
        uint256 round_size;
        uint256 left_to_raise;
        RoundVotes votes;
        RoundInvestments investments;
    }

    mapping(uint256 => Round) rounds_by_id;

    struct RoundTimeline {
        uint32  start_date;
        uint32  end_date;
    }

    struct RoundStatus {
        bool is_active;
        bool is_approved;
        bool is_complete;
    }

    struct RoundVotes {
        uint256 votes_for;
        uint256 votes_against;
        mapping(address => int256) vote_status;
    }

    struct RoundInvestments {
        address payable[] investors;
        mapping(address => uint256) investments;
    }

    // EVENTS ---------------------------------------------------------------------------------------------------------

    /**
    * @dev Event to be emitted when a round is created.
    */
    event RoundCreated(
        uint256 round_id,
        string name,
        string description,
        uint256 valuation,
        uint256 amount,
        uint256 start_date,
        uint256 end_date
    );

    /**
    * @dev Event to be emitted when a new vote is vast on a round.
    */
    event NewVote(
        uint256 round_id,
        address voter,
        bool is_for,
        uint256 votes_for,
        uint256 votes_against,
        bool is_approved
    );

    /**
    * @dev Event to be emitted when a new investment is made.
    */
    event NewInvestment(
        uint256 round_id,
        address backer,
        uint256 amount,
        uint256 left_to_raise,
        bool is_complete
    );

    /**
    * @dev Event to be emitted when a round is closed.
    */
    event RoundClosed(
        uint256 round_id,
        bool is_complete
    );

    /**
    * @dev Event to be emitted when someone withdraws their investment in a round.
    */
    event Withdrawal(
        address founder,
        uint256 amount,
        uint256 treasury_balance
    );


    // MODIFIERS -----------------------------------------------------------------------------------------------------

    /**
    * @dev Checks if the message sender is a founder of the DAO.
    */
    modifier onlyFounder() {
        require(_founders[_msgSender()], "Only founders can call this function.");
        _;
    }

    /**
    * @dev Checks that an address is listed as founder of the DAO.
    */
    modifier isFounder(address founder) {
        require(_founders[founder], "Founder doesn't exist.");
        _;
    }

    /**
    * @dev Checks that an address isn't aready listed as a founder of the DAO.
    * @param founder the address to check
    */
    modifier isNotFounder(address founder) {
        require(!_founders[founder], "Founder already exists.");
        _;
    }

    modifier noActiveRounds() {
        require(!rounds_by_id[_current_round].status.is_active, "There is already an active investment round.");
        _;
    }

    /**
    * @dev Checks that a round can be voted on.
    */
    modifier isVotable() {
        require(rounds_by_id[_current_round].status.is_active, "This round is no longer active.");
        require(!rounds_by_id[_current_round].status.is_approved, "This round has already been approved.");
        _;
    }

    /**
    * @dev Checks that a round is accepting investments.
    */
    modifier isAcceptingInvestments() {
        require(rounds_by_id[_current_round].status.is_active, "This round is no longer active.");
        require(rounds_by_id[_current_round].status.is_approved, "This round has not been approved yet.");
        require(!rounds_by_id[_current_round].status.is_complete, "This round has already been completed.");
        _;
    }

    /**
    * @dev Checks that the message sender has enough funds to invest {amount} in ETH.
    */
    modifier hasEnoughFundsToInvest(uint256 amount) {
        require(msg.value >= amount, "You don't have enough funds.");
        _;
    }

    /**
    * @dev Checks that their is enough funds to withdraw {amount} from the DAO.
    */
    modifier hasEnoughFundsToWithdraw(uint256 amount) {
        require(_treasury_balance >= amount, "The DAO doesn't have enough funds to withdraw.");
        _;
    }


    // FUNCTIONS -----------------------------------------------------------------------------------------------------

    /**
    * @dev Returns the name of the DAO.
    */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
    * @dev Returns the symbol of the DAO's token.
    */
    function symbol() public view returns (string memory) {
        return _token.symbol();
    }

    /**
    * @dev Returns the description of the DAO.
    */
    function description() public view returns (string memory) {
        return _description;
    }

    /**
    * @dev Returns the name of the current round.
    */
    function currentRoundName() public view returns (string memory) {
        return rounds_by_id[_current_round].name;
    }

    /**
    * @dev Returns the description of the current round.
    */
    function currentRoundDescription() public view returns (string memory) {
        return rounds_by_id[_current_round].description;
    }

    /**
    * @dev Returns the valuation of the current round.
    */
    function currentRoundValuation() public view returns (uint256) {
        return rounds_by_id[_current_round].valuation;
    }

    /**
    * @dev Adds a new founder to the {founders} map.
    * @param founder the address of the founder to add
    */
    function addFounder(address founder) public onlyFounder() isNotFounder(founder) {
        _founders[founder] = true;
    }

    /**
    * @dev Removes a founder from the {founders} map.
    * @param founder the address of the founder to remove
    */
    function removeFounder(address founder) public onlyFounder() isFounder(founder) {
        delete _founders[founder];
    }

    /**
    * @dev Proposes a new funding round for the DAO.
    * @param name the name of the round
    * @param description the description of the round
    * @param valuation the valuation of the round
    * @param amount the amount of tokens to be raised
    * @param start_date the start time of the round
    * @param end_date the end time of the round
    */
    function createRound(string memory name, string memory description, uint256 valuation, uint256 amount, uint32 start_date, uint32 end_date) public onlyFounder() noActiveRounds() {
        // Increment the next_round counter
        _current_round++;

        // Add a new round to the rounds_by_id mapping
        Round storage round = rounds_by_id[_current_round];
        round.round_id = _current_round;
        round.status.is_active = true;
        round.name = name;
        round.description = description;
        round.valuation = valuation;
        round.round_size = amount;
        round.left_to_raise = amount;
        round.timeline.start_date = start_date;
        round.timeline.end_date = end_date;
        round.votes.votes_for = 0;
        round.votes.votes_against = 0;
        round.status.is_approved = false;
        round.investments.investors = new address payable[](0);
        round.status.is_complete = false;

        // Emit the RoundCreated event
        emit RoundCreated(_current_round, round.name, round.description, round.valuation, amount, round.timeline.start_date, round.timeline.end_date);
    }

    /**
    * @dev Allows a founder or backer to vote on a round by adding the number of tokens they hold to {votes_for} or {votes_against}.
    * @param vote the vote to cast (true for for, false for against)
    */
    function voteOnRound(bool vote) public isVotable(){
        // Find out how many votes the sender has.
        uint256 number_of_votes = _token.balanceOf(_msgSender());
        require(number_of_votes > 0, "You must have at least one token to vote.");

        // Get the round
        Round storage round = rounds_by_id[_current_round];

        // Reset the users voting status if they're voting again
        if (round.votes.vote_status[_msgSender()] > 0) {
            round.votes.votes_for -= uint256(round.votes.vote_status[_msgSender()]);
        } else if (round.votes.vote_status[_msgSender()] < 0) {
            round.votes.votes_against -= uint256(round.votes.vote_status[_msgSender()]);
        }

        // Register the users new voting status
        if (vote) {
            round.votes.votes_for = number_of_votes;
            round.votes.vote_status[_msgSender()] = int256(number_of_votes);
        } else {
            round.votes.votes_against = number_of_votes;
            round.votes.vote_status[_msgSender()] = -int256(number_of_votes);
        }

        // Update the approval status of the round
        _update_approval();


        // Emit the NewVote event
        emit NewVote(
            _current_round,
            _msgSender(),
            vote,
            round.votes.votes_for,
            round.votes.votes_against,
            round.status.is_approved
        );
    }

    /**
    * @dev Allows someone to invest in a round.
    * @param amount the amount of ETH to invest
    *
    * NOTE: {amount} is implicitly transferred to the DAO contract.
    */
    function invest(uint256 amount) public payable isAcceptingInvestments() hasEnoughFundsToInvest(amount) {
        // Get the round
        Round storage round = rounds_by_id[_current_round];

        // If the the amount is larger than the amount left to raise, return the difference
        if (amount > round.left_to_raise) {
            amount = round.left_to_raise;
            payable(address(this)).transfer(amount - round.left_to_raise);
        }

        // Update the round
        round.left_to_raise -= amount;
        round.investments.investors.push(payable(_msgSender()));
        round.investments.investments[_msgSender()] = amount;

        // Update the completion status of the round
        _update_completion();

        // Emit the NewInvestment event
        emit NewInvestment(
            _current_round,
            _msgSender(),
            amount,
            round.left_to_raise,
            round.status.is_complete
        );
    }

    /**
    * @dev Allows a founder to withdraw {amount} from the DAO's treasury.
    * @param amount the amount of ETH to withdraw
    */
    function withdraw(uint256 amount) public onlyFounder() hasEnoughFundsToWithdraw(amount){
        // Transfer the amount to the sender
        payable(address(this)).transfer(amount);

        // Update {treasury balance}
        _treasury_balance -= amount;

        // Emit the Withdrawal event
        emit Withdrawal(
            _msgSender(),
            amount,
            _treasury_balance
        );
    }


    /**
    * @dev Updates the approval status of the current round.
    */
    function _update_approval() private {
        Round storage round = rounds_by_id[_current_round];
        uint256 votes_for_decision = _token.totalSupply() / 2;
        if (round.votes.votes_for > votes_for_decision) {
            round.status.is_approved = true;
        } else if (round.votes.votes_against > votes_for_decision) {
            round.status.is_active = false;
        }
    }

    /**
    * @dev Updates the completion status of a round.
    */
    function _update_completion() private {
        Round storage round = rounds_by_id[_current_round];
        if (round.left_to_raise == 0) {
            round.status.is_complete = true;
            _complete_mint();
            _treasury_balance += round.round_size;
        } else if (round.left_to_raise > 0 && round.timeline.end_date > block.timestamp) {
            round.status.is_active = false;
            _return_funds();
        }
    }

    /**
    * @dev Mints tokens when a round is complete.
    */
    function _complete_mint() private {
        Round storage round = rounds_by_id[_current_round];
        uint256 share_price = _share_price();
        for (uint256 i = 0; i < round.investments.investors.length; i++) {
            address investor = round.investments.investors[i];
            uint256 investment = round.investments.investments[investor];
            uint256 tokens_awarded = investment / share_price;
            _token.mint(investor, tokens_awarded);
        }

        emit RoundClosed(_current_round, true);
    }

    /**
    * @dev Returns the share price of the current round.
    */
    function _share_price() private view returns (uint256) {
        Round storage round = rounds_by_id[_current_round];
        return round.valuation / _token.totalSupply();
    }

    /**
    * @dev Returns the funds raised in a failed round.
    */
    function _return_funds() private {
        Round storage round = rounds_by_id[_current_round];
        for (uint256 i = 0; i < round.investments.investors.length; i++) {
            address payable investor = round.investments.investors[i];
            uint256 investment = round.investments.investments[investor];
            investor.transfer(investment);
        }

        emit RoundClosed(_current_round, false);
    }
}

// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.15;

import "./utils/Context.sol";
import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "./extensions/IERC20InvestmentRounds.sol";

contract ERC20 is Context, IERC20, IERC20Metadata, IERC20InvestmentRounds {
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
    * @dev Function to mint tokens to a given address.
    */
    function mint(address to, uint256 amount) public {
        require(amount > 0, "ERC20: mint amount must be greater than 0");
        require(to != address(0), "ERC20: mint to address cannot be the zero address");
        _mint(to, amount);
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
// Adapted from: OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.15;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for holding investment rounds with an ERC20 token.
 *
 * _Available since v4.1._
 */
interface IERC20InvestmentRounds is IERC20 {
    /**
    * @dev Mints and transfers tokens to a specified address.
    */
    function mint(address _to, uint256 _amount) external;
}