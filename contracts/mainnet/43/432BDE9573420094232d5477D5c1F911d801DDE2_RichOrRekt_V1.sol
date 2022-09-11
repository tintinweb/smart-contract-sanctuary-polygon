// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/*
PRELUDE:
   This contract was written primarily as an opportunity to learn more about hardhat,
   VRF, and Moralis mechanics. While I believe this contract is safe and secure to use,
   it is sloppy about naming conventions, types (uint256 EVERYWHERE instead of using more
   appropriate sizes), and comments/documentation. This should most likely be converted
   into an upgradeable contract in the future. If you are reusing this contract 
   for any purposes, take this into consideration. DYOR. Yaya.

IMPORTANT NOTES:
   This contract is ONLY intended to be used with utility tokens that have no liquidity
   pool or monetary value. This is for entertainment purposes only.
*/

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** 
@title RichOrRekt - the Game 
@author wakingtheechoes
*/
contract RichOrRekt_V1 is VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;
    using Strings for string;
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Polygon Mainnet Coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // 200 gwei gas lane for Polygon Mainnet
    bytes32 keyHash =
        0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    // this is a massive callback gas limit. It works and doesn't seem to be a cost pain point... yet.
    uint32 callbackGasLimit = 600000;

    // Set to default 3
    uint16 requestConfirmations = 3;

    // For this use, retrieve 1 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    /// @notice erc20 payment token
    IERC20 public paymentToken;

    /// @notice Coinflip structure
    struct CoinFlipGame {
        address[] addresses;
        mapping(address => bool) addressLookup;
        address creator;
        bool isPublic;
        address[] gameAllowlist;
        uint16 maxEntriesPerWallet;
        uint256 entryFee;
        uint256 minEntrants;
        uint256 maxEntrants;
        address winner;
        uint256 prize;
        bool requestedRandom;
        bool completed;
        uint256 randomRequestID;
        uint256 randomWordReturned;
        string gameAlias;
    }

    // @dev split this struct out to a separate one since the CoinFlipGame struct
    // was hitting the 16 local variable limit and wouldn't compile:
    //
    // CompilerError: Stack too deep when compiling inline assembly:
    // Variable value0 is 2 slot(s) too deep inside the stack.
    struct GameMetadata {
        uint256 timeCreated;
        uint256 timeRan;
    }

    /// @notice main parameters for logic.
    uint256 public nextGameID;
    uint256[] public openGameIDs;
    bool public useVRF;
    bool public masterSwitchOn;
    uint256 public withdrawableBalance = 0;
    mapping(uint256 => CoinFlipGame) public gamesMapping;
    mapping(uint256 => GameMetadata) public gamesMetaMapping;

    //@dev this allows the fullfillWords function to properly update the right game.
    mapping(uint256 => uint256) public randomRequestsToGameIndices;

    // @dev these should be grouped into a "Player" struct in future update
    mapping(address => mapping(uint256 => uint16)) public walletGameEntries;
    mapping(address => uint256[]) public walletsToGamesEntered;
    mapping(address => string) public usernames;
    mapping(address => uint256) public totalEntryFees;
    mapping(address => uint256) public totalWinnings;

    /** @param subscriptionId Chainlink VRF subscription ID 
    @param paymentTokenAddress The ERC20 token that will be used as entries and winnings
    @param _useVRF Whether to use VRF to resolve games or to manually resolve them.
    @param _masterSwitch Turns on joining and creating games by general users.
    @dev This contract has only been tested with ERC20s with zero decimals
    */
    constructor(
        uint64 subscriptionId,
        address paymentTokenAddress,
        bool _useVRF,
        bool _masterSwitch
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        paymentToken = IERC20(paymentTokenAddress);
        useVRF = _useVRF;
        nextGameID = 1;
        masterSwitchOn = _masterSwitch;
    }

    /**
    @param _alias An alias username to map to the sender's wallet address
    @dev Usernames capped at an arbitrary length of 30 characters
    @notice Sets the sender's username to a specified string
    */
    function setUsername(string calldata _alias)
        external
        returns (string memory)
    {
        require(
            bytes(_alias).length < 31,
            "Usernames must not be longer than 30 characters"
        );
        usernames[msg.sender] = _alias;
        return usernames[msg.sender];
    }

    /**
    @dev Owner override of a username (in case of inappropriate username change)
    @param addressToChange The address being updated 
    @param _alias The username to update to.
    */
    function setUsernameOf(address addressToChange, string calldata _alias)
        external
        onlyOwner
        returns (string memory)
    {
        usernames[addressToChange] = _alias;
        return usernames[addressToChange];
    }

    /**
    @notice Gets single username from an address
    @param _address Address to fetch username for
    */
    function getUsernameOf(address _address)
        external
        view
        returns (string memory)
    {
        return usernames[_address];
    }

    /**
    @notice Gets a list of usernames based on a list of addresses
    @param _addresses a list of Addresses to fetch usernames of.
    @dev intention is to make a much more performant function to fetch a batch instead of making so many network calls. 
    */
    function getUsernamesOf(address[] calldata _addresses)
        external
        view
        returns (string[] memory)
    {
        string[] memory returnAddresses = new string[](_addresses.length);
        for (uint256 i; i < _addresses.length; i++) {
            returnAddresses[i] = usernames[_addresses[i]];
        }
        return returnAddresses;
    }

    /**
    @notice Set a game's readable alias to a new string
    @dev Only owner is intentional for now without a better moderation approach
    @param gameID ID of the game to modify
    @param _alias The updated readable name of the game 
    */
    function setGameAlias(uint256 gameID, string calldata _alias)
        external
        onlyOwner
        returns (string memory)
    {
        // There should be a check here for length of the alias
        // but with the function onlyOwner no need at this point.
        gamesMapping[gameID].gameAlias = _alias;
        return gamesMapping[gameID].gameAlias;
    }

    /**
    @notice Creates a new game. The creator has to pay the entry fee as creating the game will also enter it as the first entry.
    @param _entryFee The entry fee cost that all entries will pay when they join the game. The creator pays this when they create the game.
    @param _minEntrants The minimum number of entries for the game to be run. The game creator may run the game any time after this minimum is hit.
    @param _maxEntrants The maximum number of entries in the game. If someone joins and meets the maximum, the game will automatically run.
    @param _maxEntriesPerWallet The number of times a wallet may enter a single game. 
    @param _gameAllowList A list of addresses that may join a game along with the creator. It can serve as a private game 
    */
    function createGame(
        uint256 _entryFee,
        uint256 _minEntrants,
        uint256 _maxEntrants,
        uint16 _maxEntriesPerWallet,
        address[] calldata _gameAllowList
    ) external {
        require(
            _entryFee > 25000000000000000000,
            "Must require more than 25 STEAK to enter"
        );
        require(_minEntrants > 1, "Must have 2 or more min entries");
        require(
            _maxEntrants >= _minEntrants,
            "Max Entries must be greater than or equal to Min Entries"
        );
        require(
            _maxEntriesPerWallet > 0,
            "People must be allowed at least 1 entry per wallet"
        );
        require(
            masterSwitchOn == true || msg.sender == s_owner,
            "Contract not currently open for public to create games"
        );
        CoinFlipGame storage newGame = gamesMapping[nextGameID];
        newGame.creator = msg.sender;
        newGame.entryFee = _entryFee;
        newGame.minEntrants = _minEntrants;
        newGame.maxEntrants = _maxEntrants;
        newGame.maxEntriesPerWallet = _maxEntriesPerWallet;
        newGame.addresses.push(msg.sender);
        newGame.gameAllowlist = _gameAllowList; //untested
        newGame.addressLookup[msg.sender] = true;
        GameMetadata storage gameMeta = gamesMetaMapping[nextGameID];
        gameMeta.timeCreated = block.timestamp;

        walletGameEntries[msg.sender][nextGameID] = 1;
        walletsToGamesEntered[msg.sender].push(nextGameID);
        openGameIDs.push(nextGameID++);
        _proceedPayment(address(this), msg.sender, _entryFee);
        totalEntryFees[msg.sender] = totalEntryFees[msg.sender] + _entryFee;
    }

    /** 
    @notice Joins an existing and open game. Charges the sending wallet the entry fee and adds an entry to the game 
    @param gameID The gameID to join. 
    */
    function joinGame(uint256 gameID) external {
        require(gameID < nextGameID, "Game ID out of range");
        CoinFlipGame storage gameToJoin = gamesMapping[gameID];
        require(
            gameToJoin.addresses.length < gameToJoin.maxEntrants,
            "Game is already full"
        );
        require(
            gameToJoin.requestedRandom == false,
            "Game has already been run"
        );
        require(
            masterSwitchOn == true || msg.sender == s_owner,
            "Contract not currently open to join games"
        );
        if (walletGameEntries[msg.sender][gameID] > 0) {
            require(
                walletGameEntries[msg.sender][gameID]++ <
                    gameToJoin.maxEntriesPerWallet,
                "Reached max entry limit for this game"
            );
        } else {
            walletGameEntries[msg.sender][gameID] = 1;
        }

        // allowlist check
        bool isAllowedToJoin = false;
        if (
            gameToJoin.gameAllowlist.length == 0 ||
            gameToJoin.creator == msg.sender
        ) {
            isAllowedToJoin = true;
        } else {
            for (uint8 i; i < gameToJoin.gameAllowlist.length; ) {
                if (msg.sender == gameToJoin.gameAllowlist[i]) {
                    isAllowedToJoin = true;
                }
            }
        }
        require(isAllowedToJoin, "Not on game allow list");

        // got through all the eligibility checks. Add to the game and charge the entry fee.
        walletsToGamesEntered[msg.sender].push(nextGameID);
        gameToJoin.addresses.push(msg.sender);
        gameToJoin.addressLookup[msg.sender] = true;
        _proceedPayment(address(this), msg.sender, gameToJoin.entryFee);
        totalEntryFees[msg.sender] =
            totalEntryFees[msg.sender] +
            gameToJoin.entryFee;

        // run the game if full
        if (gameToJoin.addresses.length == gameToJoin.maxEntrants) {
            _runGame(gameID);
        }
    }

    /**
     * @notice Gets the list of all entries into a game by wallet address
     * @param gameID The ID of the game to fetch entries from
     */
    function getGameEntrants(uint256 gameID)
        public
        view
        returns (address[] memory)
    {
        return gamesMapping[gameID].addresses;
    }

    /**
     * @notice Gets the list of all allowed wallets for a game
     * @param gameID The ID of the game to fetch the allow list from
     */
    function getGameAllowlist(uint256 gameID)
        public
        view
        returns (address[] memory)
    {
        return gamesMapping[gameID].gameAllowlist;
    }

    /**
     * @notice This gets all games in an array, with the previously run ones having a zero value
     * @dev this function was superceded by getOnlyOpenGames
     */
    function getOpenGames() public view returns (uint256[] memory) {
        return openGameIDs;
    }

    /**
     * @notice Gets a list of all of the non-completed (but including actively running) game IDs
     */
    function getOnlyOpenGames() public view returns (uint256[] memory) {
        // following a pattern from https://stackoverflow.com/a/66233439
        uint256 openGameCount = 0;

        for (uint256 i; i < openGameIDs.length; i++) {
            if (openGameIDs[i] != 0) {
                openGameCount++;
            }
        }

        uint256[] memory openGames = new uint256[](openGameCount);
        uint256 j;
        for (uint256 i = 0; i < openGameIDs.length; i++) {
            if (openGameIDs[i] != 0) {
                openGames[j] = openGameIDs[i]; // step 3 - fill the array
                j++;
            }
        }

        return openGames; // step 4 - return
    }

    /**
     * @notice Manually start a game before it fills up.
     * @param gameID game ID to run
     * @dev this is only available by the contract owner OR when the minimum entries have been satisfied */
    function runGame(uint256 gameID) external {
        require(
            (msg.sender == gamesMapping[gameID].creator ||
                msg.sender == s_owner),
            "Must be the game creator or contract owner to manually run a game."
        );
        require(
            gamesMapping[gameID].addresses.length >=
                gamesMapping[gameID].minEntrants ||
                msg.sender == s_owner,
            "Not enough entrants to run this game"
        );
        require(
            gamesMapping[gameID].requestedRandom == false,
            "Random Winner already requested"
        );
        _runGame(gameID);
    }

    /**
     * @notice Cancels a game from running and refunds all entry fees
     * @param gameID The game to cancel
     */
    function cancelGame(uint256 gameID) external {
        require(
            (msg.sender == gamesMapping[gameID].creator ||
                msg.sender == s_owner),
            "Must be the game creator or contract owner to cancel a game."
        );

        // Covers both the just began case as well as the cancelled case to not let repeated cancellation happen
        require(
            gamesMapping[gameID].requestedRandom == false &&
                gamesMapping[gameID].completed == false,
            "Game has been started or completed. Cannot cancel"
        );

        // refund entry fees without taking a rake
        for (uint256 i = 0; i < gamesMapping[gameID].addresses.length; i++) {
            paymentToken.safeTransfer(
                gamesMapping[gameID].addresses[i],
                gamesMapping[gameID].entryFee
            );

            totalEntryFees[msg.sender] =
                totalEntryFees[msg.sender] -
                gamesMapping[gameID].entryFee;
        }
        // take it out of active game list
        for (uint256 i = 0; i < openGameIDs.length; i++) {
            if (openGameIDs[i] == gameID) {
                delete openGameIDs[i];
            }
        }

        // make it completed so that only one cancellation can be done at a time
        gamesMapping[gameID].completed = true;
    }

    /**
     * @notice the private function to kick off a game run.
     * @param gameID the game to run
     * @dev this can be called on a manual start or an auto start function call.
     */
    function _runGame(uint256 gameID) private {
        if (useVRF) {
            s_requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
        } else {
            s_requestId = gameID;
        }

        gamesMetaMapping[gameID].timeRan = block.timestamp;
        gamesMapping[gameID].requestedRandom = true;
        gamesMapping[gameID].randomRequestID = s_requestId;
        randomRequestsToGameIndices[s_requestId] = gameID;
    }

    function requestRandomWords() external onlyOwner {
        // Assumes the subscription is funded sufficiently.
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    // going to finish a game here.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        s_randomWords = randomWords;
        if (useVRF) {
            uint256 gameIndex = randomRequestsToGameIndices[requestId];
            _completeGame(gameIndex, randomWords[0]);
        }
    }

    /**
     * @notice Complete a game with a manually injected value
     * @param _gameIndex Game ID to complete
     * @param _fakeRandomWord randomness seed that will be modded to determine the winnner.
     * @dev games will stay in a `Requested Random` state until this is run if VRF toggle is turned off.*/
    function completeGameWithFauxRandom(
        uint256 _gameIndex,
        uint256 _fakeRandomWord
    ) external onlyOwner {
        require(
            useVRF == false,
            "VRF is turned on, so you can't finish a game without it"
        );
        _completeGame(_gameIndex, _fakeRandomWord);
    }

    /**
     * @notice updates the VRF subscription ID to a new value
     * @param subscriptionId a VRF Subscription from chainlink
     * @dev always need to add this contract as a consumer to the new subscription
     */
    function setSubscriptionID(uint64 subscriptionId)
        external
        onlyOwner
        returns (uint64)
    {
        s_subscriptionId = subscriptionId;
        return s_subscriptionId;
    }

    /**
     * @notice updates the VRF gas lane to a new value to `_keyHash`
     * @param _keyHash a gas lane hash from chainlink
     * @dev this determines the max gas cost to pay when fulfilling randomness.
     */
    function setGasLane(bytes32 _keyHash) external onlyOwner returns (bytes32) {
        keyHash = _keyHash;
        return keyHash;
    }

    /**
     * @notice Sets useVRF to a new value.
     * @param _useVRF the new boolean value to set the variable to
     * @dev this drives whether randomness comes from chainlink or manual values.
     */
    function setUseVRF(bool _useVRF) external onlyOwner returns (bool) {
        useVRF = _useVRF;
        return useVRF;
    }

    /**
     * @notice Sets masterSwitchOn to a new value
     * @param masterSwitchValue the new boolean value to set the variable to
     */
    function setMasterSwitch(bool masterSwitchValue)
        external
        onlyOwner
        returns (bool)
    {
        masterSwitchOn = masterSwitchValue;
        return masterSwitchOn;
    }

    /**
     * @notice Actually does the completion of the game and pays out winnings. It delegates the source of randomness to other parts of the contract.
     * @param _gameIndex Game ID to complete
     * @param _randomWord Source of randomness that determines the winner.
     */
    function _completeGame(uint256 _gameIndex, uint256 _randomWord) private {
        CoinFlipGame storage game = gamesMapping[_gameIndex];
        require(game.completed == false, "Game has already been completed");
        uint256 _winningIndex = _randomWord % game.addresses.length;
        game.winner = game.addresses[_winningIndex];
        game.randomWordReturned = _randomWord;
        game.completed = true;
        // Determine game prize

        uint256 gameFeePerEntrant = game.entryFee / uint256(20); // 5% rake, with a minimum of 25 UNIVRS safe for any values < 1

        game.prize =
            (game.entryFee - gameFeePerEntrant) *
            game.addresses.length;
        paymentToken.safeTransfer(game.winner, game.prize);
        totalWinnings[game.winner] = totalWinnings[game.winner] + game.prize;
        withdrawableBalance =
            withdrawableBalance +
            (gameFeePerEntrant * game.addresses.length);

        // take it out of active game list
        for (uint256 i = 0; i < openGameIDs.length; i++) {
            if (openGameIDs[i] == _gameIndex) {
                delete openGameIDs[i];
            }
        }
    }

    /**
     * @notice to proceed payment from buyer to seller
     * @dev only internal usage
     * @param buyer token payer
     * @param seller token payee
     * @param price amount of paymentToken to purchase nft
     */
    function _proceedPayment(
        address seller,
        address buyer,
        uint256 price
    ) private {
        paymentToken.safeTransferFrom(buyer, seller, price);
    }

    /**
    @notice Withdraws any rake collected from games that were completed
     */
    function withdraw() external onlyOwner {
        paymentToken.safeTransfer(msg.sender, withdrawableBalance);
        withdrawableBalance = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}

/*
   Dads and moms are role models
   Selfless is their name
   Kids will grow into adults
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}