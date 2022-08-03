// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {Poke} from './Poke.sol';
import {RegistryReceiverV0} from './RegistryReceiverV0.sol';

/// @title An experiment in collaborative gaming
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract EthPlaysV0 is Ownable {
  /* -------------------------------------------------------------------------- */
  /*                                   STRUCTS                                  */
  /* -------------------------------------------------------------------------- */

  struct ControlBid {
    address from;
    uint256 amount;
  }

  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice [Contract] The POKE token contract
  Poke public poke;
  /// @notice [Contract] The EthPlays registry contract
  RegistryReceiverV0 public registryReceiver;

  /// @notice [Parameter] Indicates if the game is currently active
  bool public isActive;

  /// @notice [State] The index of the last executed input
  uint256 public inputIndex;
  /// @notice [State] The block timestamp of the previous input
  uint256 private inputTimestamp;

  /// @notice [Parameter] The fraction of alignment to persist upon decay, out of 1000
  uint256 public alignmentDecayRate;
  /// @notice [Parameter] Number of seconds between alignment votes for each account
  uint256 public alignmentVoteCooldown;
  /// @notice [Parameter] The current reward (in POKE) for voting for chaos
  uint256 public chaosVoteReward;
  /// @notice [State] Timestamp of latest alignment vote by account address
  mapping(address => uint256) private alignmentVoteTimestamps;
  /// @notice [State] The current alignment value
  int256 public alignment;

  /// @notice [Parameter] Number of seconds in the order vote period
  uint256 public orderDuration;
  /// @notice [State] Count of order votes for each button index, by input index
  uint256[8] private orderVotes;
  /// @notice [State] Most recent inputIndex an account submitted an order vote
  mapping(address => uint256) private inputIndices;

  /// @notice [State] Timestamp of the most recent chaos input for each account
  mapping(address => uint256) private chaosInputTimestamps;
  /// @notice [Parameter] Number of seconds of cooldown between chaos rewards
  uint256 public chaosInputRewardCooldown;

  /// @notice [Parameter] The current reward (in POKE) for chaos inputs, subject to cooldown
  uint256 public chaosInputReward;
  /// @notice [Parameter] The current reward (in POKE) for order input votes
  uint256 public orderInputReward;
  /// @notice [Parameter] The current cost (in POKE) to submit a chat message
  uint256 public chatCost;
  /// @notice [Parameter] The current cost (in POKE) to buy a rare candy
  uint256 public rareCandyCost;

  /// @notice [Parameter] The number of seconds that the control auction lasts
  uint256 public controlAuctionDuration;
  /// @notice [Parameter] The number of seconds that control lasts
  uint256 public controlDuration;
  /// @notice [State] The best bid for the current control auction
  ControlBid private bestControlBid;
  /// @notice [State] The block timestamp of the start of the latest control auction
  uint256 public controlAuctionStartTimestamp;
  /// @notice [State] The block timestamp of the end of the latest control auction
  uint256 public controlAuctionEndTimestamp;
  /// @notice [State] The account that has (or most recently had) control
  address public controlAddress;

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */

  // Gameplay events
  event AlignmentVote(address from, bool vote, int256 alignment);
  event InputVote(uint256 inputIndex, address from, uint256 buttonIndex);
  event ButtonInput(uint256 inputIndex, address from, uint256 buttonIndex);
  event Chat(address from, string message);
  event RareCandy(address from, uint256 count);

  // Auction events
  event NewControlBid(address from, uint256 amount);
  event Control(address from);

  // Parameter update events
  event SetIsActive(bool isActive);
  event SetAlignmentDecayRate(uint256 alignmentDecayRate);
  event SetChaosVoteReward(uint256 chaosVoteReward);
  event SetOrderDuration(uint256 orderDuration);
  event SetChaosInputRewardCooldown(uint256 chaosInputRewardCooldown);
  event SetChaosInputReward(uint256 chaosInputReward);
  event SetOrderInputReward(uint256 orderInputReward);
  event SetChatCost(uint256 chatCost);
  event SetRareCandyCost(uint256 rareCandyCost);
  event SetControlAuctionDuration(uint256 controlAuctionDuration);
  event SetControlDuration(uint256 controlDuration);

  /* -------------------------------------------------------------------------- */
  /*                                   ERRORS                                   */
  /* -------------------------------------------------------------------------- */

  // Gameplay errors
  error GameNotActive();
  error AccountNotRegistered();
  error InvalidButtonIndex();
  error AnotherPlayerHasControl();
  error AlreadyVotedForThisInput();
  error AlignmentVoteCooldown();

  // Redeem errors
  error InsufficientBalanceForRedeem();

  // Auction errors
  error InsufficientBalanceForBid();
  error InsufficientBidAmount();
  error AuctionInProgress();
  error AuctionIsOver();
  error AuctionHasNoBids();

  /* -------------------------------------------------------------------------- */
  /*                                 MODIFIERS                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Requires the game to be active.
  modifier onlyActive() {
    if (!isActive) {
      revert GameNotActive();
    }
    _;
  }

  /// @notice Requires the sender to be a registered account.
  modifier onlyRegistered() {
    if (!registryReceiver.isRegistered(msg.sender)) {
      revert AccountNotRegistered();
    }
    _;
  }

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */

  constructor(Poke _poke, RegistryReceiverV0 _registryReceiver) {
    poke = _poke;
    registryReceiver = _registryReceiver;

    isActive = true;

    alignmentVoteCooldown = 60;
    alignmentDecayRate = 985;
    chaosVoteReward = 40e18;

    orderDuration = 20;
    chaosInputRewardCooldown = 30;

    chaosInputReward = 20e18;
    orderInputReward = 20e18;
    chatCost = 20e18;
    rareCandyCost = 200e18;

    controlAuctionDuration = 90;
    controlDuration = 30;
    bestControlBid = ControlBid(address(0), 0);
  }

  /* -------------------------------------------------------------------------- */
  /*                                  GAMEPLAY                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Submit an alignment vote.
  /// @param _alignmentVote The alignment vote. True corresponds to order, false to chaos.
  function submitAlignmentVote(bool _alignmentVote) external onlyActive onlyRegistered {
    if (block.timestamp < alignmentVoteTimestamps[msg.sender] + alignmentVoteCooldown) {
      revert AlignmentVoteCooldown();
    }

    // Mint tokens to the sender if the vote is for Chaos.
    if (!_alignmentVote) {
      poke.gameMint(msg.sender, chaosVoteReward);
    }

    // Apply alignment decay.
    alignment *= int256(alignmentDecayRate);
    alignment /= int256(1000);

    // Apply sender alignment update.
    alignment += _alignmentVote ? int256(1000) : -1000;

    alignmentVoteTimestamps[msg.sender] = block.timestamp;
    emit AlignmentVote(msg.sender, _alignmentVote, alignment);
  }

  /// @notice Submit a button input.
  /// @param buttonIndex The index of the button input. Must be between 0 and 7.
  function submitButtonInput(uint256 buttonIndex) external onlyActive onlyRegistered {
    if (buttonIndex > 7) {
      revert InvalidButtonIndex();
    }

    if (block.timestamp <= controlAuctionEndTimestamp + controlDuration) {
      // Control
      if (msg.sender != controlAddress) {
        revert AnotherPlayerHasControl();
      }

      inputTimestamp = block.timestamp;
      emit ButtonInput(inputIndex, msg.sender, buttonIndex);
      inputIndex++;
    } else if (alignment > 0) {
      // Order

      orderVotes[buttonIndex]++;

      // If orderDuration seconds have passed since the previous input, execute.
      // This path could/should be broken out into an external "executeOrderVote"
      // function that rewards the sender in POKE.
      if (block.timestamp >= inputTimestamp + orderDuration) {
        uint256 bestButtonIndex = 0;
        uint256 bestButtonIndexVoteCount = 0;

        for (uint256 i = 0; i < 8; i++) {
          if (orderVotes[i] > bestButtonIndexVoteCount) {
            bestButtonIndex = i;
            bestButtonIndexVoteCount = orderVotes[i];
          }
          orderVotes[i] = 0;
        }

        inputTimestamp = block.timestamp;
        emit ButtonInput(inputIndex, msg.sender, bestButtonIndex);
        inputIndex++;
      } else {
        if (inputIndex == inputIndices[msg.sender]) {
          revert AlreadyVotedForThisInput();
        }
        inputIndices[msg.sender] = inputIndex;

        poke.gameMint(msg.sender, orderInputReward);
        emit InputVote(inputIndex, msg.sender, buttonIndex);
      }
    } else {
      // Chaos
      if (block.timestamp > chaosInputTimestamps[msg.sender] + chaosInputRewardCooldown) {
        chaosInputTimestamps[msg.sender] = block.timestamp;
        poke.gameMint(msg.sender, chaosInputReward);
      }

      inputTimestamp = block.timestamp;
      emit ButtonInput(inputIndex, msg.sender, buttonIndex);
      inputIndex++;
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                  REDEEMS                                   */
  /* -------------------------------------------------------------------------- */

  /// @notice Submit an message to the chat.
  /// @param message The chat message.
  function submitChat(string memory message) external onlyActive onlyRegistered {
    if (poke.balanceOf(msg.sender) < chatCost) {
      revert InsufficientBalanceForRedeem();
    }

    poke.gameBurn(msg.sender, chatCost);
    emit Chat(msg.sender, message);
  }

  /// @notice Submit a request to purchase rare candies.
  /// @param count The number of rare candies to be purchased.
  function submitRareCandies(uint256 count) external onlyActive onlyRegistered {
    uint256 totalCost = rareCandyCost * count;

    if (poke.balanceOf(msg.sender) < totalCost) {
      revert InsufficientBalanceForRedeem();
    }

    poke.gameBurn(msg.sender, totalCost);
    emit RareCandy(msg.sender, count);
  }

  /* -------------------------------------------------------------------------- */
  /*                                  AUCTIONS                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Submit a bid in the active control auction.
  /// @param amount The bid amount in POKE
  function submitControlBid(uint256 amount) external onlyActive onlyRegistered {
    // This is the first bid in the auction, so set controlAuctionStartTimestamp.
    if (bestControlBid.from == address(0)) {
      controlAuctionStartTimestamp = block.timestamp;
    }

    // The auction is over (it must be ended).
    if (block.timestamp > controlAuctionStartTimestamp + controlAuctionDuration) {
      revert AuctionIsOver();
    }

    if (poke.balanceOf(msg.sender) < amount) {
      revert InsufficientBalanceForBid();
    }

    if (amount <= bestControlBid.amount) {
      revert InsufficientBidAmount();
    }

    // If there was a previous best bid, return the bid amount to the account that submitted it.
    if (bestControlBid.from != address(0)) {
      poke.gameMint(bestControlBid.from, bestControlBid.amount);
    }
    poke.gameBurn(msg.sender, amount);
    bestControlBid = ControlBid(msg.sender, amount);
    emit NewControlBid(msg.sender, amount);
  }

  /// @notice End the current control auction and start the cooldown for the next one.
  function endControlAuction() external onlyActive {
    if (block.timestamp < controlAuctionStartTimestamp + controlAuctionDuration) {
      revert AuctionInProgress();
    }

    if (bestControlBid.from == address(0)) {
      revert AuctionHasNoBids();
    }

    emit Control(bestControlBid.from);
    controlAddress = bestControlBid.from;
    bestControlBid = ControlBid(address(0), 0);
    controlAuctionEndTimestamp = block.timestamp;
  }

  /* -------------------------------------------------------------------------- */
  /*                                   ADMIN                                    */
  /* -------------------------------------------------------------------------- */

  /// @notice Set the isActive parameter. Owner only.
  /// @param _isActive New value for the isActive parameter
  function setIsActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
    emit SetIsActive(_isActive);
  }

  function setAlignmentDecayRate(uint256 _alignmentDecayRate) external onlyOwner {
    alignmentDecayRate = _alignmentDecayRate;
    emit SetAlignmentDecayRate(_alignmentDecayRate);
  }

  function setChaosVoteReward(uint256 _chaosVoteReward) external onlyOwner {
    chaosVoteReward = _chaosVoteReward;
    emit SetChaosVoteReward(_chaosVoteReward);
  }

  function setOrderDuration(uint256 _orderDuration) external onlyOwner {
    orderDuration = _orderDuration;
    emit SetOrderDuration(_orderDuration);
  }

  function setChaosInputRewardCooldown(uint256 _chaosInputRewardCooldown) external onlyOwner {
    chaosInputRewardCooldown = _chaosInputRewardCooldown;
    emit SetChaosInputRewardCooldown(_chaosInputRewardCooldown);
  }

  function setChaosInputReward(uint256 _chaosInputReward) external onlyOwner {
    chaosInputReward = _chaosInputReward;
    emit SetChaosInputReward(_chaosInputReward);
  }

  function setOrderInputReward(uint256 _orderInputReward) external onlyOwner {
    orderInputReward = _orderInputReward;
    emit SetOrderInputReward(_orderInputReward);
  }

  function setChatCost(uint256 _chatCost) external onlyOwner {
    chatCost = _chatCost;
    emit SetChatCost(_chatCost);
  }

  function setRareCandyCost(uint256 _rareCandyCost) external onlyOwner {
    rareCandyCost = _rareCandyCost;
    emit SetRareCandyCost(_rareCandyCost);
  }

  function setControlAuctionDuration(uint256 _controlAuctionDuration) external onlyOwner {
    controlAuctionDuration = _controlAuctionDuration;
    emit SetControlAuctionDuration(_controlAuctionDuration);
  }

  function setControlDuration(uint256 _controlDuration) external onlyOwner {
    controlDuration = _controlDuration;
    emit SetControlDuration(_controlDuration);
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/// @title An experiment in collaborative gaming
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract Poke is ERC20, Ownable {
  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Address of the current game contract
  address public gameAddress;

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */

  event SetGameAddress(address gameAddress);

  /* -------------------------------------------------------------------------- */
  /*                                   ERRORS                                   */
  /* -------------------------------------------------------------------------- */

  error NotAuthorized();

  /* -------------------------------------------------------------------------- */
  /*                                 MODIFIERS                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Requires the sender to be the game contract
  modifier onlyGameAddress() {
    if (msg.sender != gameAddress) {
      revert NotAuthorized();
    }
    _;
  }

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */

  constructor() ERC20('ethplays', 'POKE') {}

  /* -------------------------------------------------------------------------- */
  /*                                   GAME                                     */
  /* -------------------------------------------------------------------------- */

  /// @notice Mint new tokens to an account. Can only be called by the game contract.
  /// @param account The account to mint tokens to
  /// @param amount The amount of tokens to mint
  function gameMint(address account, uint256 amount) external onlyGameAddress {
    _mint(account, amount);
  }

  /// @notice Burn existing tokens belonging to an account. Can only be called by the game contract.
  /// @param account The account to burn tokens for
  /// @param amount The amount of tokens to burn
  function gameBurn(address account, uint256 amount) external onlyGameAddress {
    _burn(account, amount);
  }

  /// @notice Transfer tokens without approval. Can only be called by the game contract.
  /// @param from The account to transfer tokens from
  /// @param to The account to transfer tokens to
  /// @param amount The amount of tokens to transfer
  function gameTransfer(
    address from,
    address to,
    uint256 amount
  ) external onlyGameAddress {
    _transfer(from, to, amount);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   OWNER                                    */
  /* -------------------------------------------------------------------------- */

  /// @notice Update the game contract address. Only owner.
  /// @param _gameAddress The address of the active game
  function setGameAddress(address _gameAddress) external onlyOwner {
    gameAddress = _gameAddress;
    emit SetGameAddress(_gameAddress);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/// @title Child registry for EthPlays
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract RegistryReceiverV0 is Ownable {
  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice [State] Registered account addresses by burner account address
  mapping(address => address) public accounts;
  /// @notice [State] Burner account addresses by registered account address
  mapping(address => address) public burnerAccounts;

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */

  event NewRegistration(address account, address burnerAccount);
  event UpdatedRegistration(address account, address burnerAccount, address previousBurnerAccount);

  /* -------------------------------------------------------------------------- */
  /*                                REGISTRATION                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Returns true if the specified burner account is registered.
  /// @param burnerAccount The address of the players burner account
  /// @return isRegistered True if the burner account is registered
  function isRegistered(address burnerAccount) public view returns (bool) {
    return accounts[burnerAccount] != address(0);
  }

  /* -------------------------------------------------------------------------- */
  /*                                REGISTRATION                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Registers a new account to burner account mapping. Owner only.
  /// @param account The address of the players main account
  /// @param burnerAccount The address of the players burner account
  function submitRegistration(address account, address burnerAccount) external onlyOwner {
    address previousBurnerAccount = burnerAccounts[account];

    if (previousBurnerAccount != address(0)) {
      emit UpdatedRegistration(account, burnerAccount, previousBurnerAccount);
    } else {
      emit NewRegistration(account, burnerAccount);
    }

    accounts[burnerAccount] = account;
    burnerAccounts[account] = burnerAccount;
  }
}

// SPDX-License-Identifier: MIT

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