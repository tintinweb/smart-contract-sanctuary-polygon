// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibSplits, Error, Part} from './LibSplits.sol';
import {SplitsStorage} from './SplitsStorage.sol';
import {Split} from '../interfaces/MeemStandard.sol';
import {RoyaltiesV2} from './RoyaltiesV2.sol';
import {MeemBaseERC721Facet} from '../MeemERC721/MeemBaseERC721Facet.sol';
import {PermissionsError} from '../Permissions/PermissionsFacet.sol';

contract SplitsFacet is RoyaltiesV2 {
	event MeemSplitsSet(uint256 tokenId, Split[] splits);
	event RoyaltiesSet(uint256 tokenId, Part[] royalties);

	function getRaribleV2Royalties(uint256 tokenId)
		public
		view
		override
		returns (Part[] memory)
	{
		return LibSplits._getRaribleV2Royalties(tokenId);
	}

	function handleSaleDistribution(uint256 tokenId, address msgSender)
		public
		payable
	{
		if (msg.value == 0) {
			return;
		}

		uint256 leftover = msg.value;
		SplitsStorage.DataStore storage s = SplitsStorage.dataStore();

		for (uint256 i = 0; i < s.tokenSplits[tokenId].splits.length; i++) {
			uint256 amt = (msg.value *
				s.tokenSplits[tokenId].splits[i].amount) / 10000;

			address payable receiver = payable(
				s.tokenSplits[tokenId].splits[i].toAddress
			);

			receiver.transfer(amt);
			leftover = leftover - amt;
		}

		if (leftover > 0) {
			// Refund difference back to the sender
			payable(msgSender).transfer(leftover);
		}
	}

	function lockSplits(uint256 tokenId) external {
		MeemBaseERC721Facet baseContract = MeemBaseERC721Facet(address(this));
		baseContract.requireTokenAdmin(tokenId, msg.sender);

		SplitsStorage.DataStore storage s = SplitsStorage.dataStore();

		if (s.tokenSplits[tokenId].lockedBy != address(0)) {
			revert(PermissionsError.PropertyLocked);
		}

		s.tokenSplits[tokenId].lockedBy = msg.sender;
	}

	function setSplits(uint256 tokenId, Split[] memory splits) external {
		MeemBaseERC721Facet baseContract = MeemBaseERC721Facet(address(this));
		baseContract.requireTokenAdmin(tokenId, msg.sender);

		LibSplits._setSplits(tokenId, splits);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SplitsStorage} from './SplitsStorage.sol';
import {Split} from '../interfaces/MeemStandard.sol';
import {MeemBaseERC721Facet} from '../MeemERC721/MeemBaseERC721Facet.sol';
import {PermissionsError} from '../Permissions/PermissionsFacet.sol';

struct Part {
	address payable account;
	uint96 value;
}

library Error {
	string public constant InvalidNonOwnerSplitAllocationAmount =
		'INVALID_NON_OWNER_SPLIT_ALLOCATION_AMOUNT';
}

library LibSplits {
	event MeemSplitsSet(uint256 tokenId, Split[] splits);
	event RoyaltiesSet(uint256 tokenId, Part[] royalties);

	function _getRaribleV2Royalties(uint256 tokenId)
		internal
		view
		returns (Part[] memory)
	{
		SplitsStorage.DataStore storage s = SplitsStorage.dataStore();

		uint256 numSplits = s.tokenSplits[tokenId].splits.length;
		Part[] memory parts = new Part[](numSplits);
		for (uint256 i = 0; i < s.tokenSplits[tokenId].splits.length; i++) {
			parts[i] = Part({
				account: payable(s.tokenSplits[tokenId].splits[i].toAddress),
				value: uint96(s.tokenSplits[tokenId].splits[i].amount)
			});
		}

		return parts;
	}

	function _setSplits(uint256 tokenId, Split[] memory splits) internal {
		MeemBaseERC721Facet baseContract = MeemBaseERC721Facet(address(this));
		SplitsStorage.DataStore storage s = SplitsStorage.dataStore();

		if (s.tokenSplits[tokenId].lockedBy != address(0)) {
			revert(PermissionsError.PropertyLocked);
		}

		// s.tokenSplits[tokenId].splits = splits;
		delete s.tokenSplits[tokenId].splits;

		for (uint256 i = 0; i < splits.length; i++) {
			s.tokenSplits[tokenId].splits.push(splits[i]);
		}

		address tokenOwner = tokenId == 0
			? address(0)
			: baseContract.ownerOf(tokenId);

		_validateSplits(
			s.tokenSplits[tokenId].splits,
			tokenOwner,
			s.nonOwnerSplitAllocationAmount
		);

		emit MeemSplitsSet(tokenId, splits);
		emit RoyaltiesSet(tokenId, _getRaribleV2Royalties(tokenId));
	}

	function _validateSplits(
		Split[] storage currentSplits,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount
	) internal view {
		// Ensure addresses are unique
		for (uint256 i = 0; i < currentSplits.length; i++) {
			address split1 = currentSplits[i].toAddress;

			for (uint256 j = 0; j < currentSplits.length; j++) {
				address split2 = currentSplits[j].toAddress;
				if (i != j && split1 == split2) {
					revert('Split addresses must be unique');
				}
			}
		}

		uint256 totalAmount = 0;
		uint256 totalAmountOfNonOwner = 0;
		// Require that split amounts
		for (uint256 i = 0; i < currentSplits.length; i++) {
			totalAmount += currentSplits[i].amount;
			if (currentSplits[i].toAddress != tokenOwner) {
				totalAmountOfNonOwner += currentSplits[i].amount;
			}
		}

		if (
			totalAmount > 10000 ||
			totalAmountOfNonOwner < nonOwnerSplitAllocationAmount
		) {
			revert(Error.InvalidNonOwnerSplitAllocationAmount);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Split} from '../interfaces/MeemStandard.sol';

// struct Split {
// 	address toAddress;
// 	uint256 amount;
// 	address lockedBy;
// }

struct TokenSplit {
	Split[] splits;
	address lockedBy;
}

library SplitsStorage {
	bytes32 internal constant STORAGE_SLOT =
		keccak256('meem.contracts.storage.Splits');

	struct DataStore {
		address splitsLockedBy;
		mapping(uint256 => TokenSplit) tokenSplits;
		uint256 nonOwnerSplitAllocationAmount;
	}

	function dataStore() internal pure returns (DataStore storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum Permission {
	Anyone,
	Addresses,
	Holders
}

enum TokenType {
	Original,
	Copy,
	Remix,
	Wrapped
}

enum URISource {
	Url,
	JSON
}

struct Split {
	address toAddress;
	uint256 amount;
	address lockedBy;
}

struct MeemPermission {
	Permission permission;
	address[] addresses;
	uint256 numTokens;
	uint256 costWei;
	uint256 mintStartTimestamp;
	uint256 mintEndTimestamp;
	bytes32 merkleRoot;
}

struct MintParameters {
	address to;
	string tokenURI;
	TokenType tokenType;
}

struct MintWithProofParameters {
	address to;
	string tokenURI;
	TokenType tokenType;
	bytes32[] proof;
}

struct Reaction {
	string reaction;
	uint256 count;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import {Part} from './LibSplits.sol';

interface RoyaltiesV2 {
	// event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

	function getRaribleV2Royalties(uint256 id)
		external
		view
		returns (Part[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MintParameters, MintWithProofParameters} from '../interfaces/MeemStandard.sol';
import {MeemBaseStorage} from './MeemBaseStorage.sol';
import {ERC721BaseInternal} from '@solidstate/contracts/token/ERC721/base/ERC721Base.sol';
import {SolidStateERC721} from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import {ERC721Metadata} from '@solidstate/contracts/token/ERC721/metadata/ERC721Metadata.sol';
import {IERC721Metadata} from '@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol';
import {ERC721MetadataStorage} from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';
import {ERC721BaseStorage} from '@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol';
import {ERC721Base} from '@solidstate/contracts/token/ERC721/base/ERC721Base.sol';
import {IERC721} from '@solidstate/contracts/token/ERC721/IERC721.sol';
import {EnumerableSet} from '@solidstate/contracts/utils/EnumerableSet.sol';
import {EnumerableMap} from '@solidstate/contracts/utils/EnumerableMap.sol';
import {UintUtils} from '@solidstate/contracts/utils/UintUtils.sol';
import {Base64} from '../utils/Base64.sol';
import {Strings} from '../utils/Strings.sol';
import {TokenType} from '../interfaces/MeemStandard.sol';
import {ERC165} from '@solidstate/contracts/introspection/ERC165.sol';
import {ERC721BaseInternal} from '@solidstate/contracts/token/ERC721/base/ERC721Base.sol';
import {ERC721Facet} from '../ERC721/ERC721Facet.sol';
import {AccessControlFacet, AccessControlError} from '../AccessControl/AccessControlFacet.sol';
import {ERC721Enumerable} from '@solidstate/contracts/token/ERC721/enumerable/ERC721Enumerable.sol';
import {ERC721Metadata} from '@solidstate/contracts/token/ERC721/metadata/ERC721Metadata.sol';
import {ISolidStateERC721} from '@solidstate/contracts/token/ERC721/ISolidStateERC721.sol';

library Error {
	string public constant NotTokenAdmin = 'NOT_TOKEN_ADMIN';
	string public constant NotPayable = 'NOT_PAYABLE';
}

struct Meem {
	address owner;
	TokenType tokenType;
	address mintedBy;
	uint256 mintedAt;
}

struct RequireCanMintParams {
	address minter;
	address to;
	bytes32[] proof;
}

contract MeemBaseERC721Facet is
	ISolidStateERC721,
	ERC721Facet,
	ERC721Enumerable,
	ERC721Metadata,
	ERC165
{
	using EnumerableSet for EnumerableSet.UintSet;
	using EnumerableMap for EnumerableMap.UintToAddressMap;
	using UintUtils for uint256;

	event MeemTransfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);

	/**
	 * @notice Bulk Mint Meems
	 * @param bulkParams Array of minting parameters
	 */
	function bulkMint(MintParameters[] memory bulkParams)
		public
		payable
		virtual
	{
		// Only allow bulk minting if there is no fee involved
		if (msg.value > 0) {
			revert(Error.NotPayable);
		}
		MeemBaseStorage.DataStore storage s = MeemBaseStorage.dataStore();
		MeemBaseERC721Facet facet = MeemBaseERC721Facet(address(this));
		bytes32[] memory p;

		for (uint256 i = 0; i < bulkParams.length; i++) {
			s.tokenCounter++;
			uint256 tokenId = MeemBaseStorage.dataStore().tokenCounter;
			MintParameters memory params = bulkParams[i];
			facet.requireCanMint{value: msg.value}(
				RequireCanMintParams({
					minter: msg.sender,
					to: params.to,
					proof: p
				})
			);

			_safeMint(params.to, tokenId);
			ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage
				.layout();
			l.tokenURIs[tokenId] = params.tokenURI;
			s.tokenTypes[tokenId] = params.tokenType;
			s.minters[tokenId] = msg.sender;
			s.mintedTimestamps[tokenId] = block.timestamp;
		}
	}

	/**
	 * @notice Mint a Meem
	 * @param params The minting parameters
	 */
	function mint(MintParameters memory params) public payable virtual {
		MeemBaseStorage.DataStore storage s = MeemBaseStorage.dataStore();
		s.tokenCounter++;
		uint256 tokenId = MeemBaseStorage.dataStore().tokenCounter;

		MeemBaseERC721Facet facet = MeemBaseERC721Facet(address(this));
		bytes32[] memory p;
		facet.requireCanMint{value: msg.value}(
			RequireCanMintParams({minter: msg.sender, to: params.to, proof: p})
		);

		_safeMint(params.to, tokenId);
		ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
		l.tokenURIs[tokenId] = params.tokenURI;
		s.tokenTypes[tokenId] = params.tokenType;
		s.minters[tokenId] = msg.sender;
		s.mintedTimestamps[tokenId] = block.timestamp;

		facet.handleSaleDistribution{value: msg.value}(0, msg.sender);
	}

	/**
	 * @notice Mint a Meem
	 * @param params The minting parameters
	 */
	function mintWithProof(MintWithProofParameters memory params)
		public
		payable
		virtual
	{
		MeemBaseStorage.DataStore storage s = MeemBaseStorage.dataStore();
		s.tokenCounter++;
		uint256 tokenId = MeemBaseStorage.dataStore().tokenCounter;

		MeemBaseERC721Facet facet = MeemBaseERC721Facet(address(this));
		facet.requireCanMint{value: msg.value}(
			RequireCanMintParams({
				minter: msg.sender,
				to: params.to,
				proof: params.proof
			})
		);

		_safeMint(params.to, tokenId);
		ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
		l.tokenURIs[tokenId] = params.tokenURI;
		s.tokenTypes[tokenId] = params.tokenType;
		s.minters[tokenId] = msg.sender;
		s.mintedTimestamps[tokenId] = block.timestamp;

		facet.handleSaleDistribution{value: msg.value}(0, msg.sender);
	}

	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override(ERC721Metadata, IERC721Metadata)
		returns (string memory)
	{
		ERC721BaseStorage.Layout storage b = ERC721BaseStorage.layout();
		require(
			// ERC721BaseStorage.layout().exists(tokenId),
			b.tokenOwners.contains(tokenId),
			'ERC721Metadata: URI query for nonexistent token'
		);

		ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

		string memory tokenIdURI = l.tokenURIs[tokenId];
		string memory baseURI = l.baseURI;

		if (bytes(baseURI).length == 0) {
			if (bytes(tokenIdURI)[0] == bytes1('{')) {
				return
					string(
						abi.encodePacked(
							'data:application/json;base64,',
							Base64.encode(bytes(tokenIdURI))
						)
					);
			}

			return tokenIdURI;
		} else if (bytes(tokenIdURI).length > 0) {
			return string(abi.encodePacked(baseURI, tokenIdURI));
		} else {
			return string(abi.encodePacked(baseURI, tokenId.toString()));
		}
	}

	/**
	 * @notice When a token is sold, distribute the royalties
	 * @param tokenId The token that is being sold. This function will also be called when a token is minted with tokenId=0.
	 */
	function handleSaleDistribution(uint256 tokenId, address msgSender)
		public
		payable
	{
		if (msg.value == 0) {
			return;
		}

		// By default, send the funds back
		payable(msgSender).transfer(msg.value);
	}

	/**
	 * @notice Require that an address can mint a token
	 * @param params The requirement parameters
	 */
	function requireCanMint(RequireCanMintParams memory params)
		public
		payable
	{}

	/**
	 * @notice Require that an address is a token admin. By default only the token owner is an admin
	 * @param addy The address to check
	 * @param tokenId The token id to check
	 */
	function requireTokenAdmin(uint256 tokenId, address addy) public view {
		if (tokenId == 0) {
			requireAdmin();
		} else if (ownerOf(tokenId) != addy) {
			revert(Error.NotTokenAdmin);
		}
	}

	/**
	 * @notice Check if a token can be transferred
	 * @param tokenId The token id to check
	 */
	function requireCanTransfer(
		address from,
		address to,
		uint256 tokenId
	) public {
		MeemBaseERC721Facet facet = MeemBaseERC721Facet(address(this));
		facet.requireTokenAdmin(tokenId, msg.sender);
	}

	function getMeem(uint256 tokenId) public view returns (Meem memory) {
		MeemBaseStorage.DataStore storage s = MeemBaseStorage.dataStore();

		return
			Meem({
				owner: ownerOf(tokenId),
				tokenType: s.tokenTypes[tokenId],
				mintedBy: s.minters[tokenId],
				mintedAt: s.mintedTimestamps[tokenId]
			});
	}

	/**
	 * Override
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override(ERC721Facet, IERC721) {
		_handleTransferMessageValue(from, to, tokenId, msg.value);

		MeemBaseERC721Facet facet = MeemBaseERC721Facet(address(this));
		facet.requireCanTransfer(from, to, tokenId);

		_transfer(from, to, tokenId);
	}

	/**
	 * Override
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override(ERC721Facet, IERC721) {
		safeTransferFrom(from, to, tokenId, '');
	}

	/**
	 * Override
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public payable override(ERC721Facet, IERC721) {
		_handleTransferMessageValue(from, to, tokenId, msg.value);

		MeemBaseERC721Facet facet = MeemBaseERC721Facet(address(this));
		facet.requireCanTransfer(from, to, tokenId);

		_safeTransfer(from, to, tokenId, data);
	}

	function burn(uint256 tokenId) public {
		MeemBaseERC721Facet facet = MeemBaseERC721Facet(address(this));
		facet.requireTokenAdmin(tokenId, msg.sender);

		_burn(tokenId);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
		super._beforeTokenTransfer(from, to, tokenId);
		MeemBaseERC721Facet(address(this)).requireCanTransfer(
			from,
			to,
			tokenId
		);

		emit MeemTransfer(from, to, tokenId);
	}

	function requireAdmin() internal view {
		AccessControlFacet ac = AccessControlFacet(address(this));
		if (!ac.hasRole(ac.ADMIN_ROLE(), msg.sender)) {
			revert(AccessControlError.MissingRequiredRole);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Array} from '../utils/Array.sol';
import {MeemPermission, Permission} from '../interfaces/MeemStandard.sol';
import {PermissionsStorage} from './PermissionsStorage.sol';
import {AccessControlFacet, AccessControlError} from '../AccessControl/AccessControlFacet.sol';
import {MeemBaseERC721Facet, RequireCanMintParams} from '../MeemERC721/MeemBaseERC721Facet.sol';
import {IERC721} from '@solidstate/contracts/token/ERC721/IERC721.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

library PermissionsError {
	string public constant MaxSupplyExceeded = 'MAX_SUPPLY_EXCEEDED';
	string public constant NoPermission = 'NO_PERMISSION';
	string public constant IncorrectMsgValue = 'INCORRECT_MSG_VALUE';
	string public constant PropertyLocked = 'PROPERTY_LOCKED';
	string public constant TransfersLocked = 'TRANSFERS_LOCKED';
}

contract PermissionsFacet {
	event MeemMintPermissionsSet(MeemPermission[] mintPermissions);
	event MeemMaxSupplySet(uint256 maxSupply);
	event MeemMaxSupplyLocked();
	event MeemIsTransferrableLocked();

	function MINTER_ROLE() public pure returns (bytes32) {
		return keccak256('MINTER_ROLE');
	}

	function requireCanMint(RequireCanMintParams memory params) public payable {
		MeemBaseERC721Facet baseContract = MeemBaseERC721Facet(address(this));
		PermissionsStorage.DataStore storage s = PermissionsStorage.dataStore();
		AccessControlFacet ac = AccessControlFacet(address(this));

		// Check if the max supply will be exceeded
		if (s.maxSupply > 0 && baseContract.totalSupply() + 1 > s.maxSupply) {
			revert(PermissionsError.MaxSupplyExceeded);
		}

		// Bypass checks if user has the MINTER_ROLE
		if (ac.hasRole(MINTER_ROLE(), params.minter)) {
			return;
		}

		bool hasPermission = false;
		bool hasCostBeenSet = false;
		uint256 costWei = 0;

		for (uint256 i = 0; i < s.mintPermissions.length; i++) {
			MeemPermission storage perm = s.mintPermissions[i];
			bool hasIndividualPermission = false;

			if (
				isBetweenTimestamps(
					perm.mintStartTimestamp,
					perm.mintEndTimestamp
				)
			) {
				if (
					// Allowed if permission is anyone
					perm.permission == Permission.Anyone
				) {
					hasPermission = true;
					hasIndividualPermission = true;
				}

				if (perm.permission == Permission.Addresses) {
					bytes32 leaf = keccak256(abi.encodePacked(params.minter));
					if (
						MerkleProof.verify(params.proof, perm.merkleRoot, leaf)
					) {
						hasPermission = true;
						hasIndividualPermission = true;
					}
				}

				if (perm.permission == Permission.Holders) {
					// Check each address
					for (uint256 j = 0; j < perm.addresses.length; j++) {
						uint256 balance = IERC721(perm.addresses[j]).balanceOf(
							params.minter
						);

						if (balance >= perm.numTokens) {
							hasPermission = true;
							hasIndividualPermission = true;
							break;
						}
					}
				}

				if (
					hasIndividualPermission &&
					(!hasCostBeenSet ||
						(hasCostBeenSet && costWei > perm.costWei))
				) {
					costWei = perm.costWei;
					hasCostBeenSet = true;
				}
			}
		}

		if (!hasPermission) {
			revert(PermissionsError.NoPermission);
		}

		if (costWei != msg.value) {
			revert(PermissionsError.IncorrectMsgValue);
		}
	}

	function setMaxSupply(uint256 newMaxSupply) public {
		requireAdmin();

		PermissionsStorage.DataStore storage s = PermissionsStorage.dataStore();

		MeemBaseERC721Facet baseContract = MeemBaseERC721Facet(address(this));

		if (newMaxSupply < baseContract.totalSupply()) {
			revert(PermissionsError.MaxSupplyExceeded);
		}

		s.maxSupply = newMaxSupply;

		emit MeemMaxSupplySet(newMaxSupply);
	}

	function maxSupply() public view returns (uint256) {
		PermissionsStorage.DataStore storage s = PermissionsStorage.dataStore();
		return s.maxSupply;
	}

	function setMintingPermissions(MeemPermission[] memory newPermissions)
		public
	{
		requireAdmin();

		PermissionsStorage.DataStore storage s = PermissionsStorage.dataStore();

		PermissionsFacet(address(this)).validatePermissions(
			s.mintPermissions,
			newPermissions
		);

		delete s.mintPermissions;

		for (uint256 i = 0; i < newPermissions.length; i++) {
			s.mintPermissions.push(newPermissions[i]);
		}

		emit MeemMintPermissionsSet(s.mintPermissions);
	}

	function validatePermissions(
		MeemPermission[] memory basePermissions,
		MeemPermission[] memory overridePermissions
	) public pure {}

	function setIsTransferrable(bool isTransferrable) public {
		requireAdmin();
		if (PermissionsStorage.dataStore().isTransferLocked) {
			revert(PermissionsError.TransfersLocked);
		}
		PermissionsStorage.dataStore().isTransferLocked = !isTransferrable;
	}

	function requireCanTransfer(
		address from,
		address to,
		uint256 tokenId
	) public {
		if (PermissionsStorage.dataStore().isTransferLocked) {
			revert(PermissionsError.TransfersLocked);
		}
	}

	function isBetweenTimestamps(uint256 start, uint256 end)
		internal
		view
		returns (bool)
	{
		return
			(start == 0 || block.timestamp >= start) &&
			(end == 0 || block.timestamp <= end);
	}

	function requireAdmin() internal view {
		AccessControlFacet ac = AccessControlFacet(address(this));
		if (!ac.hasRole(ac.ADMIN_ROLE(), msg.sender)) {
			revert(AccessControlError.MissingRequiredRole);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TokenType, URISource} from '../interfaces/MeemStandard.sol';

library MeemBaseStorage {
	bytes32 internal constant STORAGE_SLOT =
		keccak256('meem.contracts.storage.Minting');

	struct DataStore {
		uint256 tokenCounter;
		string contractURI;
		mapping(uint256 => TokenType) tokenTypes;
		mapping(uint256 => address) minters;
		mapping(uint256 => uint256) mintedTimestamps;
	}

	function dataStore() internal pure returns (DataStore storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { IERC721 } from '../IERC721.sol';
import { IERC721Receiver } from '../IERC721Receiver.sol';
import { IERC721Base } from './IERC721Base.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';
import { ERC721BaseInternal } from './ERC721BaseInternal.sol';

/**
 * @title Base ERC721 implementation, excluding optional extensions
 */
abstract contract ERC721Base is IERC721Base, ERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'ERC721: transfer caller is not owner or approved'
        );
        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'ERC721: transfer caller is not owner or approved'
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId) public payable {
        _handleApproveMessageValue(operator, tokenId, msg.value);
        address owner = ownerOf(tokenId);
        require(operator != owner, 'ERC721: approval to current owner');
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            'ERC721: approve caller is not owner nor approved for all'
        );
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool status) public {
        require(operator != msg.sender, 'ERC721: approve to caller');
        ERC721BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC165 } from '../../introspection/ERC165.sol';
import { ERC721Base, ERC721BaseInternal } from './base/ERC721Base.sol';
import { ERC721Enumerable } from './enumerable/ERC721Enumerable.sol';
import { ERC721Metadata } from './metadata/ERC721Metadata.sol';
import { ISolidStateERC721 } from './ISolidStateERC721.sol';

/**
 * @title SolidState ERC721 implementation, including recommended extensions
 */
abstract contract SolidStateERC721 is
    ISolidStateERC721,
    ERC721Base,
    ERC721Enumerable,
    ERC721Metadata,
    ERC165
{
    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        require(value == 0, 'ERC721: payable approve calls not supported');
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        require(value == 0, 'ERC721: payable transfer calls not supported');
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { ERC721BaseInternal, ERC721BaseStorage } from '../base/ERC721Base.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';
import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';
import { IERC721Metadata } from './IERC721Metadata.sol';

/**
 * @title ERC721 metadata extensions
 */
abstract contract ERC721Metadata is IERC721Metadata, ERC721MetadataInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function name() public view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function symbol() public view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().symbol;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    /**
     * @inheritdoc ERC721MetadataInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Internal } from '../IERC721Internal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721Internal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(Layout storage l, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return l.tokenOwners.contains(tokenId);
    }

    function totalSupply(Layout storage l) internal view returns (uint256) {
        return l.tokenOwners.length();
    }

    function tokenOfOwnerByIndex(
        Layout storage l,
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return l.holderTokens[owner].at(index);
    }

    function tokenByIndex(Layout storage l, uint256 index)
        internal
        view
        returns (uint256)
    {
        (uint256 tokenId, ) = l.tokenOwners.at(index);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
	bytes internal constant TABLE =
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	/// @notice Encodes some bytes to the base64 representation
	function encode(bytes memory data) internal pure returns (string memory) {
		uint256 len = data.length;
		if (len == 0) return '';

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((len + 2) / 3);

		// Add some extra buffer at the end
		bytes memory result = new bytes(encodedLen + 32);

		bytes memory table = TABLE;

		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)

			for {
				let i := 0
			} lt(i, len) {

			} {
				i := add(i, 3)
				let input := and(mload(add(data, i)), 0xffffff)

				let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
				)
				out := shl(224, out)

				mstore(resultPtr, out)

				resultPtr := add(resultPtr, 4)
			}

			switch mod(len, 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}

			mstore(result, encodedLen)
		}

		return string(result);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
	/**
	 * @dev Converts a `uint256` to its ASCII `string` representation.
	 */
	function strWithUint(string memory _str, uint256 value)
		internal
		pure
		returns (string memory)
	{
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
		bytes memory buffer;
		unchecked {
			if (value == 0) {
				return string(abi.encodePacked(_str, '0'));
			}
			uint256 temp = value;
			uint256 digits;
			while (temp != 0) {
				digits++;
				temp /= 10;
			}
			buffer = new bytes(digits);
			uint256 index = digits - 1;
			temp = value;
			while (temp != 0) {
				buffer[index--] = bytes1(uint8(48 + (temp % 10)));
				temp /= 10;
			}
		}
		return string(abi.encodePacked(_str, buffer));
	}

	function substring(
		string memory str,
		uint256 startIndex,
		uint256 numChars
	) internal pure returns (string memory) {
		bytes memory strBytes = bytes(str);
		bytes memory result = new bytes(numChars - startIndex);
		for (uint256 i = startIndex; i < numChars; i++) {
			result[i - startIndex] = strBytes[i];
		}
		return string(result);
	}

	function compareStrings(string memory a, string memory b)
		internal
		pure
		returns (bool)
	{
		return (keccak256(abi.encodePacked((a))) ==
			keccak256(abi.encodePacked((b))));
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
	 */
	function toHexString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return '0x00';
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
	function toHexString(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes16 _HEX_SYMBOLS = '0123456789abcdef';
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = '0';
		buffer[1] = 'x';
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _HEX_SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, 'Strings: hex length insufficient');
		return string(buffer);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from './IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AddressUtils} from '@solidstate/contracts/utils/AddressUtils.sol';
import {EnumerableMap} from '@solidstate/contracts/utils/EnumerableMap.sol';
import {EnumerableSet} from '@solidstate/contracts/utils/EnumerableSet.sol';
import {IERC721} from '@solidstate/contracts/token/ERC721/IERC721.sol';
import {IERC721Receiver} from '@solidstate/contracts/token/ERC721/IERC721Receiver.sol';
import {IERC721Base} from '@solidstate/contracts/token/ERC721/base/IERC721Base.sol';
import {ERC721BaseStorage} from '@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol';
import {ERC721BaseInternal} from '@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol';

/**
 * @title Base ERC721 implementation, excluding optional extensions
 */
abstract contract ERC721Facet is IERC721Base, ERC721BaseInternal {
	using AddressUtils for address;
	using EnumerableMap for EnumerableMap.UintToAddressMap;
	using EnumerableSet for EnumerableSet.UintSet;

	/**
	 * @inheritdoc IERC721
	 */
	function balanceOf(address account) public view virtual returns (uint256) {
		return _balanceOf(account);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function ownerOf(uint256 tokenId) public view virtual returns (address) {
		return _ownerOf(tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function getApproved(uint256 tokenId)
		public
		view
		virtual
		returns (address)
	{
		return _getApproved(tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function isApprovedForAll(address account, address operator)
		public
		view
		virtual
		returns (bool)
	{
		return _isApprovedForAll(account, operator);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable virtual {
		_handleTransferMessageValue(from, to, tokenId, msg.value);
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			'ERC721: transfer caller is not owner or approved'
		);
		_transfer(from, to, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable virtual {
		safeTransferFrom(from, to, tokenId, '');
	}

	/**
	 * @inheritdoc IERC721
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public payable virtual {
		_handleTransferMessageValue(from, to, tokenId, msg.value);
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			'ERC721: transfer caller is not owner or approved'
		);
		_safeTransfer(from, to, tokenId, data);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function approve(address operator, uint256 tokenId) public payable virtual {
		_handleApproveMessageValue(operator, tokenId, msg.value);
		address owner = ownerOf(tokenId);
		require(operator != owner, 'ERC721: approval to current owner');
		require(
			msg.sender == owner || isApprovedForAll(owner, msg.sender),
			'ERC721: approve caller is not owner nor approved for all'
		);
		_approve(operator, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function setApprovalForAll(address operator, bool status) public virtual {
		require(operator != msg.sender, 'ERC721: approve to caller');
		ERC721BaseStorage.layout().operatorApprovals[msg.sender][
			operator
		] = status;
		emit ApprovalForAll(msg.sender, operator, status);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControlStorage} from './AccessControlStorage.sol';
import {LibAccessControl} from './LibAccessControl.sol';
import {Array} from '../utils/Array.sol';

struct SetRoleItem {
	address user;
	bytes32 role;
	bool hasRole;
}

library AccessControlError {
	string public constant MissingRequiredRole = 'MISSING_REQUIRED_ROLE';
	string public constant NoRenounceOthers = 'NO_RENOUNCE_OTHERS';
}

/// @title Role-based access control for limiting access to some functions of the contract
/// @notice Assign roles to grant access to otherwise limited functions of the contract
contract AccessControlFacet {
	event MeemRoleGranted(bytes32 indexed role, address indexed user);
	event MeemRoleRevoked(bytes32 indexed role, address indexed user);

	/**
	 * @dev Emitted when `account` is granted `role`.
	 *
	 * `sender` is the account that originated the contract call, an admin role
	 * bearer except when using {AccessControl-_setupRole}.
	 */
	event RoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	/**
	 * @dev Emitted when `account` is revoked `role`.
	 *
	 * `sender` is the account that originated the contract call:
	 *   - if using `revokeRole`, it is the admin role bearer
	 *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
	 */
	event RoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	event RoleSet(
		bytes32 indexed role,
		address[] indexed account,
		address indexed sender
	);

	/// @notice An admin of the contract.
	/// @return Hashed value that represents this role.
	function ADMIN_ROLE() public pure returns (bytes32) {
		return AccessControlStorage.ADMIN_ROLE;
	}

	/// @notice A contract upgrader
	/// @return Hashed value that represents this role.
	function UPGRADER_ROLE() public pure returns (bytes32) {
		return AccessControlStorage.UPGRADER_ROLE;
	}

	function canUpgradeContract(address upgrader) public view returns (bool) {
		AccessControlFacet ac = AccessControlFacet(address(this));
		if (ac.hasRole(ac.UPGRADER_ROLE(), upgrader)) {
			return true;
		}

		return false;
	}

	function bulkSetRoles(SetRoleItem[] memory items) public {
		AccessControlFacet ac = AccessControlFacet(address(this));
		ac.requireRole(AccessControlStorage.ADMIN_ROLE, msg.sender);

		for (uint256 i = 0; i < items.length; i++) {
			SetRoleItem memory item = items[i];
			if (item.hasRole) {
				LibAccessControl._grantRole(item.role, item.user);
			} else {
				LibAccessControl._revokeRole(item.role, item.user);
			}
		}
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to grant the role to
	/// @param role The role to grant
	function grantRole(bytes32 role, address user) public {
		AccessControlFacet ac = AccessControlFacet(address(this));
		ac.requireRole(AccessControlStorage.ADMIN_ROLE, msg.sender);
		LibAccessControl._grantRole(role, user);
		emit MeemRoleGranted(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function revokeRole(bytes32 role, address user) public {
		AccessControlFacet ac = AccessControlFacet(address(this));
		ac.requireRole(AccessControlStorage.ADMIN_ROLE, msg.sender);
		LibAccessControl._revokeRole(role, user);
		emit MeemRoleRevoked(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function hasRole(bytes32 role, address user) public view returns (bool) {
		return AccessControlStorage.dataStore().roles[role].members[user];
	}

	function getRoles(bytes32 role) public view returns (address[] memory) {
		return AccessControlStorage.dataStore().rolesList[role];
	}

	function requireRole(bytes32 role, address user) public view {
		AccessControlFacet ac = AccessControlFacet(address(this));
		if (!ac.hasRole(role, user)) {
			revert(AccessControlError.MissingRequiredRole);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { IERC721Enumerable } from './IERC721Enumerable.sol';
import { ERC721EnumerableInternal } from './ERC721EnumerableInternal.sol';

abstract contract ERC721Enumerable is
    IERC721Enumerable,
    ERC721EnumerableInternal
{
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        return _tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        return _tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Base } from './base/IERC721Base.sol';
import { IERC721Enumerable } from './enumerable/IERC721Enumerable.sol';
import { IERC721Metadata } from './metadata/IERC721Metadata.sol';

interface ISolidStateERC721 is
    IERC721Base,
    IERC721Enumerable,
    IERC721Metadata
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721 } from '../IERC721.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { IERC721Internal } from '../IERC721Internal.sol';
import { IERC721Receiver } from '../IERC721Receiver.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721Internal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(address account) internal view returns (uint256) {
        require(
            account != address(0),
            'ERC721: balance query for the zero address'
        );
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        require(owner != address(0), 'ERC721: invalid owner');
        return owner;
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(
            l.exists(tokenId),
            'ERC721: approved query for nonexistent token'
        );

        return l.tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address account, address operator)
        internal
        view
        returns (bool)
    {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721: query for nonexistent token'
        );

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), 'ERC721: mint to the zero address');

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(!l.exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            _ownerOf(tokenId) == from,
            'ERC721: transfer of token that is not own'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(address operator, uint256 tokenId) internal {
        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(_ownerOf(tokenId), operator, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(uint256 index)
        external
        view
        returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';

abstract contract ERC721EnumerableInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    /**
     * @notice TODO
     */
    function _totalSupply() internal view returns (uint256) {
        return ERC721BaseStorage.layout().totalSupply();
    }

    /**
     * @notice TODO
     */
    function _tokenOfOwnerByIndex(address owner, uint256 index)
        internal
        view
        returns (uint256)
    {
        return ERC721BaseStorage.layout().tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @notice TODO
     */
    function _tokenByIndex(uint256 index) internal view returns (uint256) {
        return ERC721BaseStorage.layout().tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721BaseInternal } from '../base/ERC721Base.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';

/**
 * @title ERC721Metadata internal functions
 */
abstract contract ERC721MetadataInternal is ERC721BaseInternal {
    /**
     * @notice ERC721 hook: clear per-token URI data on burn
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            delete ERC721MetadataStorage.layout().tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library AccessControlStorage {
	bytes32 internal constant STORAGE_SLOT =
		keccak256('meem.contracts.storage.AccessControl');

	bytes32 constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
	bytes32 constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

	struct RoleData {
		mapping(address => bool) members;
	}

	struct DataStore {
		// /** Keeps track of assigned roles */
		mapping(bytes32 => RoleData) roles;
		mapping(bytes32 => address[]) rolesList;
		mapping(bytes32 => mapping(address => uint256)) rolesListIndex;
	}

	function dataStore() internal pure returns (DataStore storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Array} from '../utils/Array.sol';
import {AccessControlStorage} from './AccessControlStorage.sol';
import {AccessControlFacet} from './AccessControlFacet.sol';

library LibAccessControl {
	function _grantRole(bytes32 role, address account) internal {
		AccessControlFacet ac = AccessControlFacet(address(this));
		AccessControlStorage.DataStore storage s = AccessControlStorage
			.dataStore();
		if (!ac.hasRole(role, account)) {
			s.roles[role].members[account] = true;
			s.rolesList[role].push(account);
			s.rolesListIndex[role][account] = s.rolesList[role].length - 1;
		}
	}

	function _revokeRole(bytes32 role, address account) internal {
		AccessControlFacet ac = AccessControlFacet(address(this));
		AccessControlStorage.DataStore storage s = AccessControlStorage
			.dataStore();
		if (ac.hasRole(role, account)) {
			s.roles[role].members[account] = false;
			uint256 idx = s.rolesListIndex[role][account];
			Array.removeAt(s.rolesList[role], idx);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Array {
	function removeAt(uint256[] storage array, uint256 index)
		internal
		returns (uint256[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAt(address[] storage array, uint256 index)
		internal
		returns (address[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAt(string[] storage array, uint256 index)
		internal
		returns (string[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function isEqual(address[] memory arr1, address[] memory arr2)
		internal
		pure
		returns (bool)
	{
		if (arr1.length != arr2.length) {
			return false;
		}

		for (uint256 i = 0; i < arr1.length; i++) {
			if (arr1[i] != arr2[i]) {
				return false;
			}
		}

		return true;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MeemPermission} from '../interfaces/MeemStandard.sol';

library PermissionsStorage {
	bytes32 internal constant STORAGE_SLOT =
		keccak256('meem.contracts.storage.Permissions');

	struct DataStore {
		uint256 maxSupply;
		MeemPermission[] mintPermissions;
		bool isTransferLocked;
	}

	function dataStore() internal pure returns (DataStore storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}