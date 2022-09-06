// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC20.sol";
import "./Events.sol";

contract CryptoLottery is ERC20, Events {
    uint256 public _round_interval;
    uint256 public _ticket_price;
    uint256 public _fee;
    uint256 public _fee_value;
    uint256 public _token_reward;
    uint256 public _purchased_tickets;
    uint256 public _purchased_free_tickets;
    uint256 public _all_eth_reward;
    uint256 private _secret_key;
    bool public __reward_2;

    address public _owner;

    enum RoundStatus {
        End,
        Start
    }

    mapping(uint256 => Ticket[]) private _tickets;
    mapping(address => TicketRef[]) private _tickets_ref;
    mapping(address => uint256) private _free_tickets;

    Round[] public _rounds;

    constructor(
        uint256 round_interval,
        uint256 ticket_price,
        uint256 fee
    ) ERC20("Crypto Lottery", "CL") {
        _round_interval = round_interval;
        _ticket_price = ticket_price;
        _fee = fee;
        _owner = msg.sender;
        __reward_2 = true;
    }

    struct Round {
        uint256 startTime;
        uint256 endTime;
        RoundStatus status;
        uint256[] win;
        uint256 number;
    }

    struct TicketRef {
        uint256 round;
        uint256 number;
    }

    struct Ticket {
        address owner;
        uint256[6] numbers;
        uint256 win_count;
        bool win_last_digit;
        uint256 eth_reward;
        uint256 token_reward;
        bool free_ticket;
        uint256 round;
        uint256 number;
        bool paid;
        uint256 time;
        uint256 tier;
    }

    function createRound() internal {
        if (
            _rounds.length > 0 &&
            _rounds[_rounds.length - 1].status != RoundStatus.End
        ) {
            revert("Error: the last round in progress");
        }

        uint256[] memory win;

        Round memory round = Round(
            block.timestamp,
            block.timestamp + _round_interval,
            RoundStatus.Start,
            win,
            _rounds.length
        );

        _rounds.push(round);

        _mint(msg.sender, 1000 * 10**18);

        _token_reward += 1000 * 10**18;
    }

    function buyTicket(uint256[6] memory _numbers) external payable {
        require(_ticket_price == msg.value, "not valid value");
        require(
            _rounds[_rounds.length - 1].status == RoundStatus.Start,
            "Error: the last round ended"
        );

        Ticket memory ticket = Ticket(
            msg.sender,
            _numbers,
            0,
            false,
            0,
            0,
            false,
            _rounds.length - 1,
            _tickets[_rounds.length - 1].length,
            false,
            block.timestamp,
            0
        );

        TicketRef memory ticket_ref = TicketRef(
            _rounds.length - 1,
            _tickets[_rounds.length - 1].length
        );

        _tickets[_rounds.length - 1].push(ticket);
        _tickets_ref[msg.sender].push(ticket_ref);

        _purchased_tickets += 1;
    }

    function buyFreeTicket(uint256[6] memory _numbers) external {
        require(_free_tickets[msg.sender] > 0, "You do not have a free ticket");
        require(
            _rounds[_rounds.length - 1].status == RoundStatus.Start,
            "Error: the last round ended"
        );

        Ticket memory ticket = Ticket(
            msg.sender,
            _numbers,
            0,
            false,
            0,
            0,
            false,
            _rounds.length - 1,
            _tickets[_rounds.length - 1].length,
            false,
            block.timestamp,
            0
        );

        TicketRef memory ticket_ref = TicketRef(
            _rounds.length - 1,
            _tickets[_rounds.length - 1].length
        );

        _tickets[_rounds.length - 1].push(ticket);
        _tickets_ref[msg.sender].push(ticket_ref);

        _free_tickets[msg.sender] -= 1;
        _purchased_free_tickets += 1;
    }

    function _random(uint256 key) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        key,
                        block.difficulty,
                        block.timestamp,
                        _tickets[_rounds.length - 1].length,
                        block.coinbase
                    )
                )
            );
    }

    function lastCombination() internal {
        if (_rounds[_rounds.length - 1].win.length == 0) {
            uint256[6] memory _cache;
            uint256 _num;

            for (uint256 i = 0; i < 6; i++) {
                if (i < 5) {
                    _secret_key += 1;
                    uint256 _number = _random(_secret_key) % 69;
                    _cache[i] = _number + 1;
                } else {
                    _secret_key += 1;
                    uint256 _number = _random(_secret_key) % 26;
                    _cache[i] = _number + 1;
                }
            }

            for (uint256 i = 0; i < _cache.length; i++) {
                for (uint256 z = 0; z < _cache.length; z++) {
                    if (_cache[i] == _cache[z]) {
                        _num += 1;
                    }
                }
            }

            if (_num > 6) {
                lastCombination();
            } else {
                _rounds[_rounds.length - 1].win = _cache;
            }
        } else {
            revert("Error: the win combination already exist");
        }
    }

    function closeRound() internal {
        if (_rounds[_rounds.length - 1].status == RoundStatus.End) {
            revert("The round end");
        }

        if (block.timestamp < _rounds[_rounds.length - 1].endTime) {
            revert("The round can't closed");
        }

        _rounds[_rounds.length - 1].status = RoundStatus.End;

        lastCombination();
    }
    
    function claimPay(uint256 round, uint256 number) internal {
        require(
            msg.sender == _tickets[round][number].owner,
            "You are not an owner"
        );
        require(
            _rounds[round].status == RoundStatus.End,
            "The Round is in process"
        );

        require(_tickets[round][number].paid == false, "The Ticket was paid");

        _tickets[round][number].paid = true;

        if (_tickets[round][number].free_ticket == true) {
            _free_tickets[_tickets[round][number].owner] += 1;
        }
        if (_tickets[round][number].eth_reward > 0) {
            payable(_tickets[round][number].owner).transfer(
                _tickets[round][number].eth_reward
            );
        }

        if (_tickets[round][number].token_reward > 0) {
            _mint(
                _tickets[round][number].owner,
                _tickets[round][number].token_reward
            );
        }

        emit ClaimTicketReward(
            _tickets[round][number].tier,
            _tickets[round][number].free_ticket,
            _tickets[round][number].token_reward,
            _tickets[round][number].eth_reward
        );
    }

    function getTicketWinNumbers(uint256 round, uint256 number) internal {
        
        require(_tickets[round][number].win_count == 0, "Win numbers already exist");

        uint256[] memory _numbers = _rounds[round].win;
        

        for (
            uint256 z = 0;
            z < _tickets[round][number].numbers.length;
            z++
        ) {
            for (uint256 y = 0; y < _numbers.length; y++) {
                if (_tickets[round][number].numbers[z] == _numbers[y]) {
                    _tickets[round][number].win_count += 1;

                    if (_numbers[y] == 6) {
                        _tickets[round][number].win_last_digit = true;
                    }
                }
            }
        }
    }

    function addTicketReward(uint round, uint number) internal {

      require(_tickets[round][number].token_reward == 0, "Token reward already exist");

      require(_tickets[round][number].eth_reward == 0, "Eth reward already exist");
        /* 
      0 - free ticket + 50 CL
      1 - free ticket + 100 CL
      
      0 + 1 - x2 + 2000 CL
      1 + 1 x2 + 2000 CL  
      2 - x2 + 2000 CL
      
      2 + 1 - x5 + 5000 CL
      3 - x10 + 10000 CL
      3 + 1 - x50  + 50000  CL
      4 + 0 - x100 + 100000 CL
       
      // jackpots
 
      4 + 1 - 2% of bank
      5 + 0 - 10% of bank
      5 + 1 - 30% of bank
 
     */

            if (_tickets[round][number].win_count == 0) {
                _tickets[round][number].token_reward = 50 * 10**18;
                _tickets[round][number].free_ticket = true;

                _token_reward += _tickets[round][number].token_reward;
                _tickets[round][number].tier = 1;
            }

            if (
                _tickets[round][number].win_count == 1 &&
                _tickets[round][number].win_last_digit == false &&
                __reward_2 == true
            ) {
                _tickets[round][number].free_ticket = true;
                _tickets[round][number].token_reward = 100 * 10**18;
                _token_reward += _tickets[round][number].token_reward;
                 _tickets[round][number].tier = 2;
            }

            if (
                _tickets[round][number].win_count == 1 &&
                _tickets[round][number].win_last_digit == true
            ) {
                _tickets[round][number].eth_reward = _ticket_price * 2;
                _tickets[round][number].token_reward = 2000 * 10**18;
                _token_reward += _tickets[round][number].token_reward;

                _fee_value += (_fee * (_ticket_price * 2)) / 100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 3;
            }

            if (
                _tickets[round][number].win_count == 2 &&
                _tickets[round][number].win_last_digit == false
            ) {
                _tickets[round][number].eth_reward = _ticket_price * 2;
                _tickets[round][number].token_reward = 2000 * 10**18;
                _token_reward += _tickets[round][number].token_reward;

                _fee_value += (_fee * (_ticket_price * 2)) / 100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 4;
            }

            if (
                _tickets[round][number].win_count == 2 &&
                _tickets[round][number].win_last_digit == true
            ) {
                _tickets[round][number].eth_reward = _ticket_price * 2;
                _tickets[round][number].token_reward = 2000 * 10**18;
                _token_reward += _tickets[round][number].token_reward;

                _fee_value += (_fee * (_ticket_price * 2)) / 100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 5;
            }

            if (
                _tickets[round][number].win_count == 3 &&
                _tickets[round][number].win_last_digit == true
            ) {
                _tickets[round][number].eth_reward = _ticket_price * 5;
                _tickets[round][number].token_reward = 5000 * 10**18;
                _token_reward += _tickets[round][number].token_reward;

                _fee_value += (_fee * (_ticket_price * 5)) / 100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 6;
            }

            if (
                _tickets[round][number].win_count == 3 &&
                _tickets[round][number].win_last_digit == false
            ) {
                _tickets[round][number].eth_reward = _ticket_price * 10;
                _tickets[round][number].token_reward = 10000 * 10**18;

                _token_reward += _tickets[round][number].token_reward;

                _fee_value += (_fee * (_ticket_price * 10)) / 100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 7;
            }

            if (
                _tickets[round][number].win_count == 4 &&
                _tickets[round][number].win_last_digit == true
            ) {
                _tickets[round][number].eth_reward = _ticket_price * 50;
                _tickets[round][number].token_reward = 50000 * 10**18;
                _token_reward += _tickets[round][number].token_reward;

                _fee_value += (_fee * (_ticket_price * 50)) / 100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 8;
            }

            if (
                _tickets[round][number].win_count == 4 &&
                _tickets[round][number].win_last_digit == false
            ) {
                _tickets[round][number].eth_reward =
                    _ticket_price *
                    100;
                _tickets[round][number].token_reward = 100000 * 10**18;

                _token_reward += _tickets[round][number].token_reward;

                _fee_value += ((_fee * (_ticket_price * 100)) / 100);

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 9;
            }

            if (
                _tickets[round][number].win_count == 5 &&
                _tickets[round][number].win_last_digit == true
            ) {
                _tickets[round][number].eth_reward =
                    (2 * address(this).balance) /
                    100;

                _fee_value +=
                    (_fee * _tickets[round][number].eth_reward) /
                    100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 10;
            }

            if (
                _tickets[round][number].win_count == 5 &&
                _tickets[round][number].win_last_digit == false
            ) {
                _tickets[round][number].eth_reward =
                    (10 * address(this).balance) /
                    100;

                _fee_value +=
                    (_fee * _tickets[round][number].eth_reward) /
                    100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 11;
            }

            if (
                _tickets[round][number].win_count == 6 &&
                _tickets[round][number].win_last_digit == true
            ) {
                _tickets[round][number].eth_reward =
                    (30 * address(this).balance) /
                    100;

                _fee_value +=
                    (_fee * _tickets[round][number].eth_reward) /
                    100;

                _all_eth_reward += _tickets[round][number].eth_reward;

                _tickets[round][number].tier = 12;
            }
        
    }

    function claimTicketReward (uint round, uint number) external {
        getTicketWinNumbers(round, number);
        addTicketReward(round, number);
        claimPay(round, number);
    }

    function claimOwnerReward() external {
        require(_owner == msg.sender, "you are not an owner");

        payable(_owner).transfer(_fee_value);

        _mint(_owner, _token_reward);

        _fee_value = 0;
        _token_reward = 0;
    }

    function getRoundsCount() external view returns (uint256) {
        return _rounds.length;
    }

    function getLastTicketsCount() external view returns (uint256) {
        return _tickets[_rounds.length - 1].length;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTicketRef(address user)
        external
        view
        returns (TicketRef[] memory ref)
    {
        TicketRef[] memory ref_ = new TicketRef[](_tickets_ref[user].length);

        for (uint256 i = 0; i < _tickets_ref[user].length; i++) {
            ref_[i] = _tickets_ref[user][i];
        }

        return ref_;
    }

    function getRoundById(uint256 id)
        external
        view
        returns (Round[] memory _round)
    {
        Round[] memory round = new Round[](1);
        round[0] = _rounds[id];
        return round;
    }

    function getLastRound() external view returns (Round[] memory _round) {
        Round[] memory round = new Round[](1);
        round[0] = _rounds[_rounds.length - 1];
        return round;
    }

    function getLastRounds(uint256 cursor, uint256 howMany)
        external
        view
        returns (
            Round[] memory rounds,
            uint256 newCursor,
            uint256 total
        )
    {
        uint256 length = howMany;
        uint256 _total = _rounds.length;
        if (length > _rounds.length - cursor) {
            length = _rounds.length - cursor;
        }

        Round[] memory _rounds_array = new Round[](_total);
        Round[] memory __array = new Round[](length);

        uint256 j = 0;

        for (uint256 i = _total; i >= 1; i--) {
            _rounds_array[j] = _rounds[i - 1];
            j++;
        }

        for (uint256 i = 0; i < length; i++) {
            __array[i] = _rounds_array[cursor + i];
        }

        return (__array, cursor + length, _total);
    }

    function getLastTickets(uint256 cursor, uint256 howMany)
        external
        view
        returns (
            Ticket[] memory tickets,
            uint256 newCursor,
            uint256 total
        )
    {
        uint256 length = howMany;
        uint256 _total = _tickets[_rounds.length - 1].length;
        if (length > _tickets[_rounds.length - 1].length - cursor) {
            length = _tickets[_rounds.length - 1].length - cursor;
        }

        Ticket[] memory ticket_array = new Ticket[](_total);
        Ticket[] memory __array = new Ticket[](length);

        uint256 j = 0;

        for (uint256 i = _total; i >= 1; i--) {
            ticket_array[j] = _tickets[_rounds.length - 1][i - 1];
            j++;
        }

        for (uint256 i = 0; i < length; i++) {
            __array[i] = ticket_array[cursor + i];
        }

        return (__array, cursor + length, _total);
    }

    function getUserTickets(
        address user,
        uint256 cursor,
        uint256 howMany
    )
        external
        view
        returns (
            Ticket[] memory tickets,
            uint256 newCursor,
            uint256 total
        )
    {
        uint256 length = howMany;
        uint256 _total = _tickets_ref[user].length;
        if (length > _tickets_ref[user].length - cursor) {
            length = _tickets_ref[user].length - cursor;
        }

        Ticket[] memory ticket_array = new Ticket[](_total);
        Ticket[] memory __array = new Ticket[](length);

        uint256 j = 0;

        for (uint256 i = _tickets_ref[user].length; i >= 1; i--) {
            ticket_array[j] = _tickets[_tickets_ref[user][i - 1].round][
                _tickets_ref[user][i - 1].number
            ];
            j++;
        }

        for (uint256 i = 0; i < length; i++) {
            __array[i] = ticket_array[cursor + i];
        }

        return (__array, cursor + length, _total);
    }

    function getUserFreeTicketsCount(address user)
        external
        view
        returns (uint256)
    {
        return _free_tickets[user];
    }

    function _switch_free_token_bonus(bool status) external {
        require(msg.sender == _owner, "You are not an owner");
        __reward_2 = status;
    }

    function _change_round_interval(uint256 interval) external {
        require(msg.sender == _owner, "You are not an owner");
        require(interval >= 1000, "Too short");
        _round_interval = interval;
    }

    function _change_ticket_price(uint256 price) external {
        require(msg.sender == _owner, "You are not an owner");
        require(price >= 1000, "Too short");
        _ticket_price = price;
    }

    function nextGame() external {
        if (_rounds.length > 0) {
            closeRound();
        }

        createRound();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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
pragma solidity 0.8.16;

contract Events {
  event ClaimTicketReward(uint tier, bool free_ticket, uint token_reward, uint eth_reward );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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