// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPLMData} from "../interfaces/IPLMData.sol";
import {IPLMToken} from "../interfaces/IPLMToken.sol";

library PLMSeeder {
    struct Seed {
        uint256 imgId;
        uint8 characterType;
        uint8 attribute;
    }

    function _randomFromTokenId(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - 1), tokenId)
                )
            );
    }

    /// @notice Only the cumulativeOdds stores cumulative probabilities.
    /// This function calc Id from the array with pseudoRandomness
    function _matchRandomnessWithOdds(
        uint256 pseudoRandomness,
        uint8[] memory cumulativeOdds
    ) internal pure returns (uint8) {
        uint8 sumOdds = cumulativeOdds[cumulativeOdds.length - 1];
        uint256 p = pseudoRandomness % sumOdds;
        if (p < cumulativeOdds[0]) return 0;
        for (uint8 i = 1; i < cumulativeOdds.length; i++) {
            if (cumulativeOdds[i - 1] <= p && p < cumulativeOdds[i]) {
                return i;
            }
        }
        return 0;
    }

    //////////////////////////
    ///  SEEDER FUNCTIONS  ///
    //////////////////////////

    /// @notice generate seeds for character mint
    /// @dev generate seeds of traits from current-block's hash for to mint character
    /// @param tokenId tokenId to be minted
    /// @return Seed the struct of trait seed that is indexId of trait array
    function generateTokenSeed(uint256 tokenId, IPLMToken token)
        external
        view
        returns (Seed memory)
    {
        // fetch database interface
        IPLMData data = IPLMData(token.getDataAddr());

        // TODO: 画像は属性や特性と比較して総数が多いため、現行の実装を踏襲するとものによって排出確率を変更する実装が汚くなってしまうから、一旦一様分布で対応する。
        uint256 pseudoRandomnessImg = _randomFromTokenId(tokenId);
        uint256 numImg = token.getNumImg();

        uint256 pseudoRandomnessType = _randomFromTokenId(tokenId + 1);

        // TODO: この関数は Seeder の中に追いやりたい。
        uint8[] memory cumulativeCharacterTypeOdds = data
            .getCumulativeCharacterTypeOdds();

        uint256 pseudoRandomnessAttribute = _randomFromTokenId(tokenId + 2);
        uint8[] memory cumulativeAttributeOdds = data
            .getCumulativeAttributeOdds();

        return
            Seed({
                imgId: (pseudoRandomnessImg % numImg) + 1,
                characterType: _matchRandomnessWithOdds(
                    pseudoRandomnessType,
                    cumulativeCharacterTypeOdds
                ),
                attribute: _matchRandomnessWithOdds(
                    pseudoRandomnessAttribute,
                    cumulativeAttributeOdds
                )
            });
    }

    /// @notice generate nonce to be used as input of hash for randomSlotTokenId
    /// @dev generate nonce to be used as input of hash for randomSlotTokenId
    function randomFromBlockHash() external view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1)));
    }

    ////////////////////////
    ///      GETTERS     ///
    ////////////////////////

    /// @notice create tokenId for randomslot without being searched
    /// @dev create tokenId for randomslot without being searched
    /// @param nonce : this prevent players from searching in input space
    /// @return tokenId : tokenId of randomslot
    function getRandomSlotTokenId(
        bytes32 nonce,
        bytes32 playerSeed,
        uint256 totalSupply
    ) external pure returns (uint256) {
        uint256 tokenId = (uint256(
            keccak256(abi.encodePacked(nonce, playerSeed))
        ) % totalSupply) + 1;
        return tokenId;
    }
}

import {IPLMToken} from "./IPLMToken.sol";
import {IPLMTypes} from "./IPLMTypes.sol";
import {IPLMLevels} from "./IPLMLevels.sol";

interface IPLMData {
    ////////////////////////
    ///    STRUCTURES    ///
    ////////////////////////

    /// @notice Minimal character information used in data
    struct CharacterInfoMinimal {
        uint8 level;
        uint8 characterTypeId;
        uint8[1] attributeIds;
        uint256 fromBlock;
    }

    ////////////////////////
    ///      EVENTS      ///
    ////////////////////////

    event TypesDatabaseUpdated(address oldDatabase, address newDatabase);
    event LevelsDatabaseUpdated(address oldDatabase, address newDatabase);

    ////////////////////////
    ///      GETTERS     ///
    ////////////////////////

    function getCurrentBondLevel(uint8 level, uint256 fromBlock)
        external
        view
        returns (uint32);

    function getPriorBondLevel(
        uint8 level,
        uint256 fromBlock,
        uint256 toBlock
    ) external view returns (uint32);

    function getDamage(
        uint8 numRounds,
        CharacterInfoMinimal calldata playerChar,
        uint8 playerLevelPoint,
        uint32 playerBondLevel,
        CharacterInfoMinimal calldata enemyChar
    ) external view returns (uint32);

    function getLevelPoint(CharacterInfoMinimal[4] calldata charInfos)
        external
        view
        returns (uint8);

    function getRandomSlotLevel(CharacterInfoMinimal[4] calldata charInfos)
        external
        view
        returns (uint8);

    function getCharacterTypes() external view returns (string[] memory);

    function getNumCharacterTypes() external view returns (uint256);

    function getCumulativeCharacterTypeOdds()
        external
        view
        returns (uint8[] memory);

    function getAttributeRarities() external view returns (uint8[] memory);

    function getNumAttributes() external view returns (uint256);

    function getCumulativeAttributeOdds()
        external
        view
        returns (uint8[] memory);

    function getNecessaryExp(CharacterInfoMinimal memory charInfo)
        external
        view
        returns (uint256);

    function getRarity(uint8[1] memory attributeIds)
        external
        view
        returns (uint8);

    function getTypeName(uint8 typeId) external view returns (string memory);

    ////////////////////////
    ///      SETTERS     ///
    ////////////////////////

    function setNewTypes(IPLMTypes newTypes) external;

    function setNewLevels(IPLMLevels newLevels) external;
}

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "openzeppelin-contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IPLMData} from "./IPLMData.sol";

interface IPLMToken is IERC721, IERC721Enumerable {
    ////////////////////////
    ///      ENUMS       ///
    ////////////////////////

    /// @notice Enum to represent which checkpoint is reffered
    enum WhichCheckpoints {
        CharInfo, // 0
        TotalSupply // 1
    }

    ////////////////////////
    ///      STRUCTS     ///
    ////////////////////////

    /// @notice A checkpoint for marking change of characterInfo from a given block.
    struct CharInfoCheckpoint {
        uint256 fromBlock;
        CharacterInfo charInfo;
    }

    /// @notice A checkpoint for marking change of totalSupply from a given block.
    struct TotalSupplyCheckpoint {
        uint256 fromBlock;
        uint256 totalSupply;
    }

    /// @notice A struct to manage each token's information.
    struct CharacterInfo {
        uint8 level;
        uint8 rarity;
        uint8 characterTypeId;
        uint256 imgId;
        uint256 fromBlock;
        uint8[1] attributeIds;
        bytes32 name;
    }

    ////////////////////////
    ///      EVENTS      ///
    ////////////////////////

    event LevelUped(uint256 indexed tokenId, uint8 newLevel);

    /// @notice when _checkpoint updated
    event CharacterInfoChanged(
        uint256 indexed tokenId,
        CharacterInfo oldCharacterInfo,
        CharacterInfo newCharacterInfo
    );

    ////////////////////////
    ///      ERRORS      ///
    ////////////////////////

    // For debug
    error ErrorWithLog(string reason);

    function mint(bytes32 name) external returns (uint256);

    function updateLevel(uint256 tokenId) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function minimalizeCharInfo(CharacterInfo memory charInfo)
        external
        view
        returns (IPLMData.CharacterInfoMinimal memory);

    ////////////////////////
    ///      GETTERS     ///
    ////////////////////////

    function getAllTokenOwned(address account)
        external
        view
        returns (uint256[] memory);

    function getAllCharacterInfo()
        external
        view
        returns (CharacterInfo[] memory);

    function getElapsedFromBlock(uint256 tokenId)
        external
        view
        returns (uint256);

    function getNecessaryExp(uint256 tokenId) external view returns (uint256);

    function getDealer() external view returns (address);

    function getCurrentCharacterInfo(uint256 tokenId)
        external
        view
        returns (CharacterInfo memory);

    function getPriorCharacterInfo(uint256 tokenId, uint256 blockNumber)
        external
        view
        returns (CharacterInfo memory);

    function getImgURI(uint256 imgId) external view returns (string memory);

    function getPriorTotalSupply(uint256 blockNumber)
        external
        view
        returns (uint256);

    function getNumImg() external view returns (uint256);

    function getDataAddr() external view returns (address);

    ////////////////////////
    ///      SETTER      ///
    ////////////////////////

    function setDealer(address newDealer) external;

    function setNumImg(uint256 newImgNum) external;

    function setBaseImgURI(string calldata newBaseImgURI) external;
}

interface IPLMTypes {
    ////////////////////////
    ///      EVENTS      ///
    ////////////////////////

    event NewTypeAdded(uint8 typeId, string name, uint8 odds);

    ////////////////////////
    ///      GETTERS     ///
    ////////////////////////

    function getTypeCompatibility(uint8 playerTypeId, uint8 enemyTypeId)
        external
        view
        returns (uint8, uint8);

    function getTypeName(uint8 typeId) external view returns (string memory);

    function getNumCharacterTypes() external view returns (uint8);

    function getCharacterTypeOdds() external view returns (uint8[] memory);

    function getCharacterTypes() external view returns (string[] memory);

    ////////////////////////
    ///      SETTERS     ///
    ////////////////////////

    function setNewType(string calldata name, uint8 odds) external;
}

import {IPLMData} from "./IPLMData.sol";

interface IPLMLevels {
    ////////////////////////
    ///      GETTERS     ///
    ////////////////////////

    function getCurrentBondLevel(uint8 level, uint256 fromBlock)
        external
        view
        returns (uint32);

    function getPriorBondLevel(
        uint8 level,
        uint256 fromBlock,
        uint256 toBlock
    ) external view returns (uint32);

    function getLevelPoint(IPLMData.CharacterInfoMinimal[4] calldata charInfos)
        external
        pure
        returns (uint8);

    function getRandomSlotLevel(
        IPLMData.CharacterInfoMinimal[4] calldata charInfos
    ) external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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