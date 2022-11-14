/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

// File: interfaces/IBaseCharacterNFT.sol


pragma solidity 0.8.17;

interface IBaseCharacterNFT {
    function tokensOwnedBy(address who) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) view external returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(address to) external payable;
}

// File: interfaces/IDominationGame.sol


pragma solidity 0.8.17;

enum GameStage {
    Submit,
    Reveal,
    Resolve,
    PendingWithdrawals,
    Finished
}

struct Player {
    address addr;
    address nftAddress;
    uint256 tokenId;
    uint256 balance;
    uint256 lastMoveTimestamp;
    uint256 allianceId;
    uint256 hp;
    uint256 attack;
    uint256 x;
    uint256 y;
    bytes32 pendingMoveCommitment;
    bytes pendingMove;
    bool inJail;
}

struct Alliance {
    address admin;
    uint256 id;
    uint256 activeMembersCount; // if in Jail, not active
    uint256 membersCount;
    uint256 maxMembers;
    uint256 totalBalance; // used for calc cut of spoils in win condition
    string name;
}

struct JailCell {
    uint256 x;
    uint256 y;
}

interface IDominationGame {
    error LoserTriedWithdraw();
    error OnlyWinningAllianceMember();

    event AttemptJailBreak(address indexed who, uint256 x, uint256 y);
    event AllianceCreated(address indexed admin, uint256 indexed allianceId, string name);
    event AllianceMemberJoined(uint256 indexed allianceId, address indexed player);
    event AllianceMemberLeft(uint256 indexed allianceId,address indexed player);
    event BadMovePenalty(uint256 indexed turn, address indexed player, bytes details);
    event BattleCommenced(address indexed player1, address indexed defender);
    event BattleFinished(address indexed winner, uint256 indexed spoils);
    event BattleStalemate(uint256 indexed attackerHp, uint256 indexed defenderHp);
    event CheckingWinCondition(uint256 indexed activeAlliancesCount, uint256 indexed  activePlayersCount);
    event Constructed(address indexed owner, uint64 indexed subscriptionId, uint256 indexed _gameStartTimestamp);
    event DamageDealt(address indexed by, address indexed to, uint256 indexed amount);
    event GameStartDelayed(uint256 indexed newStartTimeStamp);
    event GameFinished(uint256 indexed turn, uint256 indexed winningTeamTotalSpoils);
    event Fallback(uint256 indexed value, uint256 indexed gasLeft);
    event Jail(address indexed who, uint256 indexed inmatesCount);
    event JailBreak(address indexed who, uint256 newInmatesCount);
    event Joined(address indexed addr);
    event Move(address indexed who, uint newX, uint newY);
    event NewGameStage(GameStage indexed newGameStage, uint256 indexed turn);
    event NftConfiscated(address indexed who, address indexed nftAddress, uint256 indexed tokenId);
    event NoReveal(address indexed who, uint256 indexed turn);
    event NoSubmit(address indexed who, uint256 indexed turn);
    event Received(uint256 indexed value, uint256 indexed gasLeft);
    event Rest(address indexed who, uint256 indexed x, uint256 indexed y);
    event ReturnedRandomness(uint256[] randomWords);
    event Revealed(address indexed addr, uint256 indexed turn, bytes32 nonce, bytes data);
    event RolledDice(uint256 indexed turn, uint256 indexed vrf_request_id);
    event SkipInmateTurn(address indexed who, uint256 indexed turn);
    event Submitted(address indexed addr, uint256 indexed turn, bytes32 commitment);
    event TurnStarted(uint256 indexed turn, uint256 timestamp);
    event UpkeepCheck(uint256 indexed currentTimestamp, uint256 indexed lastUpkeepTimestamp, bool indexed upkeepNeeded);
    event WinnerPlayer(address indexed winner);
    event WinnerAlliance(uint indexed allianceId);
    event WinnerWithdrawSpoils(address indexed winner, uint256 indexed spoils);
    
    function alliances(uint256 allianceId) external view returns (address, uint256, uint256, uint256, uint256, uint256, string memory);
    function connect(uint256 tokenId, address byoNft) external payable;
    function createAlliance(address player, uint256 maxMembers, string calldata name) external;
    function currentTurn() external view returns (uint256);
    function currentTurnStartTimestamp() view external returns (uint256);
    function gameStarted() view external returns (bool);
    function gameStage() view external returns (GameStage);
    function getPlayerMeta(address _player) external view returns(address addr, uint256 allianceId);
    function interval() view external returns (uint256);
    function joinAlliance(address player, uint256 allianceId, uint8 v, bytes32 r, bytes32 s) external;
    function move(address player, int8 direction) external;
    function nextAvailableAllianceId() view external returns (uint256);
    function players(address player) view external returns (address, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bytes32, bytes memory, bool);
    function spoils(address who) external returns (uint256);
    function submit(uint256 turn, bytes32 commitment) external;
    function reveal(uint256 turn, bytes32 nonce, bytes calldata data) external;
    function withdrawWinnerAlliance() external;
    function withdrawWinnerPlayer() external;
    function winnerAllianceId() external view returns (uint256);
}



// File: https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/AutomationBase.sol


pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: https://github.com/smartcontractkit/chainlink-brownie-contracts/contracts/src/v0.8/AutomationCompatible.sol


pragma solidity ^0.8.0;



abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// File: HorizontalBot.sol


pragma solidity 0.8.17;





/**
    Goes right for 10 turns the left for 10 turns, whether or not it fights.
 */
contract HorizontalBot is AutomationCompatible, IERC721Receiver {
    address public deployer;
    address public gameAddr;
    address public byoNftAddr;
    uint256 public byoNftTokenId;
    uint256 public lastUpkeepTurn;
    uint256 public nonce;
    uint256 public interval;
    uint256 public STARTING_SPOILS = 0.0069 ether;
    IDominationGame game;
    IBaseCharacterNFT baseCharacterNft;

    mapping(uint256 => bool) didSubmitForTurn;
    mapping(uint256 => bool) didRevealForTurn;
    
    event Submitting(uint256 turn, bytes commitment);
    event Revealing(uint256 turn, bytes commitment);
    event Fallback(uint256 amount, uint256 gasLeft);
    event Received(uint256 amount, uint256 gasLeft);
    event WithdrewWinnings();
    event NoMoreToDo();

    modifier onlyDeployer() {
        require(msg.sender == deployer);
        _;
    }

    constructor(address _game, address _baseCharacterNft, uint256 _interval) payable {
        game = IDominationGame(_game);
        gameAddr = _game;
        deployer = msg.sender;
        baseCharacterNft = IBaseCharacterNFT(_baseCharacterNft);
        byoNftAddr = _baseCharacterNft;
        byoNftTokenId = 0;
        interval = _interval;
        nonce = 1;
        lastUpkeepTurn = 1;
    }

    function setByoNftTokenId(uint256 _byoNftTokenId) external onlyDeployer {
        byoNftTokenId = _byoNftTokenId;
    }

    function setByoNftAddress(address _byoNftAddr) external onlyDeployer {
        byoNftAddr = _byoNftAddr;
        baseCharacterNft = IBaseCharacterNFT(_byoNftAddr);
    }

    function setGameAddress(address _gameAddr) external onlyDeployer {
        gameAddr = _gameAddr;
        game = IDominationGame(_gameAddr);
        joinGame(byoNftTokenId);
    }

    function joinGame (uint256 _tokenId) public {
        // require(address(this).balance > 0, "Send some ETH to bot to pay for gas.");
        game.connect{value: STARTING_SPOILS}(_tokenId, byoNftAddr);
    }

    function mintDominationCharacter() external payable onlyDeployer {
        baseCharacterNft.mint{ value: msg.value }(address(this));
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        GameStage gameStage = game.gameStage();
        uint256 currentTurn = game.currentTurn();

        if (!game.gameStarted()) {
           return (true, '');
        }

        if (gameStage == GameStage.Submit && !didSubmitForTurn[currentTurn]) {
            upkeepNeeded = true;
        } else if (gameStage == GameStage.Reveal && !didRevealForTurn[currentTurn]) {
            upkeepNeeded = true;
        } else if (gameStage == GameStage.PendingWithdrawals){
            upkeepNeeded = true;
        } else if (gameStage == GameStage.Finished) {
            upkeepNeeded = false;
        }

        return (upkeepNeeded, '');
    }
    
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        lastUpkeepTurn += 1;

        (address addr,) = game.getPlayerMeta(address(this));

        if (!game.gameStarted() || addr == address(0)) {
            joinGame(byoNftTokenId);
            return;
        }

        int8 direction = lastUpkeepTurn % 10 == 0 ? int8(2) : int8(-2);

        bytes memory commitment = abi.encodeWithSelector(
            game.move.selector,
            direction
        );

        if (game.gameStage() == GameStage.Submit) {
            game.submit(lastUpkeepTurn, keccak256(abi.encodePacked(lastUpkeepTurn, bytes32(nonce), commitment)));
            didSubmitForTurn[lastUpkeepTurn] = true;
            emit Submitting(lastUpkeepTurn, commitment);
        } else if (game.gameStage() == GameStage.Reveal) {
            game.reveal(lastUpkeepTurn, bytes32(nonce), commitment);
            didRevealForTurn[lastUpkeepTurn] = true;
            nonce += 1;
            emit Revealing(lastUpkeepTurn, commitment);
        } else if (game.gameStage() == GameStage.PendingWithdrawals) {
            if (game.spoils(address(this)) > 0) {
                game.withdrawWinnerPlayer();
                emit WithdrewWinnings();
            }
            emit NoMoreToDo();
        }
    }

    function withdraw() external onlyDeployer {
        require(address(this).balance > 0, "Nothing to withdraw");
        (bool success, ) = address(payable(msg.sender)).call{value: address(this).balance}("");
        require(success, "Failed to send ETH");

        uint256[] memory tokenIds = baseCharacterNft.tokensOwnedBy(address(this));
        baseCharacterNft.safeTransferFrom(address(this), msg.sender, tokenIds[0]);

        for (uint i = 0; i < tokenIds.length; i++) {
            baseCharacterNft.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    // Fallback function must be declared as external.5
    fallback() external payable {
        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)
        emit Fallback(msg.value, gasleft());
    }

    receive() external payable {
        // custom function code
        emit Received(msg.value, gasleft());
    }

    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes calldata
    ) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}