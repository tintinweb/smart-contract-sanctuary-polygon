// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "ILockERC721.sol";

contract Guardian {

	struct UserData {
		address guardian;
		uint256[] lockedAssets;
		mapping(uint256 => uint256) assetToIndex;
	}

	ILockERC721 public immutable LOCKABLE;

	mapping(address => address) public guardians;
	mapping(address => UserData) public userData;
	mapping(address => mapping(uint256 => address)) public guardianToUsers;
	mapping(address => mapping(address => uint256)) public guardianToUserIndex;
	mapping(address => uint256) public guardianUserCount;

	event GuardianSet(address indexed guardian, address indexed user);
	event GuardianRenounce(address indexed guardian, address indexed user);

	constructor(address _lockable) public {
		LOCKABLE = ILockERC721(_lockable);
	}

	function setGuardian(address _guardian) external {
		require(guardians[msg.sender] == address(0), "Guardian set");
		require(msg.sender != _guardian, "Guardian must be a different wallet");

		guardians[msg.sender] = _guardian;
		userData[msg.sender].guardian = _guardian;
		_pushGuardianrray(_guardian, msg.sender);
		emit GuardianSet(_guardian, msg.sender);
	}

	function renounce(address _protege) external {
		require(guardians[_protege] == msg.sender, "!guardian");

		guardians[_protege] = address(0);
		userData[_protege].guardian = address(0);
		_popGuardianrray(msg.sender, _protege);
		emit GuardianRenounce(msg.sender, _protege);
	}

	function lockMany(uint256[] calldata _tokenIds) external {
		address owner = LOCKABLE.ownerOf(_tokenIds[0]);
		require(guardians[owner] == msg.sender, "!guardian");

		UserData storage _userData = userData[owner];
		uint256 len = _userData.lockedAssets.length;
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			require(LOCKABLE.ownerOf(_tokenIds[i]) == owner, "!owner");
			LOCKABLE.lockId(_tokenIds[i]);
			_pushTokenInArray(_userData, _tokenIds[i], len + i);
		}
	}

	function unlockMany(uint256[] calldata _tokenIds) external {
		address owner = LOCKABLE.ownerOf(_tokenIds[0]);
		require(guardians[owner] == msg.sender, "!guardian");

		UserData storage _userData = userData[owner];
		uint256 len = _userData.lockedAssets.length;
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			require(LOCKABLE.ownerOf(_tokenIds[i]) == owner, "!owner");
			LOCKABLE.unlockId(_tokenIds[i]);
			_popTokenFromArray(_userData, _tokenIds[i], len--);
		}
	}

	function unlockManyAndTransfer(uint256[] calldata _tokenIds, address _recipient) external {
		address owner = LOCKABLE.ownerOf(_tokenIds[0]);
		require(guardians[owner] == msg.sender, "!guardian");

		UserData storage _userData = userData[owner];
		uint256 len = _userData.lockedAssets.length;
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			require(LOCKABLE.ownerOf(_tokenIds[i]) == owner, "!owner");
			LOCKABLE.unlockId(_tokenIds[i]);
			LOCKABLE.safeTransferFrom(owner, _recipient, _tokenIds[i]);
			_popTokenFromArray(_userData, _tokenIds[i], len--);
		}
	}

	function getLockedAssetsOfUsers(address _user) external view returns(uint256[] memory lockedAssets) {
		uint256 len = userData[_user].lockedAssets.length;
		lockedAssets = new uint256[](len);
		for (uint256 i = 0; i < len; i++) {
			lockedAssets[i] = userData[_user].lockedAssets[i];
		}
	}

	function getProtegesFromGuardian(address _guardian) external view returns(address[] memory proteges) {
		uint256 len = guardianUserCount[_guardian];
		proteges = new address[](len);
		for (uint256 i = 0; i < len; i++) {
			proteges[i] = guardianToUsers[_guardian][i];
		}
	}

	function _pushTokenInArray(UserData storage _userData, uint256 _token, uint256 _index) internal {
		_userData.lockedAssets.push(_token);
		_userData.assetToIndex[_token] = _index;
	}

	function _popTokenFromArray(UserData storage _userData, uint256 _token, uint256 _len) internal {
		uint256 index = _userData.assetToIndex[_token];
		delete _userData.assetToIndex[_token];
		uint256 lastId = _userData.lockedAssets[_len - 1];
		_userData.assetToIndex[lastId] = index;
		_userData.lockedAssets[index] = lastId;
		_userData.lockedAssets.pop();
	}

	function _pushGuardianrray(address _guardian, address _protege) internal {
		uint256 count = guardianUserCount[_guardian];
		guardianToUsers[_guardian][count] = _protege;
		guardianToUserIndex[_guardian][_protege] = count;
		guardianUserCount[_guardian]++;
	}

	function _popGuardianrray(address _guardian, address _protege) internal {
		uint256 index = guardianToUserIndex[_guardian][_protege];
		delete guardianToUserIndex[_guardian][_protege];
		guardianToUsers[_guardian][index] = guardianToUsers[_guardian][guardianUserCount[_guardian] - 1];
		delete guardianToUsers[_guardian][guardianUserCount[_guardian] - 1];
		guardianUserCount[_guardian]--;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "IERC721.sol";

interface ILockERC721 is IERC721 {
	function lockId(uint256 _id) external;
	function unlockId(uint256 _id) external;
	function freeId(uint256 _id, address _contract) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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