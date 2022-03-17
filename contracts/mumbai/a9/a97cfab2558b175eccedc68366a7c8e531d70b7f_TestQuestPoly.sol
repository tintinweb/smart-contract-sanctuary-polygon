/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: Unlicense
interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IDrawSvg {
  function drawSvg(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
  function drawSvgNew(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
}

interface INameChange {
  function changeName(address owner, uint256 id, string memory newName) external;
}

interface IDogewood {
    // struct to store each token's traits
    struct Doge2 {
        uint8 head;
        uint8 breed;
        uint8 color;
        uint8 class;
        uint8 armor;
        uint8 offhand;
        uint8 mainhand;
        uint16 level;
        uint16 breedRerollCount;
        uint16 classRerollCount;
        uint8 artStyle; // 0: new, 1: old
    }

    function getTokenTraits(uint256 tokenId) external view returns (Doge2 memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwnerOfDoge(uint256 id, address who_) external view returns (bool);
    function unstakeForQuest(address[] memory owners, uint256[] memory ids) external;
    function updateQuestCooldown(uint256[] memory doges, uint88 timestamp) external;
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level, uint16 breedRerollCount, uint16 classRerollCount, uint8 artStyle) external;
    function transfer(address to, uint256 tokenId) external;
    // function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
}

// interface DogeLike {
//     function pull(address owner, uint256[] calldata ids) external;
//     function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level) external;
//     function transfer(address to, uint256 tokenId) external;
//     function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

// interface DogewoodLike {
//     function ownerOf(uint256 id) external view returns (address owner_);
//     function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
//     function doges(uint256 dogeId) external view returns (uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface QuestLike {
    struct GroupConfig {
        uint16 lvlFrom;
        uint16 lvlTo;
        uint256 entryFee; // additional entry $TREAT
        uint256 initPrize; // init prize pool $TREAT
    }
    struct Leaderboard {
        uint256 performId; // unique id to distinguish leaderboard updates
        uint88 timestamp;
        uint256 prizePool; // daily total gathered to distribute
        uint256 prizeAmount; // 40%
        uint256 burnAmount; // 55%
        uint256 teamAmount; // 5%
        mapping(uint256 => Action) winners; // Action[5] winners; rank => Action
        mapping(uint256 => uint256[]) scores; // rank => finalScore
    }
    struct Action {
        uint256 id; // unique id to distinguish activities
        uint88 timestamp;
        uint256[] doges;
        address[] owners;
        uint256[] scores;
    }

    function doQuestByAdmin(uint256[] memory doges, address[] memory owners, uint256[] memory scores, uint8 groupIndex) external;
}

interface IOracle {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface IVRF {
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom2(string memory seed) external returns (uint256);
    function getRand(uint256 nonce) external view returns (uint256);
    function getRange(uint min, uint max,uint nonce) external view returns(uint);
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)
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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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

interface KeeperCompatibleInterface {
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

/**
 * QuestPoly should be added to auth of TreatPoly
 * QuestPoly should be added to auth of OracleVRF
 * quest sender should be added to auth of QuestPoly
 * Note: Dogewood should set this address to quest variable
 */
contract QuestPoly is KeeperCompatibleInterface { // proxy implementation
    using ECDSA for bytes32;

    address implementation_;
    address public admin;
    mapping(address => bool) public auth;

    IDogewood public dogewood;
    ERC20Like public treat; // Quest contract address should be added to auth list of TREAT
    address public teamTreasury; // team treasury wallet address
    IVRF public vrf; // random generator

    uint256 public constant WINNER_COUNT = 5;
    mapping(uint256 => uint256) public winnerEntryConfig; //  winner's earned entry. (rank => entryCount)
    uint256 public winnerEntryTotal; // total entry count of winners
    mapping(uint256 => uint256) public winnerPrizeAllocConfig; // winner's prize alloc point. total: 10000 (rank => allocPoint)
    uint256 totalPrizeAllocPoint;

    uint8 public constant GROUP_COUNT = 4;
    mapping(uint8 => QuestLike.GroupConfig) public groupConfig; // groupId => GroupConfig
    mapping(uint8 => QuestLike.Leaderboard) public leaderboard; // (groupIndex => board)
    mapping(uint8 => uint256) public prizePool; // (groupIndex => prizeAmount)
    uint256 public lastLeaderboardTimestamp; // last calculated timestamp of winners

    uint256 public _currentPerformId; // increament when perform leaderboard
    uint256 public _currentActionId; // increament when doing quest
    mapping(uint8 => QuestLike.Action[]) public activities; // groupId => actions
    // mapping(uint8 => mapping(uint256 => QuestLike.Action)) public activities; // groupId => index => action
    mapping(uint8 => uint256) public activityLengths; // groupId => actionCount

    mapping(address => ScoreLog) public ownerScores; // owner score log in a day. (owner => scoreLog)
    mapping(uint256 => DogeEntryLog) public dogeEntryLog; // daily entry count log. (dogeId => entryLog)

    // earned entry points variables
    mapping(uint8 => uint256) public groupEarnedEntryCount; // last earned entry count of group (groupId => entryCount)

    /*///////////////////////////////////////////////////////////////
                    EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event NewQuest(uint256 indexed performId, uint256 indexed actionId, uint8 indexed groupIndex, QuestLike.Action action);
    event ScoreUpdate(uint256 performId, uint256 actionId, address indexed owner, uint256 newScore, uint256 oldScore, uint256 i, uint88 timestamp);
    event LeaderboardTimestamp(uint256 indexed performId, uint256 indexed actionId, uint88 indexed timestamp);
    event LeaderboardPerform(
        uint256 indexed performId, uint256 actionId, uint88 indexed timestamp,
        uint8 indexed groupIndex,
        LbInfo lbInfo,
        LbMappingInfo lbMappingInfo
    );

    /*///////////////////////////////////////////////////////////////
                    STRUCTURE
    //////////////////////////////////////////////////////////////*/

    struct DogeEntryLog {
        uint88 timestamp;
        uint256 entryCount; // actions count that doge quested in that day
    }
    struct ScoreLog {
        uint88 timestamp;
        uint256 score; // owner score in that day
    }
    struct LbInfo {
        uint256 performId; uint88 timestamp; uint256 prizePool; uint256 prizeAmount; uint256 burnAmount; uint256 teamAmount;
    }
    struct LbMappingInfo {
        QuestLike.Action[WINNER_COUNT] winners;
        uint256[][WINNER_COUNT] scores;
    }

    /*///////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(address dogewood_, address treat_, address teamTreasury_, address vrf_) external {
        require(msg.sender == admin);

        dogewood = IDogewood(dogewood_);
        treat = ERC20Like(treat_);
        teamTreasury = teamTreasury_;
        vrf = IVRF(vrf_);

        // init group info
        groupConfig[0] = QuestLike.GroupConfig(1, 5, 1 ether, 30 ether);
        groupConfig[1] = QuestLike.GroupConfig(6, 10, 2 ether, 60 ether);
        groupConfig[2] = QuestLike.GroupConfig(11, 15, 5 ether, 100 ether);
        groupConfig[3] = QuestLike.GroupConfig(16, 20, 10 ether, 250 ether);

        // winners entry
        winnerEntryConfig[0] = 20; // rank 1 earns 20 entries
        winnerEntryConfig[1] = 15; // rank 2 earns 15 entries
        winnerEntryConfig[2] = 10; // rank 3 earns 10 entries
        winnerEntryConfig[3] = 6; // rank 4 earns 6 entries
        winnerEntryConfig[4] = 3; // rank 5 earns 3 entries
        winnerEntryTotal = 20 + 15 + 10 + 6 + 3;

        // winnerPrizeAllocConfig
        for (uint256 i = 0; i < WINNER_COUNT; i++) {
            winnerPrizeAllocConfig[i] = 10000 / WINNER_COUNT;
        }
        totalPrizeAllocPoint = winnerPrizeAllocConfig[0] * WINNER_COUNT;

        lastLeaderboardTimestamp = block.timestamp;
    }

    function setAuth(address[] calldata adds_, bool status) external {
        require(msg.sender == admin, "not admin");
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }

    function updateGroupConfig(uint8 id, uint16 lvlFrom_, uint16 lvlTo_, uint256 entryFee_, uint256 initPrize_) external {
        require(msg.sender == admin, "not admin");

        groupConfig[id].lvlFrom = lvlFrom_;
        groupConfig[id].lvlTo = lvlTo_;
        groupConfig[id].entryFee = entryFee_;
        groupConfig[id].initPrize = initPrize_;
    }

    function updateWinnerEntryConfig(uint id, uint256 entry_) external {
        require(msg.sender == admin, "not admin");
        winnerEntryTotal = winnerEntryTotal + entry_ - winnerEntryConfig[id];
        winnerEntryConfig[id] = entry_;
    }

    function updateWinnerPrizeAllocConfig(uint id, uint256 allocPoint) external {
        require(msg.sender == admin, "not admin");
        totalPrizeAllocPoint = totalPrizeAllocPoint + allocPoint - winnerPrizeAllocConfig[id];
        winnerPrizeAllocConfig[id] = allocPoint;
    }

    function changeVRF(IVRF vrf_) external {
        require(msg.sender == admin, "not admin");
        vrf = vrf_;
    }

    function changeTeamTreasury(address teamTreasury_) external {
        require(msg.sender == admin, "not admin");
        teamTreasury = teamTreasury_;
    }

    /*///////////////////////////////////////////////////////////////
                    OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Add quest log to the contract
     * Should be called by admins
     * @param doges array of doge Ids
     * @param scores array of scores
     * @param groupIndex array of group index 0-4
     */
    function doQuestByUser(uint256[] memory doges, uint256[] memory scores, uint8 groupIndex, bytes memory signature) external {
        require(doges.length > 0, "invalid input");
        require(doges.length == scores.length, "invalid input");

        // admin signature validation to prevent forge
        bytes32 params_;
        for (uint256 i = 0; i < doges.length; i++) {
            params_ = keccak256(abi.encodePacked(params_, doges[i], scores[i]));
        }
        bytes32 hash = keccak256(abi.encodePacked(params_, groupIndex, msg.sender));
        address signer = hash.toEthSignedMessageHash().recover(signature);
        // require(auth[signer] == true, "invalid signer"); // TODO -- it will be active when unity team is ready

        // groupIndex validation
        require(groupIndex < GROUP_COUNT, "invalid group index"); // total group count is 4

        // doges level validation
        for (uint256 i = 0; i < doges.length; i++) {
            IDogewood.Doge2 memory s = dogewood.getTokenTraits(doges[i]);
            require(s.level > 0, "still in reroll cooldown");
            require(groupConfig[groupIndex].lvlFrom <= s.level && groupConfig[groupIndex].lvlTo >= s.level, "invalid group index");
        }

        address[] memory owners = new address[](doges.length);
        // doge owner validation, and unstake doges first to quest
        for (uint256 i = 0; i < doges.length; i++) {
            owners[i] = msg.sender;
            require(dogewood.validateOwnerOfDoge(doges[i], msg.sender), "invalid owner");
        }
        dogewood.unstakeForQuest(owners, doges);

        _currentActionId++;
        uint88 timestamp = uint88(block.timestamp);

        // entry check
        for (uint256 i = 0; i < doges.length; i++) {
            if(dogeEntryLog[doges[i]].timestamp < lastLeaderboardTimestamp) {
                dogeEntryLog[doges[i]].timestamp = timestamp;
                dogeEntryLog[doges[i]].entryCount = 0;
            }

            if(dogeEntryLog[doges[i]].entryCount == 0) dogeEntryLog[doges[i]].entryCount = 1; // free entry
            else {
                dogeEntryLog[doges[i]].entryCount++;
                // burn $TREAT from the user
                treat.burn(owners[i], groupConfig[groupIndex].entryFee);
                // add $TREAT to prize pool
                prizePool[groupIndex] += groupConfig[groupIndex].entryFee;
            }
            dogeEntryLog[doges[i]].timestamp = timestamp;

            // update owner scores
            uint256 oldScore_ = getOwnerScore(owners[i]);
            ownerScores[owners[i]].timestamp = timestamp;
            ownerScores[owners[i]].score = oldScore_ + scores[i];
            // uint256 oldScore_ = ownerScores[owners[i]].score;
            // if(ownerScores[owners[i]].timestamp < lastLeaderboardTimestamp) { // no score existing during current period
            //     ownerScores[owners[i]].score = scores[i];
            // } else { // score already existing during current period
            //     ownerScores[owners[i]].score += scores[i];
            // }
            emit ScoreUpdate(_currentPerformId, _currentActionId, owners[i], ownerScores[owners[i]].score, oldScore_, i, timestamp);
        }
        // cooldown update
        dogewood.updateQuestCooldown(doges, timestamp);

        // add activity
        QuestLike.Action memory action = QuestLike.Action(_currentActionId, timestamp, doges, owners, scores);
        _addActivity(groupIndex, action);

        emit NewQuest(_currentPerformId, _currentActionId, groupIndex, action);
    }

    /**
     * Add quest log to the contract
     * Should be called by admins
     * @param doges array of doge Ids
     * @param owners array of doge owners
     * @param scores array of scores
     * @param groupIndex array of group index 0-4
     */
    function doQuestByAdmin(uint256[] memory doges, address[] memory owners, uint256[] memory scores, uint8 groupIndex) external {
        require(auth[msg.sender] == true, "no auth");

        require(doges.length > 0, "invalid input");
        require(doges.length == owners.length, "invalid input");
        require(doges.length == scores.length, "invalid input");

        // groupIndex validation
        require(groupIndex < GROUP_COUNT, "invalid group index"); // total group count is 4

        // doges level validation
        for (uint256 i = 0; i < doges.length; i++) {
            IDogewood.Doge2 memory s = dogewood.getTokenTraits(doges[i]);
            require(s.level > 0, "still in reroll cooldown");
            require(groupConfig[groupIndex].lvlFrom <= s.level && groupConfig[groupIndex].lvlTo >= s.level, "invalid group index");
        }

        // doge owner validation, and unstake doges first to quest
        dogewood.unstakeForQuest(owners, doges);

        _currentActionId++;
        uint88 timestamp = uint88(block.timestamp);

        // entry check
        for (uint256 i = 0; i < doges.length; i++) {
            if(dogeEntryLog[doges[i]].timestamp < lastLeaderboardTimestamp) {
                dogeEntryLog[doges[i]].timestamp = timestamp;
                dogeEntryLog[doges[i]].entryCount = 0;
            }

            if(dogeEntryLog[doges[i]].entryCount == 0) dogeEntryLog[doges[i]].entryCount = 1; // free entry
            else {
                dogeEntryLog[doges[i]].entryCount++;
                // burn $TREAT from the user
                treat.burn(owners[i], groupConfig[groupIndex].entryFee);
                // add $TREAT to prize pool
                prizePool[groupIndex] += groupConfig[groupIndex].entryFee;
            }
            dogeEntryLog[doges[i]].timestamp = timestamp;

            // update owner scores
            uint256 oldScore_ = getOwnerScore(owners[i]);
            ownerScores[owners[i]].timestamp = timestamp;
            ownerScores[owners[i]].score = oldScore_ + scores[i];
            // uint256 oldScore_ = ownerScores[owners[i]].score;
            // if(ownerScores[owners[i]].timestamp < lastLeaderboardTimestamp) { // no score existing during current period
            //     ownerScores[owners[i]].score = scores[i];
            // } else { // score already existing during current period
            //     ownerScores[owners[i]].score += scores[i];
            // }
            emit ScoreUpdate(_currentPerformId, _currentActionId, owners[i], ownerScores[owners[i]].score, oldScore_, i, timestamp);
        }
        // cooldown update
        dogewood.updateQuestCooldown(doges, timestamp);

        // add activity
        QuestLike.Action memory action = QuestLike.Action(_currentActionId, timestamp, doges, owners, scores);
        _addActivity(groupIndex, action);

        emit NewQuest(_currentPerformId, _currentActionId, groupIndex, action);
    }

    // Leaderboard winner select - this should be called by cron timer everyday
    function performLeaderboard() external virtual {
        require(block.timestamp >= (((lastLeaderboardTimestamp / 24 hours) + 1) * 24 hours), "should wait more");
        _performLeaderboard();
    }

    function emergencyPerformLeaderboard() external {
        require(msg.sender == admin, "not admin");
        require(block.timestamp >= (((lastLeaderboardTimestamp / 24 hours) + 1) * 24 hours), "should wait more");
        _performLeaderboard();
    }

    function _performLeaderboard() internal {
        _currentPerformId++;
        uint88 timestamp = uint88(block.timestamp);

        uint256 teamAmount_;
        for (uint8 gid = 0; gid < GROUP_COUNT; gid++) {

            // get raffle entry count
            uint256 raffleEntries = activityLengths[gid] + groupEarnedEntryCount[gid];
            if(raffleEntries == 0) {
                for (uint256 rank_ = 0; rank_ < WINNER_COUNT; rank_++) {
                    if(leaderboard[gid].winners[rank_].owners.length > 0) delete leaderboard[gid].winners[rank_];
                    if(leaderboard[gid].scores[rank_].length > 0) delete leaderboard[gid].scores[rank_];
                }
                leaderboard[gid].performId = _currentPerformId;
                leaderboard[gid].timestamp = timestamp;
                leaderboard[gid].prizePool = 0;
                leaderboard[gid].prizeAmount = 0;
                leaderboard[gid].burnAmount = 0;
                leaderboard[gid].teamAmount = 0;
                // update groupEarnedEntryCount
                groupEarnedEntryCount[gid] = 0;
            } else {
                QuestLike.Action[WINNER_COUNT] memory oldWinnerActions;
                if(groupEarnedEntryCount[gid] > 0) { // backup leaderboard winners for reference in raffling
                    for (uint256 k = 0; k < WINNER_COUNT; k++) {
                        if(leaderboard[gid].winners[k].owners.length > 0) {
                            oldWinnerActions[k] = _copyActionFrom(leaderboard[gid].winners[k]);
                            delete leaderboard[gid].winners[k];
                            delete leaderboard[gid].scores[k];
                        }
                    }
                }
                // start raffle to select 5 winners
                for (uint256 rank_ = 0; rank_ < WINNER_COUNT; rank_++) {
                    uint256 selNo_ = vrf.getRandom(rank_+1) % raffleEntries;

                    // get selected activity
                    QuestLike.Action memory action_;
                    if(selNo_ >= activityLengths[gid]) { // get activity from last leaderboard winners
                        uint256 _winnerId;
                        uint256 _posFrom = activityLengths[gid];
                        for (uint256 k = 0; k < WINNER_COUNT; k++) {
                            uint256 _posTo = _posFrom + winnerEntryConfig[k];
                            if(selNo_ < _posTo) {
                                _winnerId = k;
                                break;
                            }
                            _posFrom = _posTo;
                        }
                        action_ = oldWinnerActions[_winnerId];
                    } else {
                        action_ = activities[gid][selNo_];
                    }
                    // delete leaderboard[gid].winners[rank_];
                    // delete leaderboard[gid].scores[rank_];
                    leaderboard[gid].winners[rank_] = _copyActionFrom(action_);
                    leaderboard[gid].scores[rank_] = new uint256[](leaderboard[gid].winners[rank_].owners.length);
                    for (uint256 k = 0; k < leaderboard[gid].winners[rank_].owners.length; k++) {
                        leaderboard[gid].scores[rank_][k] = getOwnerScore(leaderboard[gid].winners[rank_].owners[k]);
                    }
                }

                // update groupEarnedEntryCount if selected winners
                groupEarnedEntryCount[gid] = winnerEntryTotal;

                // update leaderboard
                leaderboard[gid].performId = _currentPerformId;
                leaderboard[gid].timestamp = timestamp;
                uint256 prizeTotal_ = prizePool[gid];
                leaderboard[gid].prizePool = prizeTotal_;
                prizePool[gid] = 0;

                (uint prize_, uint burn_, uint team_) = getDistribution(prizeTotal_);
                leaderboard[gid].prizeAmount = prize_;
                leaderboard[gid].burnAmount = burn_; // burn_: no need to burn because fee already burnt, burn_ is used only for log
                leaderboard[gid].teamAmount = team_;

                teamAmount_ += team_;
                // prize distribution
                if(prize_ > 0) {
                    for (uint256 rank_ = 0; rank_ < WINNER_COUNT; rank_++) {
                        uint256 ownersPrize_ = prize_ * winnerPrizeAllocConfig[rank_] / totalPrizeAllocPoint; // calculate prize of the winner
                        if(leaderboard[gid].winners[rank_].owners.length > 0 && ownersPrize_ > 0) {
                            uint256 ownerPrize_ = ownersPrize_ / leaderboard[gid].winners[rank_].owners.length; // distribute evenly to the owners
                            for (uint256 k = 0; k < leaderboard[gid].winners[rank_].owners.length; k++) {
                                address owner_ = leaderboard[gid].winners[rank_].owners[k];
                                if(owner_ != address(0)) {
                                    treat.mint(owner_, ownerPrize_);
                                }
                            }
                        }
                    }
                }
            }
            // emit leaderboard result
            emit LeaderboardPerform(
                _currentPerformId, _currentActionId, timestamp, gid,
                getLeaderboard(gid), 
                getLeaderboardMapping(gid)
            );
        }

        if(teamAmount_ > 0) treat.mint(teamTreasury, teamAmount_);

        // reset activityLengths
        for (uint8 gid = 0; gid < GROUP_COUNT; gid++) {
            activityLengths[gid] = 0;
        }

        // update last leaderboard timestamp
        lastLeaderboardTimestamp = timestamp;
        emit LeaderboardTimestamp(_currentPerformId, _currentActionId, timestamp);
    }
    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/
    
    function getOwnerScore(address owner_) public view returns(uint256) {
        return (ownerScores[owner_].timestamp < lastLeaderboardTimestamp) ? 0 : ownerScores[owner_].score;
    }

    function getLeaderboard(uint8 groupId_) public view returns(LbInfo memory) {
        return LbInfo(leaderboard[groupId_].performId, leaderboard[groupId_].timestamp, leaderboard[groupId_].prizePool, leaderboard[groupId_].prizeAmount, leaderboard[groupId_].burnAmount, leaderboard[groupId_].teamAmount);
    }

    function getLeaderboardMapping(uint8 groupId_) public view returns(LbMappingInfo memory) {
        QuestLike.Action[WINNER_COUNT] memory winners;
        uint256[][WINNER_COUNT] memory scores;
        for (uint256 i = 0; i < WINNER_COUNT; i++) {
            if(leaderboard[groupId_].winners[i].owners.length > 0) {
                winners[i] = leaderboard[groupId_].winners[i];
                uint256[] memory scores_ = new uint256[](leaderboard[groupId_].scores[i].length);
                for (uint256 k = 0; k < scores_.length; k++) {
                    scores_[k] = leaderboard[groupId_].scores[i][k];
                }
                scores[i] = scores_;
            }
        }
        return LbMappingInfo(winners, scores);
    }

    function getDistribution(uint256 total_) public pure returns(uint256 prize_, uint256 burn_, uint256 team_) {
        prize_ = total_ * 40 / 100;
        burn_ = total_ * 55 / 100;
        team_ = total_ - prize_ - burn_;
    }

    function getActivity(uint8 gid_, uint256 pos_) external view returns(QuestLike.Action memory) {
        return activities[gid_][pos_];
    }

    /*///////////////////////////////////////////////////////////////
                    UTILS
    //////////////////////////////////////////////////////////////*/

    function _copyActionFrom(QuestLike.Action memory action_) internal pure returns (QuestLike.Action memory) {
        uint256[] memory doges_ = new uint256[](action_.doges.length);
        address[] memory owners_ = new address[](action_.owners.length);
        uint256[] memory scores_ = new uint256[](action_.scores.length);
        for (uint256 i = 0; i < action_.doges.length; i++) {
            doges_[i] = action_.doges[i];
        }
        for (uint256 i = 0; i < action_.owners.length; i++) {
            owners_[i] = action_.owners[i];
        }
        for (uint256 i = 0; i < action_.scores.length; i++) {
            scores_[i] = action_.scores[i];
        }

        return QuestLike.Action(action_.id, action_.timestamp, doges_, owners_, scores_);
    }

    /**
     * If daily activitiy count is less than activity array length, then reuse index.
     * Or push new action data to the array.
     * @return position added position index
     */
    // function _addActivity(uint8 _groupIndex, QuestLike.Action memory _action) internal returns (uint256 position) {
    //     if(activities[_groupIndex][activityLengths[_groupIndex]].doges.length > 0) delete activities[_groupIndex][activityLengths[_groupIndex]];
        
    //     activities[_groupIndex][activityLengths[_groupIndex]] = _action;
    //     position = activityLengths[_groupIndex];
    //     activityLengths[_groupIndex]++;
    // }

    function _addActivity(uint8 _groupIndex, QuestLike.Action memory _action) internal returns (uint256 position) {
        if(activities[_groupIndex].length <= activityLengths[_groupIndex]) {
            activities[_groupIndex].push(_action);
            position = activityLengths[_groupIndex];
            activityLengths[_groupIndex]++;
        } else {
            activities[_groupIndex][activityLengths[_groupIndex]] = _action;
            position = activityLengths[_groupIndex];
            activityLengths[_groupIndex]++;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    CHAINLINK KEEPER
    //////////////////////////////////////////////////////////////*/

    function checkUpkeep(bytes calldata /* checkData */) external override virtual returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = block.timestamp >= (((lastLeaderboardTimestamp / 24 hours) + 1) * 24 hours);
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override virtual {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        require(block.timestamp >= (((lastLeaderboardTimestamp / 24 hours) + 1) * 24 hours), "should wait more");
        _performLeaderboard();
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }
}

contract TestQuestPoly is QuestPoly {
    function performLeaderboard() external override {
        _performLeaderboard();
    }

    function checkUpkeep(bytes calldata /* checkData */) external override view returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = block.timestamp >= (lastLeaderboardTimestamp + 1 hours);
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        require(block.timestamp >= (lastLeaderboardTimestamp + 1 hours), "should wait more");
        _performLeaderboard();
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

}