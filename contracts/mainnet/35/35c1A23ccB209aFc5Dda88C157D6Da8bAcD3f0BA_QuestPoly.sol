/**
 *Submitted for verification at polygonscan.com on 2022-03-30
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
    struct Action {
        uint256 id; // unique id to distinguish activities
        uint88 timestamp;
        uint256 doge;
        address owner;
        uint256 score;
        uint256 finalScore;
    }

    function doQuestByAdmin(uint256 doge, address owner, uint256 score, uint8 groupIndex, uint256 combatId) external;
}

interface IOracle {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface IVRF {
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom(string memory seed) external returns (uint256);
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
 * QuestPoly should be added to auth of Dogewood
 * quest admin sender should be added to auth of QuestPoly
 * Note: Dogewood should set this address to quest variable
 * Note: BattlePoly should set this address to quest variable
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

    mapping(uint256 => uint256) public winnerPrizeAllocConfig; // winner's prize alloc point. total: 10000 (rank => allocPoint)
    uint256 totalPrizeAllocPoint;

    uint8 public constant GROUP_COUNT = 4;
    mapping(uint8 => QuestLike.GroupConfig) public groupConfig; // groupId => GroupConfig
    mapping(uint8 => uint256) public prizePool; // (groupIndex => prizeAmount)
    uint256 public lastLeaderboardTimestamp; // last calculated timestamp of winners

    uint256 public _currentPerformId; // increament when perform leaderboard
    uint256 public _currentActionId; // increament when doing quest
    uint256 public _perfLastCombatId;
    uint88 public _perfLastActionTimestamp;

    mapping(uint256 => DogeEntryLog) public dogeEntryLog; // daily entry count log. (dogeId => entryLog)
    mapping(address => mapping(uint256 => ScoreLog)) public scores; // owner => dogeId => scoreLog

    /*///////////////////////////////////////////////////////////////
                    EVENTS
    //////////////////////////////////////////////////////////////*/
    
    // gameType - (0: unity game, 1: web game)
    event NewQuest(uint8 groupIndex,uint8 gameType,uint256 combatId,uint256 performId,QuestLike.Action action);
    event LeaderboardTimestamp(uint256 indexed performId, uint256 indexed actionId, uint88 indexed timestamp);
    event LeaderboardPerform(uint256 indexed performId, uint256 actionId, uint88 indexed timestamp,uint8 indexed groupIndex,LbInfo lbInfo);
    event LeaderboardPerformWinnersInfo(uint256 indexed performId,uint8 indexed groupIndex,uint256 rank,LbWinnerInfo winnerInfo);

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
        uint256 prizePool; uint256 prizeAmount; uint256 burnAmount; uint256 teamAmount;
    }
    struct LbWinnerInfo {
        address owner;
        uint256 doge;
        uint256 score;
        uint256 prize;
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

        // winnerPrizeAllocConfig
        winnerPrizeAllocConfig[0] = 1000; // 10.00%
        winnerPrizeAllocConfig[1] = 800; // 8.00%
        winnerPrizeAllocConfig[2] = 700; // 7.00%
        winnerPrizeAllocConfig[3] = 500; // 5.00%
        winnerPrizeAllocConfig[4] = 500; // 5.00%
        winnerPrizeAllocConfig[5] = 500; // 5.00%
        winnerPrizeAllocConfig[6] = 450; // 4.50%
        winnerPrizeAllocConfig[7] = 400; // 4.00%
        winnerPrizeAllocConfig[8] = 350; // 3.50%
        winnerPrizeAllocConfig[9] = 300; // 3.00%
        winnerPrizeAllocConfig[10] = 200; // 2.00%
        winnerPrizeAllocConfig[11] = 200; // 2.00%
        winnerPrizeAllocConfig[12] = 200; // 2.00%
        winnerPrizeAllocConfig[13] = 200; // 2.00%
        winnerPrizeAllocConfig[14] = 200; // 2.00%
        winnerPrizeAllocConfig[15] = 175; // 1.75%
        winnerPrizeAllocConfig[16] = 175; // 1.75%
        winnerPrizeAllocConfig[17] = 175; // 1.75%
        winnerPrizeAllocConfig[18] = 175; // 1.75%
        winnerPrizeAllocConfig[19] = 175; // 1.75%
        winnerPrizeAllocConfig[20] = 150; // 1.50%
        winnerPrizeAllocConfig[21] = 150; // 1.50%
        winnerPrizeAllocConfig[22] = 150; // 1.50%
        winnerPrizeAllocConfig[23] = 150; // 1.50%
        winnerPrizeAllocConfig[24] = 150; // 1.50%
        winnerPrizeAllocConfig[25] = 125; // 1.25%
        winnerPrizeAllocConfig[26] = 125; // 1.25%
        winnerPrizeAllocConfig[27] = 125; // 1.25%
        winnerPrizeAllocConfig[28] = 125; // 1.25%
        winnerPrizeAllocConfig[29] = 125; // 1.25%
        winnerPrizeAllocConfig[30] = 100; // 1.00%
        winnerPrizeAllocConfig[31] = 100; // 1.00%
        winnerPrizeAllocConfig[32] = 100; // 1.00%
        winnerPrizeAllocConfig[33] = 100; // 1.00%
        winnerPrizeAllocConfig[34] = 100; // 1.00%
        winnerPrizeAllocConfig[35] = 75; // 0.75%
        winnerPrizeAllocConfig[36] = 75; // 0.75%
        winnerPrizeAllocConfig[37] = 75; // 0.75%
        winnerPrizeAllocConfig[38] = 75; // 0.75%
        winnerPrizeAllocConfig[39] = 75; // 0.75%
        winnerPrizeAllocConfig[40] = 50; // 0.50%
        winnerPrizeAllocConfig[41] = 50; // 0.50%
        winnerPrizeAllocConfig[42] = 50; // 0.50%
        winnerPrizeAllocConfig[43] = 50; // 0.50%
        winnerPrizeAllocConfig[44] = 50; // 0.50%
        winnerPrizeAllocConfig[45] = 25; // 0.25%
        winnerPrizeAllocConfig[46] = 25; // 0.25%
        winnerPrizeAllocConfig[47] = 25; // 0.25%
        winnerPrizeAllocConfig[48] = 25; // 0.25%
        winnerPrizeAllocConfig[49] = 25; // 0.25%
        totalPrizeAllocPoint = 10000;

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
     * Should be called by users
     */
    function doQuestByUser(uint256 doge_, uint256 score_, uint8 groupIndex_) external {
        // admin signature validation to prevent forge
        bytes32 hash = keccak256(abi.encodePacked(doge_, score_, groupIndex_, msg.sender));
        // address signer = hash.toEthSignedMessageHash().recover(signature);
        // require(auth[signer] == true, "invalid signer"); // TODO -- it will be active when unity team is ready

        // groupIndex validation
        require(groupIndex_ < GROUP_COUNT, "invalid group index"); // total group count is 4

        // doges level validation
        IDogewood.Doge2 memory s = dogewood.getTokenTraits(doge_);
        require(s.level > 0, "still in reroll cooldown");
        require(groupConfig[groupIndex_].lvlFrom <= s.level && groupConfig[groupIndex_].lvlTo >= s.level, "invalid group index");

        // doge owner validation, and unstake doges first to quest
        require(dogewood.validateOwnerOfDoge(doge_, msg.sender), "invalid owner");
        _doQuest(doge_, msg.sender, score_, groupIndex_, 0, 0);
    }

    /**
     * Add quest log to the contract
     * Should be called by admins
     */
    function doQuestByAdmin(uint256 doge_, address owner_, uint256 score_, uint8 groupIndex_, uint256 combatId_) external {
        require(auth[msg.sender] == true, "no auth");

        // groupIndex validation
        require(groupIndex_ < GROUP_COUNT, "invalid group index"); // total group count is 4

        // doges level validation
        IDogewood.Doge2 memory s = dogewood.getTokenTraits(doge_);
        require(s.level > 0, "still in reroll cooldown");
        require(groupConfig[groupIndex_].lvlFrom <= s.level && groupConfig[groupIndex_].lvlTo >= s.level, "invalid group index");

        // // doge owner validation, and unstake doges first to quest
        // require(dogewood.validateOwnerOfDoge(doge_, owner_), "invalid owner");

        _doQuest(doge_, owner_, score_, groupIndex_, combatId_, 1);
    }

    // gameType - (0: unity game, 1: web game)
    function _doQuest(uint256 doge_, address owner_, uint256 score_, uint8 groupIndex_, uint256 combatId_, uint8 gameType_) internal {
        uint256[] memory doges_ = new uint256[](1); doges_[0] = doge_;
        address[] memory owners_ = new address[](1); owners_[0] = owner_;
        dogewood.unstakeForQuest(owners_, doges_);

        _currentActionId++;
        uint88 timestamp = uint88(block.timestamp);

        // entry check
        if(dogeEntryLog[doge_].timestamp < lastLeaderboardTimestamp) {
            dogeEntryLog[doge_].timestamp = timestamp;
            dogeEntryLog[doge_].entryCount = 0;
        }

        if(dogeEntryLog[doge_].entryCount == 0) dogeEntryLog[doge_].entryCount = 1; // free entry
        else {
            dogeEntryLog[doge_].entryCount++;
            // burn $TREAT from the user
            treat.burn(owner_, groupConfig[groupIndex_].entryFee);
            // add $TREAT to prize pool
            prizePool[groupIndex_] += groupConfig[groupIndex_].entryFee;
        }
        dogeEntryLog[doge_].timestamp = timestamp;

        // update owner scores
        uint256 oldScore_ = getScore(owner_, doge_);
        scores[owner_][doge_].timestamp = timestamp;
        if(score_ > oldScore_) scores[owner_][doge_].score = score_;
        // cooldown update
        dogewood.updateQuestCooldown(doges_, timestamp);
        QuestLike.Action memory action_ = QuestLike.Action(_currentActionId, timestamp, doge_, owner_, score_, scores[owner_][doge_].score);

        emit NewQuest(groupIndex_, gameType_, combatId_, _currentPerformId, action_);
    }

    // Leaderboard winner select - this should be called by cron timer everyday
    function performLeaderboard(
        uint256 performId_, uint256 lastCombatId_, uint88 lastActionTimestamp_,
        address[] calldata owners_, uint256[] calldata doges_, uint256[] calldata countPerGroup_,
        bytes memory signature
    ) external virtual {
        uint88 timestamp = uint88(block.timestamp);
        require(block.timestamp >= (((lastLeaderboardTimestamp / 24 hours) + 1) * 24 hours), "should wait more");
        require(
            _perfLastCombatId <= lastCombatId_
            && (_perfLastActionTimestamp <= lastActionTimestamp_ && lastActionTimestamp_ < timestamp)
            && performId_ == _currentPerformId,
            "invalid last perf"
        );
        bytes32 hash = keccak256(abi.encodePacked(performId_, lastCombatId_, lastActionTimestamp_, msg.sender));
        address signer = hash.toEthSignedMessageHash().recover(signature);
        require(auth[signer] == true, "invalid signer");

        // validation of input data
        require(owners_.length == doges_.length, "invalid input data");
        require(countPerGroup_.length == GROUP_COUNT, "invalid group length");
        uint256 totalCount_ = 0;
        for (uint256 i = 0; i < GROUP_COUNT; i++) {
            require(countPerGroup_[i] <= 50, "invalid winner count");
            totalCount_ += countPerGroup_[i];
        }
        require(owners_.length == totalCount_, "invalid total count");

        _currentPerformId++;
        _perfLastCombatId = lastCombatId_;
        _perfLastActionTimestamp = lastActionTimestamp_;

        _performLeaderboard(owners_, doges_, countPerGroup_);

        // update last leaderboard timestamp
        lastLeaderboardTimestamp = timestamp;
        emit LeaderboardTimestamp(_currentPerformId, _currentActionId, timestamp);
    }

    function _performLeaderboard(address[] calldata owners_, uint256[] calldata doges_, uint256[] calldata countPerGroup_) internal {
        // uint88 timestamp = uint88(block.timestamp);

        uint8 gid = 0;
        uint256 from_ = 0; uint256 to_ = 0;
        while(gid < GROUP_COUNT) {
            if(countPerGroup_[gid] == 0) {
                gid++; continue;
            }
            from_ = to_;
            to_ += countPerGroup_[gid];

            _perfGroup(gid, from_, to_, owners_, doges_);

            gid++;
        }
    }

    function _perfGroup(uint8 gid, uint256 from_, uint256 to_, address[] calldata owners_, uint256[] calldata doges_) internal {
        uint88 timestamp = uint88(block.timestamp);
        uint256 prizeTotal_ = prizePool[gid];
        (uint prize_, uint burn_, uint team_) = getDistribution(prizeTotal_);
        treat.mint(teamTreasury, team_);

        for (uint256 i = from_; i < to_; i++) {
            _perfWinner(gid, owners_[i], doges_[i], i-from_, prize_);
        }
        emit LeaderboardPerform(
            _currentPerformId, _currentActionId, timestamp, gid,
            LbInfo(prizeTotal_, prize_, burn_, team_)
        );
        prizePool[gid] = groupConfig[gid].initPrize;
    }

    function _perfWinner(uint8 gid, address owner_, uint256 doge_, uint256 rank_, uint256 prize_) internal {
        uint256 amount_ = prize_ * winnerPrizeAllocConfig[rank_] / totalPrizeAllocPoint;
        if(amount_ > 0) {
            treat.mint(owner_, amount_);
        }
        emit LeaderboardPerformWinnersInfo(
            _currentPerformId, gid, rank_,
            LbWinnerInfo(owner_, doge_, getScore(owner_, doge_), amount_)
        );
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    function checkUpkeepView() external virtual view returns (bool upkeepNeeded) {
        upkeepNeeded = block.timestamp >= (((lastLeaderboardTimestamp / 24 hours) + 1) * 24 hours);
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }
    
    /**
     * Get group index of the level
     */
    function getGroupIndex(uint16 level_) external view returns (uint8) {
        for (uint8 i = 0; i < GROUP_COUNT; i++) {
            if(level_ <= groupConfig[i].lvlTo) return i;
        }
        return GROUP_COUNT;
    }
    
    /**
     * Get $TREAT fee amount to enter quest
     */
    function getDogeEntryFee(uint256 dogeId) external view returns (uint256) {
        if(dogeEntryLog[dogeId].timestamp < lastLeaderboardTimestamp) return 0;
        if(dogeEntryLog[dogeId].entryCount == 0) return 0;

        IDogewood.Doge2 memory s = dogewood.getTokenTraits(dogeId);
        for (uint8 i = 0; i < GROUP_COUNT; i++) {
            if(s.level <= groupConfig[i].lvlTo) return groupConfig[i].entryFee;
        }
        return 0;
    }

    function getScore(address owner_, uint256 doge_) public view returns(uint256) {
        return (scores[owner_][doge_].timestamp < lastLeaderboardTimestamp) ? 0 : scores[owner_][doge_].score;
    }

    function getDistribution(uint256 total_) public pure returns(uint256 prize_, uint256 burn_, uint256 team_) {
        prize_ = total_ * 40 / 100;
        burn_ = total_ * 55 / 100;
        team_ = total_ - prize_ - burn_;
    }

    /*///////////////////////////////////////////////////////////////
                    UTILS
    //////////////////////////////////////////////////////////////*/


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
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }
}