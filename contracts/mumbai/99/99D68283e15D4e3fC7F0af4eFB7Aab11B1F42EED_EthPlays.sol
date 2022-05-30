// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import '@rari-capital/solmate/src/tokens/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @title An experiment in collaborative gaming
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract EthPlays is ERC20, Ownable {
  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Indicates if the game is currently active
  bool public isActive;

  /// @notice The index of the last executed input
  uint256 public inputIndex;
  /// @notice The block timestamp of the previous input
  uint256 private inputTimestamp;

  /// @notice The current alignment value
  int256 public alignment;
  /// @notice The rate (out of 1000) to remain upon decay
  uint256 private alignmentDecayRate;

  /// @notice Count of order votes for each button index, by input index
  uint256[8] private orderVotes;
  /// @notice Number of seconds in the order vote period
  uint256 private orderLength;

  /// @notice Registered account addresses by burner account address
  mapping(address => address) public accounts;
  /// @notice Burner account addresses by registered account address
  mapping(address => address) public burnerAccounts;
  /// @notice Total number of inputs an account has made
  mapping(address => uint256) private inputNonces;
  /// @notice Most recent block in which an account submitted an input
  mapping(address => uint256) private inputBlocks;

  /// @notice The number of inputs in each reward tier
  uint256 public rewardTierSize;
  /// @notice The current reward (in POKE) for chaos inputs
  uint256 public chaosReward;
  /// @notice The current reward (in POKE) for order input votes
  uint256 public orderReward;
  /// @notice The current cost (in POKE) to submit a chat message
  uint256 public chatCost;
  /// @notice The current cost (in POKE) to submit a banner message
  uint256 public bannerMessageCost;
  /// @notice The current cost (in POKE) to take individual control
  uint256 public individualControlCost;
  /// @notice The current cost (in POKE) to buy a rare candy
  uint256 public rareCandyCost;

  /// @notice The current banner message
  string public bannerMessage;
  /// @notice The block timestamp marking the start of the current banner message
  uint256 private bannerMessageTimestamp;
  /// @notice The number of seconds that the banner message lasts
  uint256 private bannerMessageLength;

  /// @notice The address of the latest account to take individual control
  address public individualControlAddress;
  /// @notice The block timestamp marking the start of the latest banner message
  uint256 private individualControlTimestamp;
  /// @notice The number of seconds that individual control lasts
  uint256 private individualControlLength;

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */

  // Player events
  event AlignmentVote(address from, bool vote, int256 alignment);
  event InputVote(uint256 inputIndex, address from, uint256 buttonIndex);
  event ButtonInput(uint256 inputIndex, address from, uint256 buttonIndex);
  event Chat(address from, string message);
  event BannerMessage(address from, string message);
  event IndividualControl(address from);
  event RareCandy(address from, uint256 count);

  // Owner events
  event UpdateBurnerAccount(address account, address burnerAccount);
  event UpdateIsActive(bool isActive);
  event UpdateAlignmentDecayRate(uint256 alignmentDecayRate);
  event UpdateOrderLength(uint256 orderLength);
  event UpdateBannerMessageLength(uint256 bannerMessageLength);
  event UpdateIndividualControlLength(uint256 individualControlLength);
  event UpdateRewardTierSize(uint256 rewardTierSize);
  event UpdateChaosReward(uint256 chaosReward);
  event UpdateOrderReward(uint256 orderReward);
  event UpdateChatCost(uint256 chatCost);
  event UpdateBannerMessageCost(uint256 bannerMessageCost);
  event UpdateIndividualControlCost(uint256 individualControlCost);
  event UpdateRareCandyCost(uint256 rareCandyCost);

  /* -------------------------------------------------------------------------- */
  /*                                   ERRORS                                   */
  /* -------------------------------------------------------------------------- */

  error GameNotActive();
  error AccountNotRegistered();
  error InvalidButtonIndex();
  error InsufficientBalance(uint256 cost);
  error IndividualControlActive();
  error BannerMessageActive();

  /* -------------------------------------------------------------------------- */
  /*                                 MODIFIERS                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Requires the game to be active.
  modifier onlyActive() {
    if (!isActive) revert GameNotActive();
    _;
  }

  /// @notice Requires the sender to be a registered account.
  modifier onlyRegistered() {
    if (accounts[msg.sender] == address(0)) revert AccountNotRegistered();
    _;
  }

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */

  constructor() ERC20('Eth Plays', 'POKE', 18) {
    isActive = true;
    alignmentDecayRate = 985;

    orderLength = 20;
    bannerMessageLength = 30;
    individualControlLength = 60;

    rewardTierSize = 100;
    orderReward = 10 * (10**18);
    chaosReward = 20 * (10**18);
    chatCost = 10 * (10**18);
    bannerMessageCost = 100 * (10**18);
    individualControlCost = 500 * (10**18);
    rareCandyCost = 200 * (10**18);
  }

  /* -------------------------------------------------------------------------- */
  /*                                  GAMEPLAY                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice Submit a button input.
  /// @param buttonIndex The index of the button input. Must be between 0 and 7.
  function submitButtonInput(uint256 buttonIndex) external onlyActive onlyRegistered {
    if (buttonIndex > 7) {
      revert InvalidButtonIndex();
    }

    if (block.timestamp <= individualControlTimestamp + individualControlLength) {
      // Individual control.

      if (msg.sender != individualControlAddress) {
        revert IndividualControlActive();
      }

      inputTimestamp = block.timestamp;
      emit ButtonInput(inputIndex, msg.sender, buttonIndex);
      inputIndex++;
    } else if (alignment > 0) {
      // Order.

      orderVotes[buttonIndex]++;

      _mint(msg.sender, calculateReward(orderReward));
      emit InputVote(inputIndex, msg.sender, buttonIndex);

      if (block.timestamp >= inputTimestamp + orderLength) {
        // If orderLength seconds have passed since the previous input, execute.
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
      }
    } else {
      // Chaos.

      _mint(msg.sender, calculateReward(chaosReward));

      inputTimestamp = block.timestamp;
      emit ButtonInput(inputIndex, msg.sender, buttonIndex);
      inputIndex++;
    }

    inputNonces[msg.sender]++;
    inputBlocks[msg.sender] = block.number;
  }

  /// @notice Submit an alignment vote.
  /// @param _alignmentVote The alignment vote. True corresponds to order, false to chaos.
  function submitAlignmentVote(bool _alignmentVote) external onlyActive onlyRegistered {
    // Apply alignment decay.
    alignment *= int256(alignmentDecayRate);
    alignment /= int256(1000);

    // Apply sender alignment update.
    alignment += _alignmentVote ? int256(1000) : -1000;

    emit AlignmentVote(msg.sender, _alignmentVote, alignment);
  }

  /* -------------------------------------------------------------------------- */
  /*                                  REDEEMS                                   */
  /* -------------------------------------------------------------------------- */

  /// @notice Submit an message to the chat.
  /// @param message The chat message.
  function submitChat(string memory message) external onlyActive onlyRegistered {
    if (balanceOf[msg.sender] < chatCost) {
      revert InsufficientBalance(chatCost);
    }

    _burn(msg.sender, chatCost);

    emit Chat(msg.sender, message);
  }

  /// @notice Submit an updated banner message. Costs $bannerMessageCost POKE.
  /// @param message The banner message.
  function submitBannerMessage(string memory message) external onlyActive onlyRegistered {
    if (balanceOf[msg.sender] < bannerMessageCost) {
      revert InsufficientBalance(bannerMessageCost);
    }

    if (block.timestamp < bannerMessageTimestamp + bannerMessageLength) {
      revert BannerMessageActive();
    }

    _burn(msg.sender, bannerMessageCost);

    bannerMessageTimestamp = block.timestamp;
    bannerMessage = message;

    emit BannerMessage(msg.sender, message);
  }

  /// @notice Submit a request for individual control. Costs $individualControlCost POKE.
  function submitIndividualControl() external onlyActive onlyRegistered {
    if (balanceOf[msg.sender] < individualControlCost) {
      revert InsufficientBalance(individualControlCost);
    }

    if (block.timestamp < individualControlTimestamp + individualControlLength) {
      revert IndividualControlActive();
    }

    _burn(msg.sender, individualControlCost);

    individualControlTimestamp = block.timestamp;
    individualControlAddress = msg.sender;

    emit IndividualControl(msg.sender);
  }

  /// @notice Submit a request to purchase rare candies.
  /// @param count The number of rare candies to be purchased.
  function submitRareCandies(uint256 count) external onlyActive onlyRegistered {
    uint256 totalCost = rareCandyCost * count;

    if (balanceOf[msg.sender] < totalCost) {
      revert InsufficientBalance(totalCost);
    }

    _burn(msg.sender, totalCost);
    emit RareCandy(msg.sender, count);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   ADMIN                                    */
  /* -------------------------------------------------------------------------- */

  function updateRegistration(address account, address burnerAccount) external onlyOwner {
    address previousBurnerAccount = burnerAccounts[account];
    if (previousBurnerAccount != address(0)) {
      // This is a re-registration, so must unregister the old burner account.
      accounts[previousBurnerAccount] = address(0);
    }

    accounts[burnerAccount] = account;
    burnerAccounts[account] = burnerAccount;

    emit UpdateBurnerAccount(account, burnerAccount);
  }

  function setActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
    emit UpdateIsActive(_isActive);
  }

  function setAlignmentDecayRate(uint256 _alignmentDecayRate) external onlyOwner {
    alignmentDecayRate = _alignmentDecayRate;
    emit UpdateAlignmentDecayRate(_alignmentDecayRate);
  }

  function setOrderLength(uint256 _orderLength) external onlyOwner {
    orderLength = _orderLength;
    emit UpdateOrderLength(_orderLength);
  }

  function setBannerMessageLength(uint256 _bannerMessageLength) external onlyOwner {
    bannerMessageLength = _bannerMessageLength;
    emit UpdateBannerMessageLength(_bannerMessageLength);
  }

  function setIndividualControlLength(uint256 _individualControlLength) external onlyOwner {
    individualControlLength = _individualControlLength;
    emit UpdateIndividualControlLength(_individualControlLength);
  }

  function setRewardTierSize(uint256 _rewardTierSize) external onlyOwner {
    rewardTierSize = _rewardTierSize;
    emit UpdateRewardTierSize(_rewardTierSize);
  }

  function setChaosReward(uint256 _chaosReward) external onlyOwner {
    chaosReward = _chaosReward;
    emit UpdateChaosReward(_chaosReward);
  }

  function setOrderReward(uint256 _orderReward) external onlyOwner {
    orderReward = _orderReward;
    emit UpdateOrderReward(_orderReward);
  }

  function setChatCost(uint256 _chatCost) external onlyOwner {
    chatCost = _chatCost;
    emit UpdateChatCost(_chatCost);
  }

  function setBannerMessageCost(uint256 _bannerMessageCost) external onlyOwner {
    bannerMessageCost = _bannerMessageCost;
    emit UpdateBannerMessageCost(_bannerMessageCost);
  }

  function setIndividualControlCost(uint256 _individualControlCost) external onlyOwner {
    individualControlCost = _individualControlCost;
    emit UpdateIndividualControlCost(_individualControlCost);
  }

  function setRareCandyCost(uint256 _rareCandyCost) external onlyOwner {
    rareCandyCost = _rareCandyCost;
    emit UpdateRareCandyCost(_rareCandyCost);
  }

  /* -------------------------------------------------------------------------- */
  /*                                  HELPERS                                   */
  /* -------------------------------------------------------------------------- */

  /// @notice Calculates the reward modifier for this button input.
  /// @return reward The reward, adjusted for playtime
  function calculateReward(uint256 baseReward) internal view returns (uint256) {
    // If this is not the first reward for this player in this block, return zero.
    if (inputBlocks[msg.sender] >= block.number) {
      return 0;
    }

    uint256 rewardTier = inputNonces[msg.sender] / rewardTierSize;
    // If the player is beyond rewardTier 9, set to rewardTier 9.
    rewardTier = rewardTier > 9 ? 9 : rewardTier;
    return (baseReward * (10 - rewardTier)) / 10;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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