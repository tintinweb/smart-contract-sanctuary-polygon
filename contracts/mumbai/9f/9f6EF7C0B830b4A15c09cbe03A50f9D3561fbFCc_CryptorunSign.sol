// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
//import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoRunNFTFactory.sol";
import "./CryptorunModifier.sol";
import "./CryptorunFeeSharer.sol";
import "./CryptorunAdministrative.sol";
import "./VerifySignature.sol";



contract CryptorunSign is Pausable, ReentrancyGuard, CryptorunAdministrative, VerifySignature  {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	uint256 public arenaPercentageFee = 6000; // arena rate 60% of 10% 
	uint256 public avatarPercentageFee = 4000; // avatar rate 40% of 10% splitted in 2 player

	struct SignedStartGame {
		address playerAddress;
		address paymentToken;
		bytes signature;
		uint256 startPrice;
	}

	struct Player {
		address playerAddress;
		address paymentToken;
		uint256 startPrice;
		uint256 closePrice;
	}

	struct Run {
		uint256 gameId;
		uint256 startGameTimestamp;
		uint256 endGameTimestamp;
		Player player1;
		Player player2;
		address winner;
	}

	struct RewardInfo {
		address bettedToken;
		uint256 bettedAmount;
		address rewardToken;
		uint256 rewardAmount;
		bool claimed;
	}

	enum Winner {
		PLAYER1,
		PLAYER2,
		NONE
	}

	mapping(uint256 => Run) public runs;
	mapping(uint256 => mapping(address => RewardInfo)) public ledger;


	event StartRun(uint256 indexed gameId, address runTokenPlayer1, address runTokenPlayer2, uint256 startGameTimestamp);
	event EndRun(uint256 indexed gameId, address winner, uint256 endGameTimestamp);
	event Claim(address indexed sender, uint256 indexed gameId, address token, uint256 amount);
	constructor(
		address _adminAddress,
		address _operatorAddress,
		uint256 _ticketCost,
		uint256 _treasuryFee
	) {
		require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
		require(_adminAddress != address(0), "Cannot be zero address");
		require(_operatorAddress != address(0), "Cannot be zero address");

		adminAddress = _adminAddress;
		operatorAddress = _operatorAddress;
		ticketCost = _ticketCost * 1e6;
		treasuryFee = _treasuryFee;
	}

	// function findMatch(address _token) external whenNotPaused nonReentrant {
	// 	require(bettableTokens[_token], "Can only join with allowed tokens");

	// 	Run storage run = runs[currentMatch];

	// 	if (currentMatch == 0 || run.startGameTimestamp > 0 || block.timestamp > run.startMatchTimestamp + findMatchTimeout) {
	// 		_startMatch(_token);
	// 	} else {
	// 		require(run.player1.paymentToken != _token, "Choose a different token to participate in current match");
	// 		_joinMatch(run, _token);
	// 	}
	// }

	// function _startMatch(address paymentToken) internal {
	// 	currentMatch++;

	// 	Run storage run = runs[currentMatch];

	// 	run.gameId = currentMatch;
	// 	run.player1.playerAddress = msg.sender;
	// 	run.player1.paymentToken = paymentToken;
	// 	run.startMatchTimestamp = block.timestamp;

	// 	emit CreateMatch(run.gameId, msg.sender, run.player1.paymentToken,run.startMatchTimestamp);
	// }

	// function _joinMatch(Run storage run, address paymentToken) internal {
	// 	run.player2.playerAddress = msg.sender;
	// 	run.player2.paymentToken = paymentToken;
	// 	run.joinMatchTimestamp = block.timestamp;

	// 	emit JoinMatch(run.gameId, run.player1.paymentToken, run.player2.paymentToken);
	// }

	function startRun(uint256 gameId, SignedStartGame calldata player1, SignedStartGame calldata player2) external onlyOperator whenNotPaused nonReentrant {
		
		//check for unique gameid
		Run storage run = runs[gameId];
		require(run.gameId == 0,"Game id already in use");
		//console.log("verify  tokens to %s ",gameId);
		//check signature of both players
		verify(player1.playerAddress, player1.paymentToken, player1.playerAddress, player1.signature);
		verify(player2.playerAddress, player2.paymentToken, player2.playerAddress, player2.signature);
		//check approval of both players
		//console.log("verified");


		//create run
		run.gameId = gameId;
		run.player1.playerAddress = player1.playerAddress;
		run.player1.paymentToken = player1.paymentToken;
		run.player1.startPrice = player1.startPrice;
		run.player2.playerAddress = player2.playerAddress;
		run.player2.paymentToken = player2.paymentToken;
		run.player2.startPrice = player2.startPrice;
		run.startGameTimestamp = block.timestamp;
		
		//calculate reward
		RewardInfo storage rewardInfoPlayer1 = ledger[gameId][run.player1.playerAddress];
		RewardInfo storage rewardInfoPlayer2 = ledger[gameId][run.player2.playerAddress];

		ERC20 player1PaymentToken = ERC20(run.player1.paymentToken);
		ERC20 player2PaymentToken = ERC20(run.player2.paymentToken);

		uint256 player1PaymentTokenDecimals;
		uint256 player2PaymentTokenDecimals;

		try ERC20(player1PaymentToken).decimals() returns (uint8 decimals) {
			player1PaymentTokenDecimals = decimals;
		} catch {
			player1PaymentTokenDecimals = 18;
		}

		try ERC20(player2PaymentToken).decimals() returns (uint8 decimals) {
			player2PaymentTokenDecimals = decimals;
		} catch {
			player2PaymentTokenDecimals = 18;
		}

		uint256 bettedAmountPlayer1 = ((10**player1PaymentTokenDecimals) * ticketCost) / player1.startPrice;
		uint256 bettedAmountPlayer2 = ((10**player2PaymentTokenDecimals) * ticketCost) / player2.startPrice;

		rewardInfoPlayer1.bettedToken = run.player1.paymentToken;
		rewardInfoPlayer1.bettedAmount = bettedAmountPlayer1;
		rewardInfoPlayer2.bettedToken = run.player2.paymentToken;
		rewardInfoPlayer2.bettedAmount = bettedAmountPlayer2;

		//move token
		//console.log("before token transfer");

		IERC20(run.player1.paymentToken).safeTransferFrom(run.player1.playerAddress, address(this), bettedAmountPlayer1);
		IERC20(run.player2.paymentToken).safeTransferFrom(run.player2.playerAddress, address(this), bettedAmountPlayer2);

		//console.log("token transferred");

		//emit event
		emit StartRun(gameId, run.player1.paymentToken, run.player2.paymentToken, block.timestamp);



		
		
		// Run storage run = runs[gameId];
		// require(run.startGameTimestamp == 0, "Run already started");
		// require(run.joinMatchTimestamp < block.timestamp + startRunTimeout, "Too late to start run");

		// run.player1.startPrice = paymentAmountsUnitPrice[0];
		// run.player2.startPrice = paymentAmountsUnitPrice[1];
		// run.startGameTimestamp = block.timestamp;

		// RewardInfo storage rewardInfoPlayer1 = ledger[gameId][run.player1.playerAddress];
		// RewardInfo storage rewardInfoPlayer2 = ledger[gameId][run.player2.playerAddress];

		// ERC20 player1PaymentToken = ERC20(run.player1.paymentToken);
		// ERC20 player2PaymentToken = ERC20(run.player2.paymentToken);

		// uint256 player1PaymentTokenDecimals;
		// uint256 player2PaymentTokenDecimals;

		// try ERC20(player1PaymentToken).decimals() returns (uint8 decimals) {
		// 	player1PaymentTokenDecimals = decimals;
		// } catch {
		// 	player1PaymentTokenDecimals = 18;
		// }

		// try ERC20(player2PaymentToken).decimals() returns (uint8 decimals) {
		// 	player2PaymentTokenDecimals = decimals;
		// } catch {
		// 	player2PaymentTokenDecimals = 18;
		// }

		// uint256 bettedAmountPlayer1 = ((10**player1PaymentTokenDecimals) * ticketCost) / paymentAmountsUnitPrice[0];
		// uint256 bettedAmountPlayer2 = ((10**player2PaymentTokenDecimals) * ticketCost) / paymentAmountsUnitPrice[1];

		// rewardInfoPlayer1.bettedToken = run.player1.paymentToken;
		// rewardInfoPlayer1.bettedAmount = bettedAmountPlayer1;
		// rewardInfoPlayer2.bettedToken = run.player2.paymentToken;
		// rewardInfoPlayer2.bettedAmount = bettedAmountPlayer2;

		// emit StartRun(gameId, run.player1.paymentToken, run.player2.paymentToken, block.timestamp);

		// IERC20(run.player1.paymentToken).safeTransferFrom(run.player1.playerAddress, address(this), bettedAmountPlayer1);
		// IERC20(run.player2.paymentToken).safeTransferFrom(run.player2.playerAddress, address(this), bettedAmountPlayer2);
	}

	function endRun(uint256 gameId, uint256[] calldata endGamePrices) external onlyOperator whenNotPaused nonReentrant {
		Run storage run = runs[gameId];
		require(run.endGameTimestamp == 0, "Run already closed");
		require(
			block.timestamp > run.startGameTimestamp + gameDuration && block.timestamp < run.startGameTimestamp + gameDuration + endGameTimeout,
			"Cannot close run at this time"
		);

		run.player1.closePrice = endGamePrices[0];
		run.player2.closePrice = endGamePrices[1];

		Winner winner = _getWinner(
			int256(run.player1.startPrice),
			int256(run.player1.closePrice),
			int256(run.player2.startPrice),
			int256(run.player2.closePrice)
		);

		RewardInfo memory loserInfo;
		RewardInfo memory winnerInfo;
		uint256 fee;

		require(winner != Winner.NONE, "Game Tied, please refund");

		if (winner == Winner.PLAYER1) {
			run.winner = run.player1.playerAddress;
			winnerInfo = ledger[gameId][run.player1.playerAddress];
			loserInfo  = ledger[gameId][run.player2.playerAddress];
			fee = (loserInfo.bettedAmount * treasuryFee) / 10000;
			_calculateRewards(gameId, run.winner, loserInfo,fee); 
		}
		if (winner == Winner.PLAYER2) {
			run.winner = run.player2.playerAddress;
			winnerInfo = ledger[gameId][run.player2.playerAddress];
			loserInfo = ledger[gameId][run.player1.playerAddress];
			fee = (loserInfo.bettedAmount * treasuryFee) / 10000;
			_calculateRewards(gameId, run.winner, loserInfo,fee);
		}



		//console.log("reward token %s ",loserInfo.bettedToken);
		uint256 arenaFee = fee * arenaPercentageFee / 10000 ;
		_setArenaFee(gameId, loserInfo.bettedToken, arenaFee);
		//set fees for the loser avatar
		uint256 avatarFee= fee * avatarPercentageFee / 10000 / 2;
		_setAvatarFee(gameId, loserInfo.bettedToken, loserInfo.bettedToken,avatarFee);
		//set fee for the winner avatar
		_setAvatarFee(gameId, winnerInfo.bettedToken, loserInfo.bettedToken ,avatarFee);
		
		run.endGameTimestamp = block.timestamp;

		emit EndRun(gameId, run.winner, block.timestamp);
	}

	function _getWinner(
		int256 player1StartPrice,
		int256 player1EndPrice,
		int256 player2StartPrice,
		int256 player2EndPrice
	) internal pure returns (Winner) {
		int256 player1PriceVariation = ((player1EndPrice - player1StartPrice) * 1e10) / player1StartPrice;
		int256 player2PriceVariation = ((player2EndPrice - player2StartPrice) * 1e10) / player2StartPrice;

		if (player1PriceVariation > player2PriceVariation) {
			return Winner.PLAYER1;
		}

		if (player2PriceVariation > player1PriceVariation) {
			return Winner.PLAYER2;
		}

		return Winner.NONE;
	}

	function _calculateRewards(
		uint256 gameId,
		address winner,
		RewardInfo memory loser,
		uint256 fee
	) internal {
		RewardInfo storage rewardInfo = ledger[gameId][winner];
		rewardInfo.rewardToken = loser.bettedToken;
		rewardInfo.rewardAmount = loser.bettedAmount - fee;
	}

	
	function claim(uint256 gameId) external nonReentrant notContract {
		require(runs[gameId].startGameTimestamp != 0, "Round has not started");
		require(block.timestamp > runs[gameId].endGameTimestamp, "Round has not ended");

		RewardInfo storage rewardInfo = ledger[gameId][msg.sender];
		address rewardToken = rewardInfo.rewardToken;
		uint256 rewardAmount = rewardInfo.rewardAmount;
		address bettedToken = rewardInfo.bettedToken;
		uint256 bettedAmount = rewardInfo.bettedAmount;

		if (claimable(gameId, msg.sender)) {
			rewardInfo.claimed = true;

			emit Claim(msg.sender, gameId, rewardToken, rewardAmount);
			emit Claim(msg.sender, gameId, bettedToken, bettedAmount);

			IERC20(rewardToken).safeTransfer(address(msg.sender), rewardAmount);
			IERC20(bettedToken).safeTransfer(address(msg.sender), bettedAmount);
		} else if (refundable(gameId, msg.sender)) {
			rewardInfo.claimed = true;

			emit Claim(msg.sender, gameId, rewardToken, rewardAmount);

			IERC20(bettedToken).safeTransfer(address(msg.sender), bettedAmount);
		}
	}

	function claimable(uint256 gameId, address user) public view returns (bool) {
		RewardInfo memory rewardInfo = ledger[gameId][user];
		Run memory run = runs[gameId];

		return rewardInfo.rewardAmount > 0 && rewardInfo.bettedAmount > 0 && !rewardInfo.claimed && run.winner == user;
	}

	function refundable(uint256 gameId, address user) public view returns (bool) {
		RewardInfo memory rewardInfo = ledger[gameId][user];
		Run memory run = runs[gameId];

		return
			run.endGameTimestamp == 0 &&
			run.startGameTimestamp > 0 &&
			!rewardInfo.claimed &&
			block.timestamp > run.startGameTimestamp + gameDuration + endGameTimeout &&
			rewardInfo.bettedAmount > 0;
	}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICryptoRunNFTFactory is IERC721
{
    /**
     * @dev Returns the last tokenId minted.
     */
    function latestTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoRunNFTFactory.sol";


abstract contract CryptorunModifier is Pausable {
	using SafeMath for uint256;

	address public adminAddress; // address of the admin
	address public operatorAddress; // address of the operator
	uint256 public currentMatch; // current match
	event Pause(uint256 indexed gameId);
	event Unpause(uint256 indexed gameId);

	modifier onlyAdmin() {
		require(msg.sender == adminAddress, "Not admin");
		_;
	}

	modifier onlyAdminOrOperator() {
		require(msg.sender == adminAddress || msg.sender == operatorAddress, "Not operator/admin");
		_;
	}

	modifier onlyOperator() {
		require(msg.sender == operatorAddress, "Not operator");
		_;
	}

	modifier notContract() {
		require(!_isContract(msg.sender), "Contract not allowed");
		require(msg.sender == tx.origin, "Proxy contract not allowed");
		_;
	}

	
	
	function _isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function pause() external whenNotPaused onlyAdminOrOperator {
		_pause();

		emit Pause(currentMatch);
	}

	function unpause() external whenPaused onlyAdmin {
		// genesisStartOnce = false;
		// genesisLockOnce = false;
		_unpause();

		emit Unpause(currentMatch);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoRunNFTFactory.sol";
import "./CryptorunModifier.sol";
import "./CryptorunNFTLinker.sol";
//import "hardhat/console.sol";


abstract contract CryptorunFeeSharer is CryptorunNFTLinker  {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	//Mapping to link arenaNFTID and commission amount 
	mapping(uint256 => mapping(address => uint256)) public arenaFees;
	uint256 public _totalArenaMinted;

	//Mapping to link currency -> avatarNFTID ->rewardcurrency -> reward amount 
	mapping(address => mapping(uint256 => mapping(address => uint256))) public avatarFees;
	mapping(address => uint256) public _totalAvatarMinted;

	event TotalArenaUpdated(uint256 indexed totalArena);
	event TotalAvatarUpdated(address indexed currency, uint256 indexed totalAvatar);
	event ArenaFeeUpdated(uint256 indexed arenaID,address indexed currency, int256 amount);
	event AvatarFeeUpdated(uint256 indexed avatarID,address indexed avatarCurrency, address indexed currency, int256 amount );

	function _setArenaFee(uint256 gameId, address currencyFee, uint256 fee) internal {
		uint256 arenaTokenId = (gameId % _totalArenaMinted) + 1;
		if(uint256(arenaFees[arenaTokenId][currencyFee]) > 0 )
		{
			//console.log("Set arena check! Amount for arena %s is %s of token %s", arenaTokenId, fee, currencyFee);
			arenaFees[arenaTokenId][currencyFee] = arenaFees[arenaTokenId][currencyFee] + fee;
		}
		else
		{
			//console.log("Set arena not check! Amount for arena %s is %s of token %s", arenaTokenId, fee, currencyFee);
			arenaFees[arenaTokenId][currencyFee] = fee;
		}

		emit ArenaFeeUpdated(arenaTokenId,currencyFee,int256(arenaFees[arenaTokenId][currencyFee]));	

	}

	function ClaimArenaFee(uint256 arenaTokenId, address currencyFee) public {
		ICryptoRunNFTFactory nftFactory = ICryptoRunNFTFactory(nftArenaFactoryContract);
		address nftOwner = nftFactory.ownerOf(arenaTokenId);
		require(nftOwner == msg.sender,"Caller doesn't own arena token");
		uint256 arenaFeeAmount = arenaFees[arenaTokenId][currencyFee];
		//console.log("Amount for arena %s is %s of token %s", arenaTokenId, arenaFeeAmount, currencyFee);
		arenaFees[arenaTokenId][currencyFee] = 0;
		IERC20(currencyFee).safeTransfer(address(msg.sender), arenaFeeAmount);	
		emit ArenaFeeUpdated(arenaTokenId, currencyFee, -int256(arenaFeeAmount) );	
	}

	function _setAvatarFee(uint256 gameId,address avatarCurrency, address currencyFee, uint256 fee) internal {
		uint avatarTokenId = (gameId % _totalAvatarMinted[avatarCurrency]) + 1;

		if(uint256(avatarFees[avatarCurrency][avatarTokenId][currencyFee]) > 0 ){
			avatarFees[avatarCurrency][avatarTokenId][currencyFee] = avatarFees[avatarCurrency][avatarTokenId][currencyFee] + fee;
		}
		else{
			avatarFees[avatarCurrency][avatarTokenId][currencyFee] = fee;
		}

		emit AvatarFeeUpdated(avatarTokenId, avatarCurrency, currencyFee, int256(avatarFees[avatarCurrency][avatarTokenId][currencyFee]));	
	}

	function ClaimAvatarFee(uint256 avatarTokenId,address avatarCurrency, address currencyFee) public {
		address nftFactoryAddress = avatarNftFactories[avatarCurrency];
		ICryptoRunNFTFactory nftFactory = ICryptoRunNFTFactory(nftFactoryAddress);
		address nftOwner = nftFactory.ownerOf(avatarTokenId);
		require(nftOwner == msg.sender,"Caller doesn't own avatar token");
		uint256 avatarFeeAmount = avatarFees[avatarCurrency][avatarTokenId][currencyFee];
		avatarFees[avatarCurrency][avatarTokenId][currencyFee] = 0;
		IERC20(currencyFee).safeTransfer(address(msg.sender), avatarFeeAmount);		
		emit AvatarFeeUpdated(avatarTokenId, avatarCurrency ,currencyFee, -int256(avatarFeeAmount));			
	}


	//call nftarena contract and update total minted
	function updateTotalArenaMinted() external  onlyAdmin {
		ICryptoRunNFTFactory nftFactory = ICryptoRunNFTFactory(nftArenaFactoryContract);
		_totalArenaMinted = nftFactory.latestTokenId();
		emit TotalArenaUpdated(_totalArenaMinted);
	}
	//call nftavatar contract and update total minted for different currency
	function updateTotalAvatarMinted(address avatarCurrency) external  onlyAdmin {
		address nftAvatarFactoryContract = avatarNftFactories[avatarCurrency];
		ICryptoRunNFTFactory nftFactory = ICryptoRunNFTFactory(nftAvatarFactoryContract);
		_totalAvatarMinted[avatarCurrency] = nftFactory.latestTokenId();
		emit TotalAvatarUpdated(avatarCurrency, _totalAvatarMinted[avatarCurrency]);
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CryptorunModifier.sol";
import "./CryptorunFeeSharer.sol";


abstract contract CryptorunAdministrative is Pausable, Ownable, CryptorunFeeSharer {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 public ticketCost; // minimum betting amount in dollars
	uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
	uint256 public constant MAX_TREASURY_FEE = 1000; // 10%
	uint256 public findMatchTimeout = 300;
	uint256 public startRunTimeout = 60;
	uint256 public gameDuration = 30;
	uint256 public endGameTimeout = 30;

	mapping(address => bool) public bettableTokens;
	//mapping(address => uint256) public fees;

	event NewAdminAddress(address admin);
	event NewOperatorAddress(address operator);
	event NewTicketCost(uint256 indexed epoch, uint256 betAmount);
	event BettableTokenUpdated(address token, string tokenName, bool added);
	event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
	event NewFindMatchTimeout(uint256 timeout);
	event NewStartRunTimeout(uint256 timeout);
	event NewGameDuration(uint256 duration);
	event NewEndGameTimeout(uint256 timeout);

	function setTreasuryFee(uint256 _treasuryFee) external whenPaused onlyAdmin {
		require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
		treasuryFee = _treasuryFee;

		emit NewTreasuryFee(currentMatch, treasuryFee);
	}

	function setTicketCost(uint256 _ticketCost) external whenPaused onlyAdmin {
		require(_ticketCost != 0, "Must be superior to 0");
		ticketCost = _ticketCost;

		emit NewTicketCost(currentMatch, ticketCost);
	}

	function setAdmin(address _adminAddress) external onlyOwner {
		require(_adminAddress != address(0), "Cannot be zero address");
		adminAddress = _adminAddress;

		emit NewAdminAddress(_adminAddress);
	}

	function setOperator(address _operatorAddress) external whenPaused onlyAdmin {
		require(_operatorAddress != address(0), "Cannot be zero address");
		operatorAddress = _operatorAddress;

		emit NewOperatorAddress(_operatorAddress);
	}

	function setFindMatchTimeout(uint256 timeout) external whenPaused onlyAdmin {
		require(timeout > 0, "Cannot be zero or lower");
		findMatchTimeout = timeout;
		emit NewFindMatchTimeout(timeout);
	}

	function setStartRunTimeout(uint256 timeout) external whenPaused onlyAdmin {
		require(timeout > 0, "Cannot be zero or lower");
		startRunTimeout = timeout;
		emit NewStartRunTimeout(timeout);
	}

	function setGameDuration(uint256 duration) external whenPaused onlyAdmin {
		require(duration > 0, "Cannot be zero or lower");
		gameDuration = duration;
		emit NewGameDuration(duration);
	}

	function setEndGameTimeout(uint256 timeout) external whenPaused onlyAdmin {
		require(timeout > 0, "Cannot be zero or lower");
		endGameTimeout = timeout;
		emit NewEndGameTimeout(timeout);
	}

	function addBettableToken(address _tokenAddress) external whenPaused onlyAdmin {
		bettableTokens[_tokenAddress] = true;

		ERC20 bettable = ERC20(_tokenAddress);
		string memory name = bettable.name();
		//todo: emit also erc20 token name in event for logging in moralis
		emit BettableTokenUpdated(_tokenAddress, name, true);
	}

	function removeBettableToken(address _tokenAddress) external whenPaused onlyAdmin {
		bettableTokens[_tokenAddress] = false;
		ERC20 bettable = ERC20(_tokenAddress);
		string memory name = bettable.name();
		emit BettableTokenUpdated(_tokenAddress, name, false);
	}

	// function collectFees(address token) external onlyAdmin {
	// 	IERC20(token).safeTransfer(msg.sender, fees[token]);
	// }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

//import "hardhat/console.sol";
/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign with tokenaddress and playeraddress
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

abstract contract VerifySignature {
    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x359b610d8B7146A4cC0D97D63e391C03ea63FAE6, //busd contract for example on matic network
        0x677af2C11c9cc78604340926ea23D5eE0dFdcf14, //test player 1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(
        address _tokenAddress,
        address _playerAddress
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_tokenAddress, _playerAddress));
    }

    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /* 4. Verify signature
    signer = 0x677af2C11c9cc78604340926ea23D5eE0dFdcf14
    tokenAddress = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    playerAddress = 0x677af2C11c9cc78604340926ea23D5eE0dFdcf14
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(
        address _signer,
        address _tokenAddress,
        address _playerAddress,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_tokenAddress, _playerAddress);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoRunNFTFactory.sol";
import "./CryptorunModifier.sol";


abstract contract CryptorunNFTLinker is CryptorunModifier {
	using SafeMath for uint256;

	address public nftArenaFactoryContract;
	//map a currency address with his tokenfactory address
	mapping(address => address) public avatarNftFactories;

	event UpdatedArenaFactory(address indexed arenaFactoryAddress);
	event UpdatedTokenFactory(address indexed currency, address indexed tokenFactory);

	function setTokenFactory(address currency, address tokenFactory) public onlyAdmin {
		avatarNftFactories[currency] = tokenFactory;
		emit UpdatedTokenFactory(currency, tokenFactory);

	}
	
	
	function setArenaFactory(address arenaFactory) public onlyAdmin {
		nftArenaFactoryContract = arenaFactory;
		emit UpdatedArenaFactory(arenaFactory);
	}

	
}