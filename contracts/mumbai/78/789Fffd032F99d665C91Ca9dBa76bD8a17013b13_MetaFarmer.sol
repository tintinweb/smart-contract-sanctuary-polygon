// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IEnergyFarmer.sol";
import "./interfaces/IMetaFarmer.sol";
import "./interfaces/IOnchainArtworkFarmer.sol";
import "./interfaces/IRegistryFarmer.sol";
import "./interfaces/IRevealFarmer.sol";

import "./libraries/LibraryFarmer.sol";

contract MetaFarmer is IMetaFarmer, Ownable {
	using LibraryFarmer for LibraryFarmer.Passion;
	using LibraryFarmer for LibraryFarmer.Skill;
	using LibraryFarmer for LibraryFarmer.VisualTraitType;
	using LibraryFarmer for LibraryFarmer.FarmerContract;
	using LibraryFarmer for LibraryFarmer.FarmerMetadata;
	using Counters for Counters.Counter;
	using Strings for uint8;
	using Strings for uint256;

	IRegistryFarmer public registryFarmer;

	// Metadata
	string[3] public passions = [
		"Harvesting", // 0
		"Fishing", // 1
		"Planting" // 2
	];
	string[6] public skills = [
		"Degen", // 0
		"Honesty", // 1
		"Fitness", // 2
		"Strategy", // 3
		"Patience", // 4
		"Agility" // 5
	];
	string[8] public visualTraitTypes = [
		"Background", // 0
		"Skin", // 1
		"Clothing", // 2
		"Mouth", // 3
		"Nose", // 4
		"Head", // 5
		"Eyes", // 6
		"Ears" // 7
	];
	mapping(uint256 => uint256) public passionIdByInternalTokenId;
	mapping(uint256 => bool) public isSpecialByInternalTokenId;
	mapping(uint256 => string) public specialNameByInternalTokenId;

	mapping(LibraryFarmer.VisualTraitType => mapping(uint256 => string))
		public visualTraitsByTraitIdByTraitType;
	mapping(LibraryFarmer.VisualTraitType => mapping(uint256 => uint256))
		public visualTraitValueIdByInternalTokenIdByTraitType;

	// Artwork
	mapping(uint256 => string) public ipfsHashByInternalTokenId;
	string public unrevealedIpfsHash;
	bool public isOnChainArtworkReady;

	constructor(
		IRegistryFarmer _registryFarmer,
		string memory _unrevealedIpfsHash
	) {
		registryFarmer = _registryFarmer;
		unrevealedIpfsHash = _unrevealedIpfsHash;
	}

	// Passion
	function getPassionTraitMetadata(uint256 internalTokenId, bool isRevealed)
		public
		view
		returns (string memory)
	{
		uint256 passionId = passionIdByInternalTokenId[internalTokenId];

		return
			string(
				abi.encodePacked(
					'{"trait_type":"Passion",',
					'"value":"',
					isRevealed ? passions[passionId] : "Howdy",
					'"}'
				)
			);
	}

	// Skills
	function getSkillTraitMetadata(
		LibraryFarmer.Skill skillId,
		uint256 internalTokenId
	) public view returns (string memory) {
		string memory skillName = skills[uint256(skillId)];

		IEnergyFarmer energyFarmer = IEnergyFarmer(
			registryFarmer.contracts(LibraryFarmer.FarmerContract.EnergyFarmer)
		);
		uint8 level = energyFarmer.getSkillLevel(skillId, internalTokenId);
		uint8 MAX_SKILL_LEVEL = energyFarmer.MAX_SKILL_LEVEL();

		return
			string(
				abi.encodePacked(
					'{"trait_type":"',
					skillName,
					'","value":',
					level.toString(),
					',"max_value":',
					MAX_SKILL_LEVEL.toString(),
					"}"
				)
			);
	}

	function compileSkillTraits(uint256 internalTokenId)
		public
		view
		returns (string memory)
	{
		string memory skillTraits = string(
			abi.encodePacked(
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Degen,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Honesty,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Fitness,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Strategy,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Patience,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Agility,
					internalTokenId
				)
			)
		);
		return skillTraits;
	}

	// Visuals
	function getVisualTraitMetadata(
		LibraryFarmer.VisualTraitType traitTypeId,
		uint256 internalTokenId,
		bool isRevealed
	) public view returns (string memory) {
		string memory traitType = visualTraitTypes[uint256(traitTypeId)];

		uint256 traitValueId = visualTraitValueIdByInternalTokenIdByTraitType[
			traitTypeId
		][internalTokenId];
		string memory traitValue = isRevealed
			? visualTraitsByTraitIdByTraitType[traitTypeId][traitValueId]
			: "Howdy";

		return
			string(
				abi.encodePacked(
					'{"trait_type":"',
					traitType,
					'","value":"',
					traitValue,
					'"}'
				)
			);
	}

	function compileVisualTraits(uint256 internalTokenId, bool isRevealed)
		public
		view
		returns (string memory)
	{
		string memory visualTraits = string(
			abi.encodePacked(
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Background,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Skin,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Clothing,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Mouth,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Nose,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Head,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Eyes,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Ears,
					internalTokenId,
					isRevealed
				)
			)
		);

		return visualTraits;
	}

	function compileAttributes(uint256 internalTokenId, bool isRevealed)
		public
		view
		returns (string memory)
	{
		string memory passionTrait = getPassionTraitMetadata(
			internalTokenId,
			isRevealed
		);
		string memory skillTraits = compileSkillTraits(internalTokenId);

		bool isSpecial = isSpecialByInternalTokenId[internalTokenId];
		if (isSpecial) {
			string memory specialName = specialNameByInternalTokenId[
				internalTokenId
			];
			string memory visualTrait = string(
				abi.encodePacked(
					'{"trait_type":"Specials","value":"',
					specialName,
					'"}'
				)
			);

			return _getPackedAttributes(passionTrait, skillTraits, visualTrait);
		}

		string memory visualTraits = compileVisualTraits(
			internalTokenId,
			isRevealed
		);

		return _getPackedAttributes(passionTrait, skillTraits, visualTraits);
	}

	// Artwork
	function getIPFSImageUrl(uint256 internalTokenId, bool isRevealed)
		public
		view
		returns (string memory)
	{
		return
			string(
				abi.encodePacked(
					"https://ipfs.io/ipfs/",
					isRevealed
						? ipfsHashByInternalTokenId[internalTokenId]
						: unrevealedIpfsHash
				)
			);
	}

	function getOnChainSVGBase64ImageUrl(
		uint256 internalTokenId,
		bool isRevealed
	) public view returns (string memory) {
		IOnchainArtworkFarmer onchainArtworkFarmer = IOnchainArtworkFarmer(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.OnchainArtworkFarmer
			)
		);
		return onchainArtworkFarmer.uri(internalTokenId, isRevealed);
	}

	function getMetadata(uint256 tokenId) public view returns (string memory) {
		uint256 internalTokenId = getInternalTokenId(tokenId);
		bool isRevealed = internalTokenId >= 1;

		string memory imageUrl = isOnChainArtworkReady
			? getOnChainSVGBase64ImageUrl(internalTokenId, isRevealed)
			: getIPFSImageUrl(internalTokenId, isRevealed);
		string memory metadata = string(
			abi.encodePacked(
				'{"name":"Honest Farmer #',
				tokenId.toString(),
				'","description":"Just some honest farmers.","image":"',
				imageUrl,
				'","attributes":',
				compileAttributes(internalTokenId, isRevealed),
				"}"
			)
		);

		return metadata;
	}

	function uri(uint256 tokenId) public view returns (string memory) {
		string memory metadata = getMetadata(tokenId);

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					base64(bytes(metadata))
				)
			);
	}

	// Utilities
	function getInternalTokenId(uint256 tokenId) public view returns (uint256) {
		IRevealFarmer revealFarmer = IRevealFarmer(
			registryFarmer.contracts(LibraryFarmer.FarmerContract.RevealFarmer)
		);

		return revealFarmer.getInternalTokenId(tokenId);
	}

	function _getPackedAttributes(
		string memory passionTrait,
		string memory skillTraits,
		string memory visualTrait
	) private pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					"[",
					passionTrait,
					",",
					skillTraits,
					",",
					visualTrait,
					"]"
				)
			);
	}

	function setVisualTraitValues(
		LibraryFarmer.VisualTraitType traitTypeId,
		string[] memory visualTraitValues
	) public onlyOwner {
		for (uint256 i = 0; i < visualTraitValues.length; i++) {
			string memory visualTraitValue = visualTraitValues[i];

			visualTraitsByTraitIdByTraitType[traitTypeId][i] = visualTraitValue;
		}
	}

	function setSpecialName(uint256 internalTokenId, string memory specialName)
		public
		onlyOwner
	{
		specialNameByInternalTokenId[internalTokenId] = specialName;
	}

	function setIsOnChainArtworkReady(bool _isOnChainArtworkReady)
		public
		onlyOwner
	{
		isOnChainArtworkReady = _isOnChainArtworkReady;
	}

	/**
	 * Visual trait sets are hand picked, but randomly assigned
	 */
	function setInternalTokenMetadata(
		LibraryFarmer.FarmerMetadata[] memory metadata
	) public onlyOwner {
		for (uint256 i = 0; i < metadata.length; i++) {
			uint256 internalTokenId = metadata[i].internalTokenId;

			ipfsHashByInternalTokenId[internalTokenId] = metadata[i].ipfsHash;

			for (uint8 j = 0; j < 8; j++) {
				uint8 visualTraitValueId = metadata[i].visualTraitValueIds[j];

				visualTraitValueIdByInternalTokenIdByTraitType[
					LibraryFarmer.VisualTraitType(j)
				][internalTokenId] = visualTraitValueId;
			}

			if (metadata[i].isSpecial) {
				isSpecialByInternalTokenId[internalTokenId] = true;
			}
		}
	}

	/** BASE 64 - Credits to WizardsAndDragons/Brech Devos */
	string internal constant TABLE =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	function base64(bytes memory data) internal pure returns (string memory) {
		if (data.length == 0) return "";

		// load the table into memory
		string memory table = TABLE;

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((data.length + 2) / 3);

		// add some extra buffer at the end required for the writing
		string memory result = new string(encodedLen + 32);

		assembly {
			// set the actual output length
			mstore(result, encodedLen)

			// prepare the lookup table
			let tablePtr := add(table, 1)

			// input ptr
			let dataPtr := data
			let endPtr := add(dataPtr, mload(data))

			// result ptr, jump over length
			let resultPtr := add(result, 32)

			// run over the input, 3 bytes at a time
			for {

			} lt(dataPtr, endPtr) {

			} {
				dataPtr := add(dataPtr, 3)

				// read 3 bytes
				let input := mload(dataPtr)

				// write 4 characters
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(input, 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
			}

			// padding with '='
			switch mod(mload(data), 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}
		}

		return result;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../libraries/LibraryFarmer.sol";

interface IEnergyFarmer {
	function MAX_SKILL_LEVEL() external view returns (uint8);

	function getSkillLevel(LibraryFarmer.Skill skillId, uint256 internalTokenId)
		external
		view
		returns (uint8);

	function increaseXP(uint256 internalTokenId, uint256 xpIncrement) external;

	function levelUp(LibraryFarmer.Skill skillId, uint256 internalTokenId)
		external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMetaFarmer {
	function uri(uint256 internalTokenId) external view returns (string memory);

	function isSpecialByInternalTokenId(uint256 internalTokenId)
		external
		view
		returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IOnchainArtworkFarmer {
	function uri(uint256 internalTokenId, bool isRevealed)
		external
		view
		returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../libraries/LibraryFarmer.sol";

interface IRegistryFarmer {
	function contracts(LibraryFarmer.FarmerContract _contract)
		external
		view
		returns (address);

	function updateContract(
		LibraryFarmer.FarmerContract _contract,
		address _address
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../libraries/LibraryFarmer.sol";

interface IRevealFarmer {
	function getInternalTokenId(uint256 tokenId)
		external
		view
		returns (uint256 internalTokenId);

	function isRevealed(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library LibraryFarmer {
	// Metadata
	enum Passion {
		Harvesting,
		Fishing,
		Planting
	}

	enum Skill {
		Degen,
		Honesty,
		Fitness,
		Strategy,
		Patience,
		Agility
	}

	enum VisualTraitType {
		Background,
		Skin,
		Clothing,
		Mouth,
		Nose,
		Head,
		Eyes,
		Ears
	}

	struct FarmerMetadata {
		uint256 internalTokenId;
		uint8[8] visualTraitValueIds;
		bool isSpecial;
		string ipfsHash;
	}

	// Mint
	enum MintType {
		PUBLIC,
		WHITELIST,
		FREE
	}

	function isWhitelistMintType(LibraryFarmer.MintType mintType)
		public
		pure
		returns (bool)
	{
		return mintType == LibraryFarmer.MintType.WHITELIST;
	}

	// Infrastructure
	enum FarmerContract {
		HonestFarmerClubV1,
		HonestFarmerClubV2,
		EnergyFarmer,
		MetaFarmer,
		MigrationTractor,
		OnchainArtworkFarmer,
		RevealFarmer,
		WhitelistFarmer
	}
}

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

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}