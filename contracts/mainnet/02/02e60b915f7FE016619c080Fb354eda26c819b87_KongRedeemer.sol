pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "Ownable.sol";
import "IERC20.sol";
import "IERC721.sol";
import "IERC1155.sol";
import "VRFConsumerBase2.sol";
import "SafeMath.sol";

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

contract KongRedeemer is VRFConsumerBaseV2 {
	using SafeMath for uint256;

	struct vrfCall {
		uint256 tokenType;
		address ticketAdd;
		uint256 ticketId;
		uint256 index;
		address user;
		address lootAdd;
	}

	struct Loot20 {
		uint256 ticketReq;
		uint256 min;
		uint256 max;
	}

	struct Loot721 {
		uint256 ticketReq;
		uint256[] loot;
	}

	struct SubGroup {
		uint256[] tokenIds;
		uint256[] itemCount;
		uint256 totalItemCount;
	}

	struct Loot1155 {
		uint256 ticketReq;
		uint256 itemCount;
		uint256 subGroupCount;
		mapping(uint256 => SubGroup) subGroups;
	}

	address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

	mapping(uint256 => vrfCall) public requestData;

	// ticket add => tokenId  => redeemIndex => nftadd => array of loot
	mapping(address => mapping(uint256 => mapping(uint256 => mapping(address => Loot20)))) public loot20Array;

	// ticket add => tokenId  => redeemIndex => nftadd => array of loot
	mapping(address => mapping(uint256 => mapping(uint256 => mapping(address => Loot721)))) public loot721Array;
	// ticket add => tokenId  => redeemIndex => nftadd => array of loot
	mapping(address => mapping(uint256 => mapping(uint256 => mapping(address => Loot1155)))) public lootArray1155;

	event ItemRedeemed(address indexed user, uint256 tokenType, address lootAdd, uint256 tokenId, uint256 amount);

	constructor(address _vrfCoordinator, address _link) public VRFConsumerBaseV2(_vrfCoordinator, _link) {}

	function populateLoot20(address _ticket, uint256 _ticketId, uint256 _ticketReq, uint256 _index, address _lootAdd, uint256 _min, uint256 _max) external onlyOwner {
		loot20Array[_ticket][_ticketId][_index][_lootAdd] = Loot20(_ticketReq, _min, _max);
	}

	function populateArray721(address _ticket, uint256 _ticketId, uint256 _ticketReq, uint256 _index, address _lootAdd, uint256[] calldata _ids) external onlyOwner {
		Loot721 storage loot = loot721Array[_ticket][_ticketId][_index][_lootAdd];
		loot.ticketReq = _ticketReq;
		for (uint256 i = 0; i < _ids.length; i++) {
			loot.loot.push(_ids[i]);
			IERC721(_lootAdd).safeTransferFrom(msg.sender, address(this), _ids[i]);
		}
	}

	function populateArray1155(address _ticket, uint256 _ticketId, uint256 _ticketReq, uint256 _index, address _lootAdd, uint256[][] calldata _groupIds, uint256[][] calldata _groupCounts) external onlyOwner {
		Loot1155 storage loot1155 = lootArray1155[_ticket][_ticketId][_index][_lootAdd];
		require(loot1155.itemCount == 0);
		loot1155.ticketReq = _ticketReq;

		uint256 totalCount;
		for (uint256 i = 0; i < _groupIds.length; i++) {
			uint256 subItemCount;
			SubGroup storage sub = loot1155.subGroups[i];
			for (uint256 j = 0; j < _groupIds[i].length; j++) {
				sub.tokenIds.push(_groupIds[i][j]);
				sub.itemCount.push(_groupCounts[i][j]);
				subItemCount += _groupCounts[i][j];
			}
			sub.totalItemCount = subItemCount;
			totalCount += subItemCount;
		}
		loot1155.subGroupCount = _groupIds.length;
		loot1155.itemCount = totalCount;
	}

	function redeem(uint256 tokenType, address _ticket, uint256 _ticketId, uint256 _index, address _lootAdd) external {
		require(tokenType == 20 || tokenType == 721 || tokenType == 1155);
		uint256 ticketReq;

		if (tokenType == 721) {
			require(loot721Array[_ticket][_ticketId][_index][_lootAdd].loot.length > 0, "721: Array empty");
			ticketReq = loot721Array[_ticket][_ticketId][_index][_lootAdd].ticketReq;
		}
		else if (tokenType == 1155) {
			require(lootArray1155[_ticket][_ticketId][_index][_lootAdd].itemCount > 0, "1155: Array empty" );
			ticketReq = lootArray1155[_ticket][_ticketId][_index][_lootAdd].ticketReq;
		}
		else if (tokenType == 20) {
			require(loot20Array[_ticket][_ticketId][_index][_lootAdd].max <= IERC20(_lootAdd).balanceOf(address(this)), "Not enough tokens");
			ticketReq = loot20Array[_ticket][_ticketId][_index][_lootAdd].ticketReq;
		}
		uint256 requestId = requestRandomWords();
		requestData[requestId] = vrfCall(tokenType, _ticket, _ticketId, _index, msg.sender, _lootAdd);
		IERC1155(_ticket).safeTransferFrom(msg.sender, address(this), _ticketId, ticketReq, "");
		
	}

	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
		vrfCall memory call = requestData[requestId];
		uint256 tokenType = call.tokenType;
		uint256 ticketReq;
		if (tokenType == 20) {
			Loot20 memory loot20 = loot20Array[call.ticketAdd][call.ticketId][call.index][call.lootAdd];
			ticketReq = loot20.ticketReq;
			if (loot20.max > IERC20(call.lootAdd).balanceOf(address(this))) {
				IERC1155(call.ticketAdd).safeTransferFrom(address(this), call.user, call.ticketId, ticketReq, "");
				return;
			}
			_redeem20(randomWords[0], call.lootAdd, call.user, loot20.min, loot20.max);
		}
		else if (tokenType == 721) {
			Loot721 storage loot721 = loot721Array[call.ticketAdd][call.ticketId][call.index][call.lootAdd];
			ticketReq = loot721.ticketReq;
			if (loot721.loot.length == 0) {
				IERC1155(call.ticketAdd).safeTransferFrom(address(this), call.user, call.ticketId, ticketReq, "");
				return;
			}
			_redeem721(loot721, randomWords[0], call.lootAdd, call.user);
		}
		else if (tokenType == 1155) {
			Loot1155 storage loot1155 = lootArray1155[call.ticketAdd][call.ticketId][call.index][call.lootAdd];
			ticketReq = loot1155.ticketReq;
			if (loot1155.itemCount == 0) {
				IERC1155(call.ticketAdd).safeTransferFrom(address(this), call.user, call.ticketId, ticketReq, "");
				return;
			}
			_redeem1155(loot1155, randomWords[0], call.lootAdd, call.user);
		}

		IERC1155(call.ticketAdd).safeTransferFrom(address(this), BURN_ADDRESS, call.ticketId, ticketReq, "");
	}

	function _redeem20(uint256 _seed, address _lootAdd, address _receiver, uint256 _min, uint256 _max) internal {
		_seed = uint256(keccak256(abi.encodePacked(_seed)));
		uint256 amount = _min + _seed % (_max - _min + 1);
		IERC20(_lootAdd).transfer(_receiver, amount);
		emit ItemRedeemed(_receiver, 20, _lootAdd, 0, amount);
	}

	function _redeem721(Loot721 storage _loot, uint256 _seed, address _lootAdd, address _receiver) internal {
		uint256 len = _loot.loot.length;
		_seed = uint256(keccak256(abi.encodePacked(_seed))) % len;
		uint256 tokenId = _loot.loot[_seed];
		_loot.loot[_seed] = _loot.loot[len - 1];
		_loot.loot.pop();
		IERC721(_lootAdd).safeTransferFrom(address(this), _receiver, tokenId);
		emit ItemRedeemed(_receiver, 721, _lootAdd, tokenId, 0);
	}

	function _redeem1155(Loot1155 storage _loot, uint256 _seed, address _lootAdd, address _receiver) internal {
		uint256 rng = uint256(keccak256(abi.encodePacked(_seed))) % _loot.itemCount;
		uint256 subGroupCount = _loot.subGroupCount;
		uint256 rngCeiling;
		uint256 returnId;

		for (uint256 i = 0; i < subGroupCount; i++) {
			rngCeiling += _loot.subGroups[i].totalItemCount;
			if (rng < rngCeiling) {
				SubGroup storage sub = _loot.subGroups[i];
				rng = uint256(keccak256(abi.encodePacked(_seed))) % sub.totalItemCount;
				uint256 itemCount = sub.tokenIds.length;
				rngCeiling = 0;
				for (uint256 j = 0; j < itemCount; j++) {
					rngCeiling += sub.itemCount[j];
					if (rng < rngCeiling) {
						sub.itemCount[j]--;
						sub.totalItemCount--;
						_loot.itemCount--;
						IERC1155(_lootAdd).safeTransferFrom(address(this), _receiver, sub.tokenIds[j], 1, "");
						emit ItemRedeemed(_receiver, 1155, _lootAdd, sub.tokenIds[j], 1);
						return;
					}
				}
			}
		}
	}

	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
		return KongRedeemer.onERC721Received.selector;
	}

	function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
		return KongRedeemer.onERC1155Received.selector;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "IERC165.sol";

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
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

pragma solidity ^0.6.12;

import "IVRFCoordinator2.sol";
import "ILink.sol";
import "Ownable.sol";

abstract contract VRFConsumerBaseV2 is Ownable {

	struct RequestConfig {
		uint64 subId;
		uint32 callbackGasLimit;
		uint16 requestConfirmations;
		uint32 numWords;
		bytes32 keyHash;
	}

	RequestConfig public config;
	VRFCoordinatorV2Interface private COORDINATOR;
	LinkTokenInterface private LINK;


	/**
	* @param _vrfCoordinator address of VRFCoordinator contract
	*/
	// poly coord: 0xAE975071Be8F8eE67addBC1A82488F1C24858067
	// poly link:  0xb0897686c545045afc77cf20ec7a532e3120e0f1
	constructor(address _vrfCoordinator, address _link) public {
		COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
		LINK = LinkTokenInterface(_link);
		
		config = RequestConfig({
			subId: 0,
			callbackGasLimit: 1000000,
			requestConfirmations: 3,
			numWords: 1,
			keyHash: 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93
		});
	}

	function _initVRF(address _vrfCoordinator, address _link) internal {
		COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
		LINK = LinkTokenInterface(_link);
		
		config = RequestConfig({
			subId: 0,
			callbackGasLimit: 1000000,
			requestConfirmations: 3,
			numWords: 1,
			keyHash: 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93
		});
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
		require (msg.sender == address(COORDINATOR), "!coordinator");
		fulfillRandomWords(requestId, randomWords);
	}

	  // Assumes the subscription is funded sufficiently.
	function requestRandomWords() internal returns(uint256 requestId) {
		RequestConfig memory rc = config;
		// Will revert if subscription is not set and funded.
		requestId = COORDINATOR.requestRandomWords(
			rc.keyHash,
			rc.subId,
			rc.requestConfirmations,
			rc.callbackGasLimit,
			rc.numWords
		);
	}

	function topUpSubscription(uint256 amount) external onlyOwner {
		LINK.transferAndCall(address(COORDINATOR), amount, abi.encode(config.subId));
	}

	function withdraw(uint256 amount, address to) external onlyOwner {
		LINK.transfer(to, amount);
	}

	function unsubscribe(address to) external onlyOwner {
		// Returns funds to this address
		COORDINATOR.cancelSubscription(config.subId, to);
		config.subId = 0;
	}

	function subscribe() public onlyOwner {
		// Create a subscription, current subId
		address[] memory consumers = new address[](1);
		consumers[0] = address(this);
		config.subId = COORDINATOR.createSubscription();
		COORDINATOR.addConsumer(config.subId, consumers[0]);
	}
}

pragma solidity ^0.6.12;

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

pragma solidity ^0.6.12;

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

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}