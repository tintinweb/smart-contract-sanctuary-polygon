//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/* 
 *     █████  ██████  ██████   ██████  ██ ███    ██ ████████ ███    ███ ███████ ███    ██ ████████ 
 *    ██   ██ ██   ██ ██   ██ ██    ██ ██ ████   ██    ██    ████  ████ ██      ████   ██    ██    
 *    ███████ ██████  ██████  ██    ██ ██ ██ ██  ██    ██    ██ ████ ██ █████   ██ ██  ██    ██    
 *    ██   ██ ██      ██      ██    ██ ██ ██  ██ ██    ██    ██  ██  ██ ██      ██  ██ ██    ██    
 *    ██   ██ ██      ██       ██████  ██ ██   ████    ██    ██      ██ ███████ ██   ████    ██    
 *                                                                                                 
 *                                                                                                 
 *     ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████          
 *    ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██         
 *    ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████          
 *    ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██         
 *     ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██         
 *
 *
 *    GALAXIS - Appointment Trait (logic) controller
 *
 *    This contract is used for changing trait values in a UTAppointmentStorage contract
 *
*/

import "./UTGenericTimedController.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitStorage {
    function setValue(uint16 _tokenId, uint8 _value, bytes32 _eventId) external;
    function getValues(uint16[] memory _tokenIds) external view returns (uint8[] memory);
    function getTokenForEvent(bytes32 _eventId) external view returns (uint16);
}

// Status:
// 1 - Open to redeem
// 2 - Redeemed by the user (date fixed)

contract UTAppointmentController is UTGenericTimedController {
    uint8               public constant TRAIT_TYPE = 4;         // Appointment trait
    string              public constant APP = 'appointment';    // Application in the claim URL
    uint8                      constant TRAIT_OPEN_VALUE = 1;
    uint8                      constant TRAIT_REDEEMED_VALUE = 2;

    event contractControllerEvent(address _address, bool mode);

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime
    ) UTGenericTimedController(_erc721, _registry, _startTime, _endTime) {
    }

    function setValue(uint16[] memory tokenId, uint8 value, bytes32[] memory eventId, address traitStorage) public {
        require(
            !locked,
            "UT Appointment Controller: contract locked"
        );
        require(
            tokenId.length > 0,
            "UT Appointment Controller: at least 1 token"
        );
        require(
            getTimestamp() > startTime,
            "UT Appointment Controller: before start time"
        );
        require(
            getTimestamp() < endTime,
            "UT Appointment Controller: after end time"
        );

        // Read all current states
        uint8[] memory values = ITraitStorage(traitStorage).getValues(tokenId);

        for(uint8 i = 0; i < tokenId.length; i++) {
            uint16 currentTokenId = tokenId[i];
            uint8  currentValue = values[i];
            bytes32 currentEventId = eventId[i];

            // Business logic (simple)
            if(currentValue == TRAIT_OPEN_VALUE && value == TRAIT_REDEEMED_VALUE) {
                // From state 1 - "Open to redeem" to state 2 - "Redeemed by the user (date fixed)" - Only owner of the NFT can change it
                require(
                    erc721.ownerOf(currentTokenId) == msg.sender,
                    "UT Appointment Controller: not owner of token."
                );
                // Is this event still open?
                require(
                    ITraitStorage(traitStorage).getTokenForEvent(currentEventId) == 0,
                    "UT Appointment Controller: this appointment is already taken!"
                );
                ITraitStorage(traitStorage).setValue(currentTokenId, TRAIT_REDEEMED_VALUE, currentEventId);
            } else {
                require(
                    false,
                    "UT Appointment Controller: invalid state"
                );
            }
        }
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitRegistry {
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function isAllowed(bytes32 role, address user) external view returns (bool);
}

abstract contract UTGenericTimedController {
    bytes32             public constant TRAIT_REGISTRY_ADMIN = keccak256("TRAIT_REGISTRY_ADMIN");
    IERC721             public erc721;                      // NFT ToolBox
    ITraitRegistry      public registry;                    // Trait registry
    bool                public locked       = false;
    uint256             public startTime;
    uint256             public endTime;

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime
    ) {
        erc721 = IERC721(_erc721);
        registry = ITraitRegistry(_registry);
        startTime = _startTime;
        endTime = _endTime == 0 ? 9999999999 : _endTime;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    struct contractInfo {
        address erc721;
        address registry;
        bool    locked;
        uint256 startTime;
        uint256 endTime;
        bool    available;
    }

    function tellEverything() external view returns (contractInfo memory) {
        return contractInfo(
            address(erc721),
            address(registry),
            locked,
            startTime,
            endTime,
            (getTimestamp() >= startTime && getTimestamp() <= endTime && !locked )
        );
    }

    /*
    *   Admin Stuff - For controlling the toggleLock() funtion
    */

    function toggleLock() public {
        require(
            registry.isAllowed(TRAIT_REGISTRY_ADMIN, msg.sender),
            "UTController: Not authorised"
        );
        locked = !locked;
    }
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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