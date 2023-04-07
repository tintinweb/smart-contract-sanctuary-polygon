// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract DuelP2P is VRFV2WrapperConsumerBase, ConfirmedOwner {
    uint8 constant FEE = 5;

    uint32 callbackVRFGasLimit = 100000;
    uint16 requestVRFConfirmations = 3;
    uint32 numWords = 1;

    uint8 public maxDrumSpin = 7;
    enum GameStage {
        Created,
        PlayerTurn,
        WaitingVRF,
        Finished
    }
    struct Game {
        uint48 id;
        GameStage stage;
        uint256 bet;
        address player1;
        address player2;
        address whoTurn;
        bool player1ShotedOpponent;
        bool player2ShotedOpponent;
        bool shotOpponent;
        uint8 numberDrumSpin;
        address winner;
        uint256 timeLastMove;
    }
    mapping(uint256 => Game) public games;
    uint48 public numberOfGames;
    mapping(uint256 => uint48) public requestVRFIdToGameId;

    event GameJoined(
        uint48 indexed gameId,
        address indexed player2,
        uint256 bet
    );
    event GameCreated(
        uint48 indexed gameId,
        address indexed player1,
        uint256 bet
    );
    event StartGameMove(
        uint48 indexed gameId,
        address indexed player,
        uint256 moveTime,
        bool shotOpponent
    );
    event EndGameMove(uint48 indexed gameId);
    event GameOver(uint48 indexed gameId, address indexed winner);

    constructor(
        address _wrapperAddress,
        address _linkAddress
    )
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
        ConfirmedOwner(msg.sender)
    {}

    function createGame() public payable returns (uint256) {
        games[numberOfGames] = Game(
            numberOfGames,
            GameStage.Created,
            msg.value,
            msg.sender,
            address(0),
            address(0),
            false,
            false,
            false,
            0,
            address(0),
            block.timestamp
        );
        emit GameCreated(numberOfGames, msg.sender, msg.value);
        numberOfGames++;
        return numberOfGames - 1;
    }

    function joinGame(uint48 _gameId) public payable {
        Game storage game = games[_gameId];
        require(msg.value >= game.bet, "The bet is less than necessary");
        require(
            games[_gameId].player2 == address(0),
            "This game is already full"
        );
        game.player2 = msg.sender;
        game.stage = GameStage.PlayerTurn;
        game.whoTurn = random() % 2 == 0 ? game.player1 : game.player2;
        emit GameJoined(_gameId, msg.sender, msg.value);
    }

    function move(uint48 gameId, bool shotOpponent) public {
        Game storage game = games[gameId];
        require(
            msg.sender == game.player1 || msg.sender == game.player2,
            "You are not a player in this game"
        );
        require(game.winner == address(0), "This game is already over");
        require(game.whoTurn == msg.sender, "It is not your turn");
        require(game.stage == GameStage.PlayerTurn, "The game is not started");

        if (shotOpponent) {
            require(
                (game.whoTurn == game.player1 && !game.player1ShotedOpponent) ||
                    (game.whoTurn == game.player2 &&
                        !game.player2ShotedOpponent),
                "You have already shot your opponent"
            );
            game.shotOpponent = true;
            if (game.whoTurn == game.player1) game.player1ShotedOpponent = true;
            else game.player2ShotedOpponent = true;
        }

        requestVRF(gameId);
        game.stage = GameStage.WaitingVRF;

        emit StartGameMove(gameId, msg.sender, game.timeLastMove, shotOpponent);
    }

    function requestVRF(uint48 gameId) private returns (uint256 requestId) {
        requestId = requestRandomness(
            callbackVRFGasLimit,
            requestVRFConfirmations,
            numWords
        );
        requestVRFIdToGameId[requestId] = gameId;
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint48 gameId = requestVRFIdToGameId[_requestId];
        Game storage game = games[gameId];
        uint256 randomNumber = _randomWords[0] % maxDrumSpin;
        bool player1Turn = isPlayer1Turn(game);

        // Check if the random number is less than or equal to the probability of the shot being fired
        if (randomNumber < game.numberDrumSpin) {
            if (game.shotOpponent) {
                game.winner = player1Turn ? game.player1 : game.player2;
            } else {
                game.winner = player1Turn ? game.player2 : game.player1;
            }
            // Send the bet to the winner
            payable(game.winner).transfer((game.bet * (100 - FEE)) / 100);
            emit GameOver(gameId, game.winner);
        } else {
            game.stage = GameStage.PlayerTurn;
            game.whoTurn = player1Turn ? game.player2 : game.player1;
            // Increment the number of drum spins
            game.numberDrumSpin++;
            // Update the last move timestamp
            game.timeLastMove = block.timestamp;
            // Reset the shotOpponent flag
            if (game.shotOpponent) game.shotOpponent = false;
            emit EndGameMove(gameId);
        }
    }

    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            );
    }

    function isPlayer1Turn(Game memory game) public pure returns (bool) {
        return game.whoTurn == game.player1;
    }

    //DEV:
    function withdrawLink(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            LINK.balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );
        LINK.transfer(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        payable(msg.sender).transfer(_amount);
    }

    function setCallbackVRFGasLimit(
        uint32 _callbackVRFGasLimit
    ) external onlyOwner {
        callbackVRFGasLimit = _callbackVRFGasLimit;
    }

    function setMaxDrumSpin(uint8 _maxDrumSpin) external onlyOwner {
        maxDrumSpin = _maxDrumSpin;
    }
}