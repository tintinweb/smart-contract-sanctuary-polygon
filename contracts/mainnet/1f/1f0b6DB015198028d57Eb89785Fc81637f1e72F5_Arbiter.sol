/*
  ________                           ____.       __
 /  _____/_____    _____   ____     |    |__ ___/  |_  ________ __
/   \  ___\__  \  /     \_/ __ \    |    |  |  \   __\/  ___/  |  \
\    \_\  \/ __ \|  Y Y  \  ___//\__|    |  |  /|  |  \___ \|  |  /
 \______  (____  /__|_|  /\___  >________|____/ |__| /____  >____/
        \/     \/      \/     \/                          \/
https://gamejutsu.app
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ECDSA.sol";
import "Address.sol";
import "IGameJutsuRules.sol";
import "IGameJutsuArbiter.sol";

/**
    @title GameJutsu Arbiter
    @notice gets cheaters bang to rights
    @notice ETHOnline2022 submission by ChainHackers
    @notice 2 players only for now to make it doable during the hackathon
    @notice Major source of inspiration: https://magmo.com/force-move-games.pdf
    @author Gene A. Tsvigun
    @author Vic G. Larson
  */
contract Arbiter is IGameJutsuArbiter {
    /**
        @custom startTime The moment one of the players gets fed up waiting for the other to make a move
        @custom gameMove GameMove structure with the last move of the complainer
        @custom stake Put your money where your mouth is - nefarious timeouts can be penalized by not returning stake
      */
    struct Timeout {
        uint256 startTime;
        GameMove gameMove;
        uint256 stake;
    }

    uint256 public constant TIMEOUT = 5 minutes;
    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
    bytes32 public immutable DOMAIN_SEPARATOR;
    /// @notice The EIP-712 typehash for the game move struct used by the contract
    bytes32 public constant GAME_MOVE_TYPEHASH = keccak256("GameMove(uint256 gameId,uint256 nonce,address player,bytes oldState,bytes newState,bytes move)");

    uint256 public DEFAULT_TIMEOUT = 5 minutes;
    uint256 public DEFAULT_TIMEOUT_STAKE = 0.1 ether;
    uint256 public NUM_PLAYERS = 2;

    mapping(uint256 => Game) public games;
    mapping(uint256 => Timeout) public timeouts;
    uint256 public nextGameId;

    modifier firstMoveSignedByAll(SignedGameMove[2] calldata signedMoves) {
        require(_isSignedByAllPlayersAndOnlyByPlayers(signedMoves[0]), "Arbiter: first move not signed by all players");
        _;
    }

    modifier lastMoveSignedByMover(SignedGameMove[2] calldata signedMoves) {
        require(_moveSignedByMover(signedMoves[1]), "Arbiter: first signature must belong to the player making the move");
        _;
    }

    modifier signedByMover(SignedGameMove calldata signedMove) {
        require(_moveSignedByMover(signedMove), "Arbiter: first signature must belong to the player making the move");
        _;
    }

    modifier onlyValidGameMove(GameMove calldata move) {
        require(_isValidGameMove(move), "Arbiter: invalid game move");
        _;
    }

    modifier onlyPlayer(SignedGameMove calldata signedMove){
        require(_playerInGame(signedMove.gameMove.gameId, signedMove.gameMove.player), "Arbiter: player not in game");
        _;
    }

    modifier movesInSequence(SignedGameMove[2] calldata moves) {
        for (uint256 i = 0; i < moves.length - 1; i++) {
            GameMove calldata currentMove = moves[i].gameMove;
            GameMove calldata nextMove = moves[i + 1].gameMove;
            require(currentMove.gameId == nextMove.gameId, "Arbiter: moves are for different games");
            require(currentMove.nonce + 1 == nextMove.nonce, "Arbiter: moves are not in sequence");
            require(keccak256(currentMove.newState) == keccak256(nextMove.oldState), "Arbiter: moves are not in sequence");
        }
        _;
    }

    modifier allValidGameMoves(SignedGameMove[2] calldata moves) {
        require(_allValidGameMoves(moves), "Arbiter: invalid game move");
        _;
    }

    modifier timeoutStarted(uint256 gameId) {
        require(_timeoutStarted(gameId), "Arbiter: timeout not started");
        _;
    }

    modifier timeoutNotStarted(uint256 gameId) {
        require(!_timeoutStarted(gameId), "Arbiter: timeout already started");
        _;
    }

    modifier timeoutExpired(uint256 gameId) {
        require(_timeoutExpired(gameId), "Arbiter: timeout not expired");
        _;
    }

    modifier timeoutNotExpired(uint256 gameId) {
        require(!_timeoutExpired(gameId), "Arbiter: timeout already expired");
        _;
    }

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("GameJutsu")), keccak256("0.1"), 137, 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC, bytes32(0x920dfa98b3727bbfe860dd7341801f2e2a55cd7f637dea958edfc5df56c35e4d)));
    }

    /**
        @notice Create a new game, define its rules and stake amount, put the stake on the table
        @param rules Rules contract address to use in conflict resolution
        @param sessionAddresses Addresses the proposer intends to use to sign moves
      */
    function proposeGame(IGameJutsuRules rules, address[] calldata sessionAddresses) payable external returns (uint256 gameId) {
        gameId = nextGameId;
        Game storage game = games[gameId];
        game.rules = rules;
        game.players[msg.sender] = 1;
        game.playersArray[0] = msg.sender;
        game.stake = msg.value;
        nextGameId++;
        emit GameProposed(address(rules), gameId, msg.value, msg.sender);
        if (sessionAddresses.length > 0) {
            for (uint256 i = 0; i < sessionAddresses.length; i++) {
                _registerSessionAddress(gameId, msg.sender, sessionAddresses[i]);
            }
        }
    }


    /**
        @notice Join a game, put the stake on the table
        @param gameId Game ID to join
        @param sessionAddresses Addresses the joiner intends to use to sign moves
      */
    function acceptGame(uint256 gameId, address[] calldata sessionAddresses) payable external {
        Game storage game = games[gameId];
        require(game.players[msg.sender] == 0, "Arbiter: player already in game");
        require(game.started == false, "Arbiter: game already started");
        require(game.playersArray[0] != address(0), "Arbiter: game not proposed");
        require(game.stake <= msg.value, "Arbiter: stake mismatch");
        game.players[msg.sender] = 2;
        game.playersArray[1] = msg.sender;
        game.stake += msg.value;
        game.started = true;

        emit GameStarted(address(game.rules), gameId, game.stake, game.playersArray);
        if (sessionAddresses.length > 0) {
            for (uint256 i = 0; i < sessionAddresses.length; i++) {
                _registerSessionAddress(gameId, msg.sender, sessionAddresses[i]);
            }
        }
    }

    /**
        @notice Register an additional session address to sign moves
        @notice This is useful if when changing browser sessions
        @param gameId The ID of the game being played
        @param sessionAddress Address the joiner intends to use to sign moves
      */
    function registerSessionAddress(uint256 gameId, address sessionAddress) external {
        require(games[gameId].players[msg.sender] > 0, "Arbiter: player not in game");
        require(games[gameId].started == true, "Arbiter: game not started");
        _registerSessionAddress(gameId, msg.sender, sessionAddress);
    }

    /**
        @notice Submit 2 most recent signed moves to the arbiter to finish the game
        @notice the first move must be signed by all players
        @notice the second move must be signed at least by the player making the move
        @notice the new state of the second move must be final -i.e. reported by the rules contract as such
        @param signedMoves Array of 2 signed moves
      */
    function finishGame(SignedGameMove[2] calldata signedMoves) external
    movesInSequence(signedMoves)
    returns (address winner){
        require(_isSignedByAllPlayersAndOnlyByPlayers(signedMoves[0]), "Arbiter: first move not signed by all players");
        require(_moveSignedByMover(signedMoves[1]), "Arbiter: second move not signed by mover");

        uint256 gameId = signedMoves[0].gameMove.gameId;
        require(_isGameOn(gameId), "Arbiter: game not active");
        require(signedMoves[1].gameMove.gameId == gameId, "Arbiter: game ids mismatch");
        require(_isValidGameMove(signedMoves[1].gameMove), "Arbiter: invalid game move");

        IGameJutsuRules.GameState memory newState = IGameJutsuRules.GameState(
            gameId,
            signedMoves[1].gameMove.nonce + 1,
            signedMoves[1].gameMove.newState);
        IGameJutsuRules rules = games[gameId].rules;
        require(rules.isFinal(newState), "Arbiter: game state not final");
        for (uint8 i = 0; i < NUM_PLAYERS; i++) {
            if (rules.isWin(newState, i)) {
                winner = games[gameId].playersArray[i];
                address loser = _opponent(gameId, winner);
                _finishGame(gameId, winner, loser, false);
                return winner;
            }
        }
        _finishGame(gameId, address(0), address(0), true);
        return address(0);
    }

    /**
        @notice Resign from a game and forfeit the stake
        @notice The caller's opponent wins
        @param gameId The ID of the game being played
      */
    function resign(uint256 gameId) external {
        require(_isGameOn(gameId), "Arbiter: game not active");
        require(games[gameId].players[msg.sender] != 0, "Arbiter: player not in game");
        address loser = msg.sender;
        address winner = _opponent(gameId, loser);
        _finishGame(gameId, winner, loser, false);
        emit PlayerResigned(gameId, loser);
    }

    /**
        @notice Dispute a cheat move by a player
        @param signedMove The signed move to be validated
      */
    function disputeMove(SignedGameMove calldata signedMove) external
    signedByMover(signedMove)
    {
        GameMove calldata gm = signedMove.gameMove;
        require(!_isValidGameMove(gm), "Arbiter: valid move disputed");

        Game storage game = games[gm.gameId];
        require(game.started && !game.finished, "Arbiter: game not started yet or already finished");
        require(game.players[gm.player] != 0, "Arbiter: player not in game");

        disqualifyPlayer(gm.gameId, gm.player);
    }

    function disputeMoveWithHistory(SignedGameMove[2] calldata signedMoves) external {
        //TODO add dispute move version based on comparison to previously signed moves
    }

    /**
        @notice both moves must be in sequence
        @notice first move must be signed by both players
        @notice second move must be signed at least by the player making the move
        @notice no timeout should be active for the game
       */
    function initTimeout(SignedGameMove[2] calldata moves) payable external
    firstMoveSignedByAll(moves)
    lastMoveSignedByMover(moves)
    timeoutNotStarted(moves[0].gameMove.gameId)
    movesInSequence(moves)
    allValidGameMoves(moves)
    {
        require(msg.value == DEFAULT_TIMEOUT_STAKE, "Arbiter: timeout stake mismatch");
        uint256 gameId = moves[0].gameMove.gameId;
        timeouts[gameId].stake = msg.value;
        timeouts[gameId].gameMove = moves[1].gameMove;
        timeouts[gameId].startTime = block.timestamp;
        emit TimeoutStarted(gameId, moves[1].gameMove.player, moves[1].gameMove.nonce, block.timestamp + TIMEOUT);
    }

    /**
        @notice a single valid signed move is enough to resolve the timout
        @notice the move must be signed by the player whos turn it is
        @notice the move must continue the game from the move started the timeout
       */
    function resolveTimeout(SignedGameMove calldata signedMove) external
    timeoutStarted(signedMove.gameMove.gameId)
    timeoutNotExpired(signedMove.gameMove.gameId)
    signedByMover(signedMove)
    onlyValidGameMove(signedMove.gameMove)
    onlyPlayer(signedMove)
    {
        uint256 gameId = signedMove.gameMove.gameId;
        GameMove storage timeoutMove = timeouts[gameId].gameMove;
        require(timeoutMove.gameId == signedMove.gameMove.gameId, "Arbiter: game ids mismatch");
        require(timeoutMove.nonce + 1 == signedMove.gameMove.nonce, "Arbiter: nonce mismatch");
        require(timeoutMove.player != signedMove.gameMove.player, "Arbiter: same player");
        require(keccak256(timeoutMove.newState) == keccak256(signedMove.gameMove.oldState), "Arbiter: state mismatch");
        _clearTimeout(gameId);
        emit TimeoutResolved(gameId, signedMove.gameMove.player, signedMove.gameMove.nonce);
    }

    /**
        @notice the timeout must be expired
        @notice 2 player games only
       */
    function finalizeTimeout(uint256 gameId) external
    timeoutExpired(gameId)
    {
        address loser = _opponent(gameId, timeouts[gameId].gameMove.player);
        disqualifyPlayer(gameId, loser);
        _clearTimeout(gameId);
    }

    /**
        @notice Get addresses of players in a game
        @param gameId The ID of the game being played
       */
    function getPlayers(uint256 gameId) external view returns (address[2] memory){
        return games[gameId].playersArray;
    }

    /**
        @notice Validate a game move without signatures
        @param gameMove The move to be validated
       */
    function isValidGameMove(GameMove calldata gameMove) external view returns (bool) {
        return _isValidGameMove(gameMove);
    }

    /**
        @notice Validate a signed game move
        @param signedMove The move to be validated
       */
    function isValidSignedMove(SignedGameMove calldata signedMove) external view returns (bool) {
        return _isValidSignedMove(signedMove);
    }

    function disqualifyPlayer(uint256 gameId, address cheater) private {
        require(games[gameId].players[cheater] != 0, "Arbiter: player not in game");
        games[gameId].finished = true;
        address winner = games[gameId].playersArray[0] == cheater ? games[gameId].playersArray[1] : games[gameId].playersArray[0];
        payable(winner).transfer(games[gameId].stake);
        emit GameFinished(gameId, winner, cheater, false);
        emit PlayerDisqualified(gameId, cheater);
    }

    function _finishGame(uint256 gameId, address winner, address loser, bool draw) private {
        games[gameId].finished = true;
        if (draw) {
            uint256 half = games[gameId].stake / 2;
            uint256 theOtherHalf = games[gameId].stake - half;
            payable(games[gameId].playersArray[0]).transfer(half);
            payable(games[gameId].playersArray[1]).transfer(theOtherHalf);
        } else {
            payable(winner).transfer(games[gameId].stake);
        }
        emit GameFinished(gameId, winner, loser, draw);
    }

    function _registerSessionAddress(uint256 gameId, address player, address sessionAddress) private {
        games[gameId].players[sessionAddress] = games[gameId].players[player];
        emit SessionAddressRegistered(gameId, player, sessionAddress);
    }

    function _clearTimeout(uint256 gameId) private {
        Address.sendValue(payable(timeouts[gameId].gameMove.player), timeouts[gameId].stake);
        delete timeouts[gameId];
    }

    function getSigners(SignedGameMove calldata signedMove) private view returns (address[] memory) {
        address[] memory signers = new address[](signedMove.signatures.length);
        for (uint256 i = 0; i < signedMove.signatures.length; i++) {
            signers[i] = recoverAddress(signedMove.gameMove, signedMove.signatures[i]);
        }
        return signers;
    }

    function recoverAddress(GameMove calldata gameMove, bytes calldata signature) private view returns (address){
        //        https://codesandbox.io/s/gamejutsu-moves-eip712-no-nested-types-p5fnzf?file=/src/index.js
        bytes32 structHash = keccak256(abi.encode(
                GAME_MOVE_TYPEHASH,
                gameMove.gameId,
                gameMove.nonce,
                gameMove.player,
                keccak256(gameMove.oldState),
                keccak256(gameMove.newState),
                keccak256(gameMove.move)
            ));
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
        return ECDSA.recover(digest, signature);
    }

    function _opponent(uint256 gameId, address player) private view returns (address){
        return games[gameId].playersArray[2 - games[gameId].players[player]];
    }

    /**
        @dev checks only state transition validity, all the signatures are checked elsewhere
    */
    function _isValidGameMove(GameMove calldata move) private view returns (bool) {
        Game storage game = games[move.gameId];
        IGameJutsuRules.GameState memory oldGameState = IGameJutsuRules.GameState(move.gameId, move.nonce, move.oldState);
        return keccak256(move.oldState) != keccak256(move.newState) &&
        game.started &&
        !game.finished &&
        game.players[move.player] != 0 &&
        game.rules.isValidMove(oldGameState, game.players[move.player] - 1, move.move) &&
        keccak256(game.rules.transition(oldGameState, game.players[move.player] - 1, move.move).state) == keccak256(move.newState);
    }

    /**
        @dev checks state transition validity and signatures, first signature must be by the player making the move
    */
    function _isValidSignedMove(SignedGameMove calldata move) private view returns (bool) {
        if (!_moveSignedByMover(move)) {
            return false;
        }

        for (uint i = 1; i < move.signatures.length; i++) {
            if (!_playerInGame(move.gameMove.gameId, recoverAddress(move.gameMove, move.signatures[i]))) {
                return false;
            }
        }
        return _isValidGameMove(move.gameMove);
    }

    function _isGameOn(uint256 gameId) private view returns (bool) {
        return games[gameId].started && !games[gameId].finished;
    }

    function _isSignedByAllPlayersAndOnlyByPlayers(SignedGameMove calldata signedMove) private view returns (bool) {
        address[] memory signers = getSigners(signedMove);
        bool[2] memory signersPresent;
        if (signers.length != NUM_PLAYERS) {
            return false;
        }
        for (uint256 i = 0; i < signers.length; i++) {
            uint8 oneBasedPlayerId = games[signedMove.gameMove.gameId].players[signers[i]];
            if (oneBasedPlayerId == 0) {
                return false;
            }
            signersPresent[oneBasedPlayerId - 1] = true;
        }
        return signersPresent[0] && signersPresent[1];
    }

    function _timeoutStarted(uint256 gameId) private view returns (bool) {
        return timeouts[gameId].startTime != 0;
    }

    function _timeoutExpired(uint256 gameId) private view returns (bool) {
        return _timeoutStarted(gameId) && timeouts[gameId].startTime + TIMEOUT < block.timestamp;
    }

    function _allValidGameMoves(SignedGameMove[2] calldata moves) private view returns (bool) {
        for (uint256 i = 0; i < moves.length; i++) {
            if (!_isValidGameMove(moves[i].gameMove)) {
                return false;
            }
        }
        return true;
    }

    function _moveSignedByMover(SignedGameMove calldata move) private view returns (bool) {
        address signer = recoverAddress(move.gameMove, move.signatures[0]);
        uint256 gameId = move.gameMove.gameId;
        return games[gameId].players[signer] == games[gameId].players[move.gameMove.player];
    }

    function _playerInGame(uint256 gameId, address player) private view returns (bool) {
        return games[gameId].players[player] != 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/*
  ________                           ____.       __
 /  _____/_____    _____   ____     |    |__ ___/  |_  ________ __
/   \  ___\__  \  /     \_/ __ \    |    |  |  \   __\/  ___/  |  \
\    \_\  \/ __ \|  Y Y  \  ___//\__|    |  |  /|  |  \___ \|  |  /
 \______  (____  /__|_|  /\___  >________|____/ |__| /____  >____/
        \/     \/      \/     \/                          \/
https://gamejutsu.app
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title GameJutsu Rules
    @notice "The fewer rules a coach has, the fewer rules there are for players to break." (John Madden)
    @notice ETHOnline2022 submission by ChainHackers
    @author Gene A. Tsvigun
  */
interface IGameJutsuRules {
    struct GameState {
        uint256 gameId;
        uint256 nonce;
        bytes state;
    }

    function isValidMove(GameState calldata state, uint8 playerId, bytes calldata move) external pure returns (bool);

    function transition(GameState calldata state, uint8 playerId, bytes calldata move) external pure returns (GameState memory);

    function defaultInitialGameState() external pure returns (bytes memory);

    function isFinal(GameState calldata state) external pure returns (bool);

    function isWin(GameState calldata state, uint8 playerId) external pure returns (bool);
}

/*
  ________                           ____.       __
 /  _____/_____    _____   ____     |    |__ ___/  |_  ________ __
/   \  ___\__  \  /     \_/ __ \    |    |  |  \   __\/  ___/  |  \
\    \_\  \/ __ \|  Y Y  \  ___//\__|    |  |  /|  |  \___ \|  |  /
 \______  (____  /__|_|  /\___  >________|____/ |__| /____  >____/
        \/     \/      \/     \/                          \/
https://gamejutsu.app
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IGameJutsuRules.sol";

/**
    @title GameJutsu Arbiter
    @notice gets cheaters bang to rights
    @notice ETHOnline2022 submission by ChainHackers
    @notice 2 players only for now to make it doable during the hackathon
    @author Gene A. Tsvigun
    @dev https://codesandbox.io/s/gamejutsu-moves-eip712-mvrh8v?file=/src/index.js
  */
interface IGameJutsuArbiter {
    /**
        @notice What the Arbiter knows about the game
        @custom rules the contract defining the rules of the game
        @custom stake the amount of the chain's native currency to stake for the game
        @custom started whether the game has started
        @custom finished whether the game has finished
        @custom players the players and their session addresses
        @custom playersArray both players addresses
      */
    struct Game {
        IGameJutsuRules rules;
        uint256 stake;
        bool started;
        bool finished;
        mapping(address => uint8) players;
        address[2] playersArray;
    }

    /**
        @notice The way players present their moves to the Arbiter
        @custom gameId the id of the game
        @custom nonce the nonce of the move - how many moves have been made before this one, for the first move it is 0
        @custom player the address of the player making the move
        @custom oldState the state of the game before the move, the player declares it to be the actual state
        @custom newState the state of the game after the move, must be a valid transition from the oldState
        @custom move the move itself, must be consistent with the newState
      */
    struct GameMove {
        uint256 gameId;
        uint256 nonce;
        address player;
        bytes oldState;
        bytes newState;
        bytes move;
    }

    /**
        @notice Signed game move with players' signatures
        @custom gameMove GameMove struct
        @custom signatures the signatures of the players signing  `abi.encode`d gameMove
      */
    struct SignedGameMove {
        GameMove gameMove;
        bytes[] signatures;
    }

    event GameProposed(address indexed rules, uint256 gameId, uint256 stake, address indexed proposer);
    event GameStarted(address indexed rules, uint256 gameId, uint256 stake, address[2] players);
    event GameFinished(uint256 gameId, address winner, address loser, bool isDraw);
    event PlayerDisqualified(uint256 gameId, address player);
    event PlayerResigned(uint256 gameId, address player);
    event SessionAddressRegistered(uint256 gameId, address player, address sessionAddress);
    event TimeoutStarted(uint256 gameId, address player, uint256 nonce, uint256 timeout);
    event TimeoutResolved(uint256 gameId, address player, uint256 nonce);

    function proposeGame(IGameJutsuRules rules, address[] calldata sessionAddresses) payable external returns (uint256 gameId);

    function acceptGame(uint256 gameId, address[] calldata sessionAddresses) payable external;

    function registerSessionAddress(uint256 gameId, address sessionAddress) external;

    function disputeMove(SignedGameMove calldata signedMove) external; //TODO mark the most important methods

    function disputeMoveWithHistory(SignedGameMove[2] calldata signedMoves) external;

    function finishGame(SignedGameMove[2] calldata signedMoves) external returns (address winner);

    function resign(uint256 gameId) external;

    function initTimeout(SignedGameMove[2] calldata signedMoves) payable external;

    function resolveTimeout(SignedGameMove calldata signedMove) external;

    function finalizeTimeout(uint256 gameId) external;

    //TODO penalize griefers for starting timeouts despite valid moves being published, needs timing in SignedGameMove

    function games(uint256 gameId) external view returns (IGameJutsuRules rules, uint256 stake, bool started, bool finished);

    function getPlayers(uint256 gameId) external view returns (address[2] memory);

    function isValidGameMove(GameMove calldata gameMove) external view returns (bool);

    function isValidSignedMove(SignedGameMove calldata signedMove) external view returns (bool);
}