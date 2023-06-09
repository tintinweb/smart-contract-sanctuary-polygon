// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokens.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract AdManager is ERC1155Holder, VRFV2WrapperConsumerBase {
    ITokens private token;

    event CampaignStarted(uint AdId, uint MaxBudget);
    event CampaignStopped(uint AdId, uint RemainingBudget);
    event AdDisplayed(uint VideoId, uint AdId, uint Reward);
    event PublisherRoomAdded(uint RoomId, uint AdId);
    event PublisherRoomRemoved(uint RoomId, uint AdId);

    address constant linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant wrapperAddress =
        0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    uint32 constant callbackGasLimit = 1_000_000;
    uint16 constant numOfWords = 1;
    uint16 constant numComfirmations = 3;

    struct AdStatus {
        uint reqId;
        uint adId;
        uint videoId;
        uint roomId;
        bool randomFilled;
    }
    mapping(uint => AdStatus) public adStatuses;

    constructor(
        address _tokenAddress
    ) VRFV2WrapperConsumerBase(wrapperAddress, linkAddress) {
        token = ITokens(_tokenAddress);
    }

    function getVideo(uint _id) public view returns (ITokens.Video memory) {
        return token.getVideo(_id);
    }

    function getAd(uint _adId) public view returns (ITokens.Ad memory) {
        return token.getAd(_adId);
    }

    function getRoom(uint _roomId) public view returns (ITokens.Room memory) {
        return token.getRoom(_roomId);
    }

    function startCampaign(uint _AdId, uint _maxBudget) public {
        ITokens.Ad memory ad = getAd(_AdId);
        require(ad.Active == false, "Ad is already active");
        token.updateAdParameters(
            _AdId,
            0,
            2,
            true,
            ad.TotalSpent,
            ad.CurrentBudget + _maxBudget,
            ad.CurrentBudget + _maxBudget
        );
        token.transferTokens(ad.Advertiser, address(this), 0, _maxBudget);
        emit CampaignStarted(_AdId, _maxBudget);
    }

    function stopCampaign(uint _AdId) public {
        ITokens.Ad memory ad = getAd(_AdId);
        require(ad.Active == true, "Ad is not active");
        token.updateAdParameters(
            _AdId,
            0,
            2,
            false,
            ad.TotalSpent,
            ad.CurrentBudget,
            ad.CurrentBudget
        );
        token.transferTokens(address(this), ad.Advertiser, 0, ad.CurrentBudget);
        emit CampaignStopped(_AdId, ad.CurrentBudget);
    }

    function serveAd(uint _videoId) external {
        ITokens.Video memory video = getVideo(_videoId);
        require(video.AdsEnabled == true, "Ads are not enabled for this video");
        uint roomId = video.RoomId;
        uint requestId = requestRandomness(
            callbackGasLimit,
            numComfirmations,
            numOfWords
        );
        adStatuses[requestId] = AdStatus(requestId, 0, _videoId, roomId, false);
    }

    function fulfillRandomWords(
        uint256 _reqId,
        uint[] memory _words
    ) internal override {
        require(
            adStatuses[_reqId].randomFilled == false,
            "Random already filled"
        );
        adStatuses[_reqId].randomFilled = true;
        uint randomIndex = token
            .getRoom(adStatuses[_reqId].roomId)
            .AdIds
            .length % _words.length;
        adStatuses[_reqId].adId = token
            .getRoom(adStatuses[_reqId].roomId)
            .AdIds[randomIndex];
        displayAd(adStatuses[_reqId].videoId, adStatuses[_reqId].adId);
    }

    function displayAd(uint _videoId, uint _AdId) public {
        ITokens.Video memory video = getVideo(_videoId);
        uint roomId = video.RoomId;
        ITokens.Ad memory ad = getAd(_AdId);
        ITokens.Room memory room = token.getRoom(roomId);
        require(ad.Active == true, "Ad is not active");
        require(video.AdsEnabled == true, "Ads are not enabled for this video");
        require(
            ad.CurrentBudget >= room.DisplayReward,
            "Ad has reached its budget"
        );
        uint publisherReward = room.DisplayReward *
            (video.OwnerPercentage / 100);
        uint beneficieriesReward = room.DisplayReward *
            (video.HoldersPercentage / 100);
        token.transferTokens(address(this), video.Owner, 0, publisherReward);
        for (uint i = 0; i < video.Benefeciaries.length; i++) {
            token.transferTokens(
                address(this),
                video.Benefeciaries[i],
                0,
                beneficieriesReward
            );
        }
        token.updateAdParameters(
            _AdId,
            0,
            2,
            ad.Active,
            ad.TotalSpent + room.DisplayReward,
            ad.CurrentBudget - room.DisplayReward,
            ad.MaxBudget
        );
        emit AdDisplayed(_videoId, _AdId, room.DisplayReward);
    }

    function addPublishingRoom(uint _AdId, uint _RoomId) public {
        ITokens.Ad memory ad = getAd(_AdId);

        require(ad.Active == true, "Campaign is not active");
        require(
            ad.CurrentBudget >= token.getRoom(_RoomId).DisplayReward,
            "Ad has reached its budget"
        );
        for (uint i = 0; i < ad.PublishingRooms.length; i++) {
            require(
                ad.PublishingRooms[i] != _RoomId,
                "Room is already added to the campaign"
            );
        }
        token.updateAdParameters(
            _AdId,
            _RoomId,
            1,
            ad.Active,
            ad.TotalSpent,
            ad.CurrentBudget,
            ad.MaxBudget
        );
        ITokens.Room memory room = token.getRoom(_RoomId);
        token.updateRoomParameters(
            _RoomId,
            room.Owner,
            room.Price,
            room.DisplayReward,
            0,
            2,
            _AdId,
            1,
            room.Listed
        );
        emit PublisherRoomAdded(_RoomId, _AdId);
    }

    function removePublishingRoom(uint _AdId, uint _RoomId) public {
        ITokens.Ad memory ad = getAd(_AdId);
        require(ad.Active == true, "Campaign is not active");
        for (uint i = 0; i < ad.PublishingRooms.length; i++) {
            require(
                ad.PublishingRooms[i] == _RoomId,
                "Room is not added to the campaign"
            );
        }
        token.updateAdParameters(
            _AdId,
            _RoomId,
            0,
            ad.Active,
            ad.TotalSpent,
            ad.CurrentBudget,
            ad.MaxBudget
        );
        ITokens.Room memory room = token.getRoom(_RoomId);
        token.updateRoomParameters(
            _RoomId,
            room.Owner,
            room.Price,
            room.DisplayReward,
            0,
            2,
            _AdId,
            0,
            room.Listed
        );
        emit PublisherRoomRemoved(_RoomId, _AdId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokens {
    struct SocialToken {
        uint ID;
        string URI;
        uint256 totalSupply;
        uint circulatingSupply;
        uint price;
        bool launched;
        address creator;
        uint maxHoldingAmount;
        uint videoIds;
    }

    struct SocialTokenHolder {
        uint Id;
        uint amount;
        uint price;
        uint currentlyListed;
    }

    struct Video {
        uint Id;
        string URI;
        address Owner;
        address Creator;
        uint Price;
        uint SocialTokenId;
        uint OwnerPercentage;
        uint HoldersPercentage;
        address[] Benefeciaries;
        bool Listed;
        bool Published;
        bool AdsEnabled;
        uint RoomId;
    }

    struct Ad {
        uint Id;
        string URI;
        address Advertiser;
        uint[] PublishingRooms;
        bool Active;
        uint TotalSpent;
        uint CurrentBudget;
        uint MaxBudget;
    }

    struct Room {
        uint Id;
        string URI;
        address Creator;
        address Owner;
        uint Price;
        uint DisplayReward;
        uint[] VideoIds;
        uint[] AdIds;
        bool Listed;
    }

    function getSocialToken(
        uint _id
    ) external view returns (SocialToken memory);

    function getAd(uint _adId) external view returns (Ad memory);

    function getVideo(uint _id) external view returns (Video memory);

    function getRoom(uint _id) external view returns (Room memory);

    function getSocialTokenHolder(
        uint _id,
        address _account
    ) external view returns (SocialTokenHolder memory);

    function getBalance(
        address _account,
        uint _id
    ) external view returns (uint256);

    function transferTokens(
        address _from,
        address _to,
        uint _id,
        uint256 _amount
    ) external;

    function transferBatch(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    function updateAdParameters(
        uint _id,
        uint _roomId,
        uint roomAdded,
        bool _status,
        uint _totalSpent,
        uint _currentBudget,
        uint _maxBudget
    ) external;

    function updateVideoParameters(
        uint _id,
        address _owner,
        uint _price,
        address _beneficiary,
        uint _action,
        bool _listed,
        bool _published,
        bool _AdsEnabled,
        uint _roomId
    ) external;

    function updateVideoRevenueParameters(
        uint _id,
        uint _ownerPercentage,
        uint _holderPercentage
    ) external;

    function updateRoomParameters(
        uint _id,
        address _owner,
        uint _price,
        uint _displayCharge,
        uint _videoId,
        uint _action,
        uint _adId,
        uint _adAction,
        bool _listed
    ) external;

    function updateSocialTokenParameters(
        uint _id,
        uint _circulatingSupply,
        uint price,
        bool _launched,
        uint videoId
    ) external;

    function updateSocialTokenHolderParameters(
        uint _id,
        uint _amount,
        uint _price,
        uint _currentlyListed,
        address _account
    ) external;
}