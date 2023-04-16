/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

contract Shishiodoshi {
    struct Bid {
        address bidder;
        uint8 amount;
    }

    struct GameInfo {
        address bidToken;
        uint256 bidIncrement;
        uint8 startingCoinAmount;
        uint8 playerCount;
        uint256 minimumDeposit; //in bidToken units bidIncrement*coinsNeeded
        bytes32 winningHash;
        address[] playerOrder;
        uint16 totalBid;
        uint16 turn;
        bool isEnded;
        Bid[] bidHistory;
    }

    address owner;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public supportedTokens;
    mapping(uint256 => GameInfo) public gameInfos;
    mapping(uint256 => mapping(address => uint8)) public gamePlayers; //controls the increment to decide who is next
    mapping(uint256 => mapping(address => uint8)) public gameBalances;

    uint256 public nextGameID = 0;
    uint8 public minCoin = 10;
    uint8 public maxCoin = 100;

    // Events
    event GameCreated(uint256 gameID);
    event GameInitialized(uint256 gameID, bytes32 winningHash);
    event GameStarted(uint256 gameID);
    event BidReceived(uint256 gameID);

    constructor(address _token) {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        supportedTokens[_token] = true;
    }

    // Admin Functions

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "NGMI");
        _;
    }

    function addAdmin(address _newAdmin) public onlyAdmin {
        isAdmin[_newAdmin] = true;
    }

    function removeAdmin(address _newAdmin) public onlyAdmin {
        isAdmin[_newAdmin] = false;
    }

    function addSupportedToken(address _token) public onlyAdmin {
        supportedTokens[_token] = true;
    }

    function removeSupportedToken(address _token) public onlyAdmin {
        supportedTokens[_token] = false;
    }

    function changeMin(uint8 _minCoin) public onlyAdmin {
        require(_minCoin < maxCoin, "Minimum coin amount larger than max");
        minCoin = _minCoin;
    }

    function changeMax(uint8 _maxCoin) public onlyAdmin {
        require(minCoin < _maxCoin, "Maximum coin amount smaller than min");
        maxCoin = _maxCoin;
    }

    function newGame(
        address _bidToken,
        uint256 _bidIncrement,
        uint8 _playerCount,
        uint8 _startingCoinAmount
    )
        public
        returns (uint256 currentGameID)
    {
        require(supportedTokens[_bidToken], "Token is not supported");
        require(minCoin <= _startingCoinAmount, "Starting coin is below limit");
        require(maxCoin >= _startingCoinAmount, "Starting coin is above limit");
        currentGameID = nextGameID;

        GameInfo storage game = gameInfos[currentGameID];
        game.bidToken = _bidToken;
        game.bidIncrement = _bidIncrement;
        game.playerCount = _playerCount;
        game.startingCoinAmount = _startingCoinAmount;
        game.minimumDeposit = _startingCoinAmount * _bidIncrement;

        nextGameID += 1;
        emit GameCreated(currentGameID);
    }

    function initGame(uint256 _gameID, bytes32 _winningHash) public onlyAdmin {
        GameInfo storage game = gameInfos[_gameID];
        require(game.winningHash == bytes32(0), "Game already initialized");
        game.winningHash = _winningHash;
        emit GameInitialized(_gameID, _winningHash);
    }

    function joinGame(uint256 _gameID) public {
        require(_gameID < nextGameID, "Game not yet created");
        GameInfo storage game = gameInfos[_gameID];
        require(game.winningHash != bytes32(0), "Game not initialized");
        require(gamePlayers[_gameID][msg.sender] == 0, "You already joined this game");
        require(game.playerOrder.length < game.playerCount, "Game full");

        ERC20(game.bidToken).transferFrom(msg.sender, address(this), game.minimumDeposit);
        game.playerOrder.push(msg.sender);
        gamePlayers[_gameID][msg.sender] = 1;
        gameBalances[_gameID][msg.sender] = game.startingCoinAmount;

        if (game.playerOrder.length == game.playerCount) {
            for (uint256 i = 0; i < game.playerOrder.length; i++) {
                uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (game.playerOrder.length - i);
                address temp = game.playerOrder[n];
                game.playerOrder[n] = game.playerOrder[i];
                game.playerOrder[i] = temp;
            }
            emit GameStarted(_gameID);
        }
    }

    function leaveGame(uint256 _gameID) public {
        require(_gameID < nextGameID, "Game not yet created");
        GameInfo storage game = gameInfos[_gameID];
        require(game.winningHash != bytes32(0), "Game not initialized");
        require(game.playerOrder.length != game.playerCount, "Cant leave game already started");
        require(gamePlayers[_gameID][msg.sender] == 1, "Not a player of this game");

        ERC20(game.bidToken).transfer(msg.sender, game.minimumDeposit);
        delete gamePlayers[_gameID][msg.sender];
        delete  gameBalances[_gameID][msg.sender];
        uint256 leavingPlayerIndex = 0;
        for (; leavingPlayerIndex < game.playerOrder.length; leavingPlayerIndex++) {
            if (game.playerOrder[leavingPlayerIndex] == msg.sender) {
                break;
            }
        }

        game.playerOrder[leavingPlayerIndex] = game.playerOrder[game.playerOrder.length - 1];
        game.playerOrder.pop();
    }

    function bidGame(uint256 _gameID, uint8 _tokenAmount) public {
        require(_gameID < nextGameID, "Game not yet created");
        GameInfo storage game = gameInfos[_gameID];
        require(game.winningHash != bytes32(0), "Game not initialized");
        require(game.playerOrder.length == game.playerCount, "Game not yet started");
        require(gameBalances[_gameID][msg.sender] >= _tokenAmount, "Not enough balance");

        uint256 playerIndex = game.turn % game.playerCount;
        require(game.playerOrder[playerIndex] == msg.sender, "Wrong turn");
        gameBalances[_gameID][msg.sender] -= _tokenAmount;
        game.totalBid += _tokenAmount;

        game.turn += gamePlayers[_gameID][msg.sender];

        if (gameBalances[_gameID][msg.sender] == 0) {
            uint8 currentStep = gamePlayers[_gameID][msg.sender];
            gamePlayers[_gameID][msg.sender] = 0;
            uint256 i = playerIndex - 1;
            // check from player before backwards
            for (; i >= 0; i--) {
                if (gameBalances[_gameID][game.playerOrder[i]] > 0) {
                    gamePlayers[_gameID][game.playerOrder[i]] += currentStep;
                    break;
                }
            }
            // if i reaches 0 start looping from array end till playerIndex
            if (i == 0) {
                for (i = game.playerOrder.length - 1; i > playerIndex; i--) {
                    if (gameBalances[_gameID][game.playerOrder[i]] > 0) {
                        gamePlayers[_gameID][game.playerOrder[i]] += currentStep;
                        break;
                    }
                }
            }
            // Sanity check
            require(i != playerIndex, "Fatal error");
        }

        Bid memory bid = Bid({ amount: _tokenAmount, bidder: msg.sender });

        game.bidHistory.push(bid);
        emit BidReceived(_gameID);
    }

    function findTipper(uint256 _gameID, uint16 _tippingAmount) internal returns (address tipper) {
        GameInfo storage game = gameInfos[_gameID];
        uint256 totalBid = game.totalBid;
        for (uint256 tipIndex = game.bidHistory.length - 1; tipIndex >= 0; tipIndex--) {
            Bid memory bid = game.bidHistory[tipIndex];
            totalBid -= bid.amount;
            if (totalBid < _tippingAmount) {
                tipper = bid.bidder;
                break;
            } else {
                // refund the player
                gameBalances[_gameID][bid.bidder] += bid.amount;
                game.totalBid -= bid.amount;
                game.bidHistory.pop();
            }
        }
    }

    function getHighestNonTipperBid(
        uint256 _gameID,
        address _tipper
    )
        internal
        view
        returns (uint8 highestNonTipperBid)
    {
        GameInfo memory game = gameInfos[_gameID];
        for (uint256 i = 0; i < game.playerOrder.length; i++) {
            if (game.playerOrder[i] != _tipper) {
                uint8 bidAmount = game.startingCoinAmount - gameBalances[_gameID][game.playerOrder[i]];
                if (highestNonTipperBid < bidAmount) {
                    highestNonTipperBid = bidAmount;
                }
            }
        }
    }

    function getHighestNonTipperBidCount(
        uint256 _gameID,
        address _tipper,
        uint8 _highestNonTipperBid
    )
        internal
        returns (uint8 highestNonTipperBidCount)
    {
        GameInfo memory game = gameInfos[_gameID];
        for (uint256 i = 0; i < game.playerOrder.length; i++) {
            if (game.playerOrder[i] != _tipper) {
                uint8 bidAmount = game.startingCoinAmount - gameBalances[_gameID][game.playerOrder[i]];
                if (bidAmount == _highestNonTipperBid) {
                    highestNonTipperBidCount += 1;
                }
            }
        }
    }

    function transferBalances(
        uint256 _gameID,
        address _tipper,
        uint8 _prize,
        uint8 _highestNonTipperBid,
        uint8 fee
    )
        internal
    {
        GameInfo memory game = gameInfos[_gameID];
        ERC20 gameToken = ERC20(game.bidToken);
        for (uint256 i = 0; i < game.playerOrder.length; i++) {
            address player = game.playerOrder[i];
            uint8 refundCoinAmount;
            if (player != _tipper) {
                refundCoinAmount = game.startingCoinAmount;
                if (gameBalances[_gameID][player] == (game.startingCoinAmount - _highestNonTipperBid)) {
                    refundCoinAmount += _prize;
                }
            } else {
                refundCoinAmount = gameBalances[_gameID][_tipper];
            }
            gameToken.transfer(player, game.bidIncrement * refundCoinAmount);
        }
        gameToken.transfer(owner, game.bidIncrement * fee);
    }

    function endGame(uint256 _gameID, uint16 _tippingAmount, bytes32 _randomHash) public onlyAdmin {
        require(_gameID < nextGameID, "Game not yet created");
        GameInfo storage game = gameInfos[_gameID];
        require(game.winningHash != bytes32(0), "Game not initialized");
        require(game.playerOrder.length == game.playerCount, "Game not yet started");
        require(!game.isEnded, "Game already ended");
        require(game.totalBid > _tippingAmount, "Not enough bids");

        bytes memory tippingAmountBytes = new bytes(32);
        assembly {
            mstore(add(tippingAmountBytes, 32), _tippingAmount)
        }

        bytes memory winningRaw = new bytes(32);
        winningRaw[0] = tippingAmountBytes[30];
        winningRaw[1] = tippingAmountBytes[31];

        for (uint256 i = 0; i < 30; i++) {
            winningRaw[i + 2] = _randomHash[i];
        }
        bytes32 winningHash = sha256(winningRaw);

        require(game.winningHash == winningHash, "Hash mismatch");
        game.isEnded = true;

        address tipper = findTipper(_gameID, _tippingAmount);
        uint8 prizePool = game.startingCoinAmount - gameBalances[_gameID][tipper];

        uint8 highestNonTipperBid = getHighestNonTipperBid(_gameID, tipper);
        uint8 highestNonTipperBidCount = getHighestNonTipperBidCount(_gameID, tipper, highestNonTipperBid);

        // TODO Change this calculation because there are cases where the winners wont receive anything.
        uint8 prizeAmount = prizePool / highestNonTipperBidCount;
        uint8 fee = prizePool % highestNonTipperBidCount;

        // Perform balance transfers
        transferBalances(_gameID, tipper, prizeAmount, highestNonTipperBid, fee);
    }

    function getPlayerOrder(address _player, uint256 _gameID) public view returns (uint256 order) {
        require(_gameID < nextGameID, "Game not yet created");
        GameInfo storage game = gameInfos[_gameID];
        for (order = 0; order < game.playerOrder.length; order++) {
            if (game.playerOrder[order] == _player) {
                return order;
            }
        }
    }

    function getCurrentPlayer(uint256 _gameID) public view returns (address) {
        require(_gameID < nextGameID, "Game not yet created");
        GameInfo storage game = gameInfos[_gameID];
        return game.playerOrder[game.turn % game.playerCount];
    }

    function getPlayers(uint256 _gameID) public view returns (address[] memory) {
        require(_gameID < nextGameID, "Game not yet created");
        GameInfo storage game = gameInfos[_gameID];
        return game.playerOrder;
    }

    function getGameRequirements(uint256 _gameID) public view returns (uint8, string memory, uint256, uint8) {
        require(_gameID < nextGameID, "Game not yet created");
        GameInfo storage game = gameInfos[_gameID];
        string memory tokenSymbol = ERC20(game.bidToken).symbol();
        return (game.playerCount, tokenSymbol, game.bidIncrement, game.startingCoinAmount);
    }
}