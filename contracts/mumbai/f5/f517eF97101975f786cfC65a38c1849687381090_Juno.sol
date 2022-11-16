// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT-LICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICreator {
    function holdMeetingProxy(
        string memory name,
        string memory symbol,
        string memory metaInfoURL,
        uint256 holdTime,
        uint256 personLimit,
        uint8 templateType,
        uint value,
        address sender
    ) external returns (address c);
}

// SPDX-License-Identifier: MIT-LICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INymph is IERC721 {
    // 签到
    function Sign(address ownerAddress) external;

    // 是否签到
    function IsSign(address ownerAddress) external view returns (bool);

    // 开会时间
    function HoldTime() external view returns (uint256);

    // 主办方批量给白名单用户mint
    function _batchMint(address[] calldata whites) external payable;

    // 裂变的mint方法
    function _fissionMint(address originAddress) external payable;

    // 模版类型
    function TemplateType() external view returns (uint8);

    // 该地址下邀请的人
    function InvitedPeople() external view returns (address[] memory);

    // 能否邀请
    function CanInvite() external view returns (bool);

    // 能否签到
    function CanSign(address ownerAddress) external view returns (bool);

    // 返回票价
    function GetValue() external view returns (uint256);

    function clearCache() external;

    function getCache() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT-LICENSED
pragma solidity ^0.8.17;
import "./INymph.sol";
import "./ICreator.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

contract Juno {
    INymph[] public meetings;
    mapping(address => address[]) public meetingHolds;
    address[] public white;
    mapping(address => address[]) peopleJoins;
    address public owner;
    ICreator public creator;

    event NewMeeting(address, address);
    event flushJoin(address, address);

    modifier inWhite(address holder) {
        for (uint i = 0; i < white.length; i++) {
            if (holder == white[i]) {
                _;
                return;
            }
        }
        require(false, "must in white");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor(address nymphCreator) {
        white.push(msg.sender);
        owner = msg.sender;
        creator = ICreator(nymphCreator);
    }

    // 举办会议
    function HoldMeeting(
        string calldata name,
        string calldata symbol,
        string calldata metaInfoURL,
        uint256 holdTime,
        uint256 personLimit,
        uint8 templateType,
        uint value
    ) external inWhite(msg.sender) returns (address c) {
        require(
            templateType >= 1 && templateType <= 4,
            "template type invalid"
        );

        c = creator.holdMeetingProxy(
            name,
            symbol,
            metaInfoURL,
            holdTime,
            personLimit,
            templateType,
            value,
            msg.sender
        );
        meetings.push(INymph(c));
        meetingHolds[msg.sender].push(c);
        emit NewMeeting(msg.sender, c);
        return c;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        for (uint i = 0; i < meetings.length; i++) {
            if (meetings[i].getCache().length != 0) {
                return (true, "");
            }
        }
        return (false, "");
    }

    // @dev this method is called by the Automation Nodes. it increases all elements which balances are lower than the LIMIT
    function performUpkeep(
        bytes calldata /* performData */
    ) external {
        for (uint i = 0; i < meetings.length; i++) {
            address[] memory cacheI = meetings[i].getCache();
            if (meetings[i].getCache().length != 0) {
                for (uint j = 0; j < cacheI.length; j++) {
                    peopleJoins[meetings[i].getCache()[j]].push(
                        address(meetings[i])
                    );
                    // flushJoin()
                }
                meetings[i].clearCache();
            }
        }
    }

    // 某人举办的会议
    function Holds(address host) external view returns (address[] memory) {
        return meetingHolds[host];
    }

    // 某人参加的会议
    // 后面改进
    function Meetings(address host) external view returns (address[] memory) {
        uint counter = 0;
        for (uint i = 0; i < meetings.length; i++) {
            if (meetings[i].balanceOf(host) > 0) {
                counter++;
            }
        }
        uint index = 0;
        address[] memory result = new address[](counter);
        for (uint i = 0; i < meetings.length; i++) {
            if (meetings[i].balanceOf(host) > 0) {
                address m = address(meetings[i]);
                result[index] = m;
                index++;
            }
        }
        return result;
    }

    // 正在举办的会议
    function HoldingMeetings() internal view returns (address[] memory) {
        address[] memory result;
        for (uint i = 0; i < meetings.length; i++) {
            if ((meetings[i].HoldTime() + 24 * 60 * 60) < block.timestamp) {
                address m = address(meetings[i]);
                result[result.length] = m;
            }
        }
        return result;
    }

    // 添加白名单用户
    function _addTestUser(address n) external onlyOwner {
        white.push(n);
    }

    function meetingSomeoneJoined(address n)
        external
        view
        returns (address[] memory)
    {
        return peopleJoins[n];
    }
}