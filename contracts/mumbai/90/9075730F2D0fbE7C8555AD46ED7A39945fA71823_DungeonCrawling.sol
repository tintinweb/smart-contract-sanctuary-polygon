// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/Interfaces.sol";

contract DungeonCrawling {
    struct Location {
        uint16 id;
        uint120 zugCost;
        uint120 minLevel;
    }

    address public _implementation;
    address public admin;
    address public dungeonMaster;
    address public orcs;
    address public allies;
    ERC20Like public zug;
    uint256 private _dungeonId;

    mapping(uint16 => Location) public locations;
    mapping(uint16 => address) public commanders;

    mapping(uint256 => uint16) public dungeonLocations;
    mapping(address => uint256) public commandersActiveDungeon;
    mapping(address => uint256[5]) public commanderPlayingCharacters;

    function initialize(
        address _orcs,
        address _allies,
        address _zug
    ) public onlyAdmin {
        orcs = _orcs;
        allies = _allies;
        zug = ERC20Like(_zug);
    }

    function stakeAndStartDungeon(
        uint16 locationId,
        uint256[] calldata orcIds,
        uint256[] calldata allyIds
    ) external {
        OrcishLike(orcs).pull(msg.sender, orcIds);
        OrcishLike(allies).pull(msg.sender, allyIds);
        _startDungeon(locationId, orcIds, allyIds);
    }

    function startDungeon(
        uint16 locationId,
        uint256[] calldata orcIds,
        uint256[] calldata allyIds
    ) external {
        _startDungeon(locationId, orcIds, allyIds);
    }

    function endDungeon(uint256 outcome, bytes calldata signature) external {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                outcome,
                msg.sender,
                commandersActiveDungeon[msg.sender]
            )
        );
        require(_verifySignature(messageHash, signature), "invalid signature");
        commandersActiveDungeon[msg.sender] = 0;
        delete commanderPlayingCharacters[msg.sender];
    }

    //{ Location, dungeonId, charIds[], isActive }
    function getDungeon(address commander)
        external
        view
        returns (
            uint256 dungeonId,
            Location memory location,
            uint256[5] memory dungeonCharacters
        )
    {
        dungeonId = commandersActiveDungeon[commander];
        location = locations[dungeonLocations[dungeonId]];
        dungeonCharacters = commanderPlayingCharacters[commander];
    }

    function stakeMany(uint256[] calldata orcIds, uint256[] calldata allyIds)
        external
    {
        OrcishLike(orcs).pull(msg.sender, orcIds);
        OrcishLike(allies).pull(msg.sender, allyIds);
    }

    function unstakeMany(uint256[] calldata orcIds, uint256[] calldata allyIds)
        external
    {
        for (uint256 index = 0; index < orcIds.length; index++) {
            uint16 orcishId = uint16(orcIds[index]);
            _unstakeCharacter(orcs, orcishId);
        }
        for (uint256 index = 0; index < allyIds.length; index++) {
            uint16 orcishId = uint16(allyIds[index]);
            _unstakeCharacter(allies, orcishId);
        }
    }

    function pullCallback(address owner, uint256[] calldata ids) external {
        require(msg.sender == orcs || msg.sender == allies, "not allowed");
        for (uint256 i = 0; i < ids.length; i++) {
            _pull(msg.sender, uint16(ids[i]), owner);
        }
    }

    function registerLocation(
        uint16 id,
        uint120 zugCost,
        uint120 minLevel
    ) external onlyAdmin {
        require(id > 0, "invalid location id");
        locations[id] = Location(id, zugCost, minLevel);
    }

    function setDungeonMaster(address _dungeonMaster) external onlyAdmin {
        dungeonMaster = _dungeonMaster;
    }

    function _getLevel(uint256 id) internal view returns (uint16 level) {
        if (id < 5051) {
            (, , , , level, , ) = EtherOrcsLike(orcs).orcs(id);
        } else {
            (, level, , , , ) = AlliesLike(allies).allies(id);
        }
    }

    function _pull(
        address token,
        uint16 orcishId,
        address owner
    ) internal {
        require(commanders[orcishId] == address(0), "already staked");
        require(msg.sender == token, "not orcs contract");
        require(
            ERC721Like(token).ownerOf(orcishId) == address(this),
            "orc not transferred"
        );

        commanders[orcishId] = owner;
    }

    function _unstakeCharacter(address token, uint16 orcishId) internal {
        address commander = commanders[orcishId];
        require(msg.sender == commander, "not allowed");
        commanders[orcishId] = address(0);

        ERC721Like(token).transfer(commander, orcishId);
    }

    function _startDungeon(
        uint16 locationId,
        uint256[] calldata orcIds,
        uint256[] calldata allyIds
    ) internal {
        Location memory location = locations[locationId];
        require(location.id > 0, "invalid location");
        require(commandersActiveDungeon[msg.sender] == 0, "already playing");

        uint256[5] memory characters = _joinCharacterArrays(orcIds, allyIds);

        for (uint256 index = 0; index < characters.length; index++) {
            uint16 orcishId = uint16(characters[index]);
            if (orcishId == 0) break;
            require(
                msg.sender == commanders[orcishId] &&
                    _getLevel(orcishId) >= locations[locationId].minLevel,
                "not allowed"
            );
        }
        _dungeonId++;
        dungeonLocations[_dungeonId] = locationId;
        zug.burn(msg.sender, location.zugCost);
        commandersActiveDungeon[msg.sender] = _dungeonId;
        commanderPlayingCharacters[msg.sender] = characters;
    }

    function _joinCharacterArrays(
        uint256[] memory arrayOne,
        uint256[] memory arrayTwo
    ) internal pure returns (uint256[5] memory) {
        require(arrayOne.length + arrayTwo.length < 5, "invalid group size");
        uint256[5] memory returnArray;

        uint256 i = 0;
        for (; i < arrayOne.length; i++) {
            returnArray[i] = arrayOne[i];
        }

        for (uint256 index = 0; index < arrayTwo.length; index++) {
            returnArray[i++] = arrayTwo[index];
        }

        return returnArray;
    }

    function _verifySignature(bytes32 messageHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(messageHash),
                signature
            ) == dungeonMaster;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface OrcishLike {
    function pull(address owner, uint256[] calldata ids) external;

    function manuallyAdjustOrc(
        uint256 id,
        uint8 body,
        uint8 helm,
        uint8 mainhand,
        uint8 offhand,
        uint16 level,
        uint16 zugModifier,
        uint32 lvlProgress
    ) external;

    function transfer(address to, uint256 tokenId) external;

    function orcs(uint256 id)
        external
        view
        returns (
            uint8 body,
            uint8 helm,
            uint8 mainhand,
            uint8 offhand,
            uint16 level,
            uint16 zugModifier,
            uint32 lvlProgress
        );

    function allies(uint256 id)
        external
        view
        returns (
            uint8 class,
            uint16 level,
            uint32 lvlProgress,
            uint16 modF,
            uint8 skillCredits,
            bytes22 details
        );

    function adjustAlly(
        uint256 id,
        uint8 class_,
        uint16 level_,
        uint32 lvlProgress_,
        uint16 modF_,
        uint8 skillCredits_,
        bytes22 details_
    ) external;
}

interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface OracleLike {
    function request() external returns (uint64 key);

    function getRandom(uint64 id) external view returns (uint256 rand);
}

interface MetadataHandlerLike {
    function getTokenURI(
        uint16 id,
        uint8 body,
        uint8 helm,
        uint8 mainhand,
        uint8 offhand,
        uint16 level,
        uint16 zugModifier
    ) external view returns (string memory);
}

interface MetadataHandlerAllies {
    function getTokenURI(
        uint256 id_,
        uint256 class_,
        uint256 level_,
        uint256 modF_,
        uint256 skillCredits_,
        bytes22 details_
    ) external view returns (string memory);
}

interface RaidsLike {
    function stakeManyAndStartCampaign(
        uint256[] calldata ids_,
        address owner_,
        uint256 location_,
        bool double_
    ) external;

    function startCampaignWithMany(
        uint256[] calldata ids,
        uint256 location_,
        bool double_
    ) external;

    function commanders(uint256 id) external returns (address);

    function unstake(uint256 id) external;
}

interface RaidsLikePoly {
    function stakeManyAndStartCampaign(
        uint256[] calldata ids_,
        address owner_,
        uint256 location_,
        bool double_,
        uint256[] calldata potions_
    ) external;

    function startCampaignWithMany(
        uint256[] calldata ids,
        uint256 location_,
        bool double_,
        uint256[] calldata potions_
    ) external;

    function commanders(uint256 id) external returns (address);

    function unstake(uint256 id) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface EtherOrcsLike {
    function ownerOf(uint256 id) external view returns (address owner_);

    function activities(uint256 id)
        external
        view
        returns (
            address owner,
            uint88 timestamp,
            uint8 action
        );

    function orcs(uint256 orcId)
        external
        view
        returns (
            uint8 body,
            uint8 helm,
            uint8 mainhand,
            uint8 offhand,
            uint16 level,
            uint16 zugModifier,
            uint32 lvlProgress
        );
}

interface ERC20Like {
    function balanceOf(address from) external view returns (uint256 balance);

    function burn(address from, uint256 amount) external;

    function mint(address from, uint256 amount) external;

    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}

interface ERC721Like {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function transfer(address to, uint256 id) external;

    function ownerOf(uint256 id) external returns (address owner);

    function mint(address to, uint256 tokenid) external;
}

interface HallOfChampionsLike {
    function joined(uint256 orcId) external view returns (uint256 joinDate);
}

interface AlliesLike {
    function allies(uint256 id)
        external
        view
        returns (
            uint8 class,
            uint16 level,
            uint32 lvlProgress,
            uint16 modF,
            uint8 skillCredits,
            bytes22 details
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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