/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

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

// File @openzeppelin/contracts/token/ERC1155/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File contracts/MysteryBox.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @author OutDev Team
 * @title MysteryBoxSale
 */
contract MysteryBoxOA {
    mapping(address => MysteryBox) public mysteryBoxes;
    mapping(address => mapping(uint256 => MysteryType)) private _mysteryTypes;

    struct MysteryType {
        uint256 tokenId;
        uint256[] _tokenTypes;
        uint256[] _tokenQuantity;
    }

    struct MysteryBox {
        uint256 revelTime;
        address erc1155Contract;
        address erc1155reward;
        address owner;
        bool paused;
    }

    event Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data,
        uint256 gas
    );
    event BatchReceived(
        address operator,
        address from,
        uint256[] ids,
        uint256[] values,
        bytes data,
        uint256 gas
    );

    event MysteryBoxCreated(
        address indexed boxId,
        address indexed owner,
        address erc1155Contract,
        address erc1155reward,
        uint256 revelTime
    );

    event MysteryBoxOpened(
        address indexed boxId,
        address indexed customer,
        address contractReward,
        uint256 tokenId
    );

    /**
     * @notice Create a new Mystery Box and transfer all the required nfts
     *  to the mysteryBox.
     * @dev To transfer all the required tokens is needed to set approval
     *  to the mystery box contract address.
     * @param revelTime Epoch time in which box time is going to open.
     * @param erc1155Contract ERC1155's address that is used as token to participate.
     * @param erc1155reward ERC1155's address that is used as reveled tokens.
     */
    function createMysteryBox(
        uint256 revelTime,
        address erc1155Contract,
        address erc1155reward,
        MysteryType[] memory mysteryTypes
    ) external {
        require(
            mysteryBoxes[erc1155Contract].erc1155Contract == address(0),
            "MysteryBox: There is already a box with taht ERC1155 address"
        );
        require(
            mysteryTypes.length > 0,
            "MysteryBox: It must exist at least one type"
        );
        require(
            erc1155Contract != address(0) && erc1155reward != address(0),
            "MysteryBox: Contract addresses must not be 0 address"
        );

        IERC1155 erc1155 = IERC1155(erc1155reward);

        for (uint256 i; i < mysteryTypes.length; ) {
            MysteryType memory mysteryType = mysteryTypes[i];
            require(
                mysteryType._tokenTypes.length ==
                    mysteryType._tokenQuantity.length,
                "MysteryBox: Tokens type and Tokens quantity must be equals."
            );
            _mysteryTypes[erc1155Contract][mysteryType.tokenId] = mysteryType;

            erc1155.safeBatchTransferFrom(
                msg.sender,
                address(this),
                mysteryType._tokenTypes,
                mysteryType._tokenQuantity,
                ""
            );

            unchecked {
                ++i;
            }
        }

        mysteryBoxes[erc1155Contract] = MysteryBox({
            erc1155Contract: erc1155Contract,
            erc1155reward: erc1155reward,
            owner: msg.sender,
            revelTime: revelTime,
            paused: false
        });

        emit MysteryBoxCreated(
            erc1155Contract,
            msg.sender,
            erc1155Contract,
            erc1155reward,
            revelTime
        );
    }

    /**
     * @notice Claim a nft using a nft from a ERC1155 collection.
     * @param boxId Id of MysteryBox instanse to participate.
     * @param tokenId The tokenId of the nft used as ticked to participate.
     */
    function openMysteryBox(address boxId, uint256 tokenId) external {
        MysteryBox memory mysteryBox = mysteryBoxes[boxId];
        IERC1155 erc1155 = IERC1155(mysteryBox.erc1155Contract);
        require(
            block.timestamp > mysteryBox.revelTime,
            "MysteryBox: box has not been reveled yet."
        );
        require(!mysteryBox.paused, "MysteryBox: This box has been paused.");
        require(
            erc1155.balanceOf(msg.sender, tokenId) >= 1,
            "MysteryBox: Insufficient balance to participate."
        );

        erc1155.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");

        MysteryType memory mysteryType = _mysteryTypes[boxId][tokenId];

        uint256 totalTokens;
        uint256[] memory limits = new uint256[](mysteryType._tokenTypes.length);
        uint i;
        while (i < mysteryType._tokenTypes.length) {
            totalTokens += mysteryType._tokenQuantity[i];
            limits[i] = totalTokens;
            unchecked {
                ++i;
            }
        }

        require(totalTokens > 0, "MysteryBox: There are not tokens available.");

        uint256 random = _random();

        random %= totalTokens;

        uint tokenType;

        for (uint j; j < limits.length; ) {
            if (random < limits[j]) {
                tokenType = j;
                --_mysteryTypes[boxId][tokenId]._tokenQuantity[j];
                break;
            }

            unchecked {
                ++j;
            }
        }

        IERC1155 rewards = IERC1155(mysteryBox.erc1155reward);

        rewards.safeTransferFrom(
            address(this),
            msg.sender,
            mysteryType._tokenTypes[tokenType],
            1,
            ""
        );

        emit MysteryBoxOpened(
            boxId,
            msg.sender,
            mysteryBox.erc1155reward,
            tokenType
        );
    }

    /**
     * @notice Allow withdraw all the nft not used.
     * @dev It is required to get nfts by the type due to mapping storage.
     * @param boxId the Id of the MysteryBox.
     * @param typesIds An array of the Ids of the MysteryTypes to withdraw their nfts.
     * @custom:restriction Only owner of the MysteryBox can execute this function.
     */
    function withdraw(address boxId, uint256[] memory typesIds) external {
        MysteryBox memory mysteryBox = mysteryBoxes[boxId];
        require(
            msg.sender == mysteryBox.owner,
            "MysteryBox: You are not the owner"
        );
        IERC1155 erc1155 = IERC1155(mysteryBox.erc1155reward);
        for (uint256 i; i < typesIds.length; ) {
            MysteryType memory mysteryType = _mysteryTypes[boxId][typesIds[i]];
            erc1155.safeBatchTransferFrom(
                address(this),
                msg.sender,
                mysteryType._tokenTypes,
                mysteryType._tokenQuantity,
                ""
            );
            delete _mysteryTypes[boxId][typesIds[i]];
        }
    }

    /**
     * @notice This function allow to pause openMysteryBox function for a specific MysteryBox.
     * @param boxId The Id of the mystery box to pause.
     * @param paused false to resume, true to pause.
     * @custom:restriction Only owner of the mystery box can execute this function.
     */
    function pauseMysteryBox(address boxId, bool paused) external {
        address owner = mysteryBoxes[boxId].owner;
        require(
            msg.sender == owner,
            "MysteryBox: Only the owner of the MysteryBox can execute this function."
        );
        mysteryBoxes[boxId].paused = paused;
    }

    /**
     * @dev Use this funciton to generate a random number from blockhash,
     *  sender
     *  to the mystery box contract address.
     * @return uint256 random number generated.
     */
    function _random() internal view returns (uint256) {
        uint256 blocknumber = block.number;
        uint256 random_gap = uint256(
            keccak256(abi.encodePacked(blockhash(blocknumber - 1), msg.sender))
        ) % 255;
        uint256 random_block = blocknumber - 1 - random_gap;
        bytes32 sha = keccak256(
            abi.encodePacked(
                blockhash(random_block),
                msg.sender,
                block.coinbase,
                block.difficulty
            )
        );
        return uint256(sha);
    }

    /**
     * @notice Get a Mystery type
     * @param boxId Address of the contrac used as ticket for the MysteryBox
     * @param typeId Id of the type
     * @return MysteryType struct that contains token types and tokens quantities.
     */
    function getMysteryType(address boxId, uint256 typeId)
        external
        view
        returns (MysteryType memory)
    {
        return _mysteryTypes[boxId][typeId];
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        emit Received(operator, from, id, value, data, gasleft());
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        emit BatchReceived(operator, from, ids, values, data, gasleft());
        return 0xbc197c81;
    }
}