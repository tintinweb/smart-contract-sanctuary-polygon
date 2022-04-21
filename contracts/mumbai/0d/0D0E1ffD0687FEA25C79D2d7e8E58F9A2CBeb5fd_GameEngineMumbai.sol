// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
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

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}

    function _msgSender() internal view returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;
import "./IERC721.sol";
interface INFTFactory is IERC721{

    function restrictedChangeNft(uint tokenID, uint8 level) external;
    function tokenOwnerCall(uint tokenId) external view  returns (address);
    function burnNFT(uint tokenId) external ;
    function tokenOwnerSetter(uint tokenId, address _owner) external;
    function getTokenLevel(uint tokenId) external view returns(uint8);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IVRF{

    // function initiateRandomness(uint _tokenId,uint _timestamp) external view returns(uint);
    // function stealRandomness() external view returns(uint);
    // function getCurrentIndex() external view returns(uint);
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom(string memory seed0, uint256 seed1) external returns (uint256);
    function getRange(uint min, uint max,uint nonce) external returns(uint);
    function getRandView(uint256 nonce) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
import './Context.sol';

pragma solidity ^0.8.0;
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
    constructor ()  {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
/**
 * Author : Gordon
 */
pragma solidity ^0.8.0;

import "../base/INFTFactory.sol";
import "../base/Ownable.sol";
import "../base/IVRF.sol";
import "../base/ReentrancyGuard.sol";
import "./ProxyTarget.sol";

// import "hardhat/console.sol";

contract GameEngine is Ownable, ReentrancyGuard, ProxyTarget {
	bool public initialized;
	mapping(uint256 => uint256) public firstStakeLockPeriod;
	mapping(uint256 => bool) public stakeConfirmation;
	mapping(uint256 => bool) public isStaked;
	mapping(uint256 => uint256) public stakeTime;
	mapping(uint256 => uint256) public lastClaim;
	mapping(uint8 => uint256[]) public pool; // (1-5) levels
	mapping(uint256 => uint256) public levelOfToken;
	mapping(uint256 => uint256) public tokenToArrayPosition;
	mapping(uint256 => uint256) public tokenToRandomHourInStake;
	mapping(uint256 => bool) public wasUnstakedRecently;

	INFTFactory nftToken;
	IVRF public randomNumberGenerator;

	// bool public frenzyStarted;

	uint256 internal _nonce;
	////////////////// ---- data ends

	////////////////// events ------
	event LevelUp(address indexed owner, uint256 tokenId, uint256 levelTo);
	event Steal(address indexed receiver, address indexed loser, uint256 tokenId);
	event Die(address indexed owner, uint256 tokenId);
	////////////////// ------ events

	function initialize(
		address _randomEngineAddress,
		address _nftAddress
	) external {
		require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
		require(!initialized);
		initialized = true;

		_owner = msg.sender;

		nftToken = INFTFactory(_nftAddress);
		randomNumberGenerator = IVRF(_randomEngineAddress);
	}

	function setRandomNumberGenerator(address _randomEngineAddress) external {
		require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
		randomNumberGenerator = IVRF(_randomEngineAddress);
	}

	// ERC721 receiver
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) public pure returns (bytes4) {
		return 0x150b7a02;
	}

	function getPool(uint8 j) public view returns (uint256[] memory) {
		return pool[j];
	}

	function alertStake(uint256 tokenId) external virtual {
		require(isStaked[tokenId] == false);
		require(nftToken.ownerOf(tokenId) == address(this));
		uint256 randomNo = 2 + (randomNumberGenerator.getRandom("alertStake", _nonce++) % 5);
		firstStakeLockPeriod[tokenId] = block.timestamp + randomNo * 1 hours;
		isStaked[tokenId] = true;
		stakeTime[tokenId] = block.timestamp;
		tokenToRandomHourInStake[tokenId] = randomNo * 1 hours;
		levelOfToken[tokenId] = 1;
		determineAndPush(tokenId);
	}

	function stake(uint256[] memory tokenId) external virtual {
		for (uint256 i; i < tokenId.length; i++) {
			require(isStaked[tokenId[i]] == false);
			if (stakeConfirmation[tokenId[i]] == true) {
				nftToken.safeTransferFrom(msg.sender, address(this), tokenId[i]);
				stakeTime[tokenId[i]] = block.timestamp;
				isStaked[tokenId[i]] = true;
				determineAndPush(tokenId[i]);
			} else {
				require(firstStakeLockPeriod[tokenId[i]] == 0, "AlreadyStaked");
				uint256 randomNo = 2 + (randomNumberGenerator.getRandom("stake", _nonce++) % 5);
				firstStakeLockPeriod[tokenId[i]] = block.timestamp + randomNo * 1 hours;
				nftToken.safeTransferFrom(msg.sender, address(this), tokenId[i]);
				stakeTime[tokenId[i]] = block.timestamp;
				isStaked[tokenId[i]] = true;
				tokenToRandomHourInStake[tokenId[i]] = randomNo * 1 hours;
				levelOfToken[tokenId[i]] = 1;
				determineAndPush(tokenId[i]);
			}
		}
	}

	function moveToLast(uint256 _tokenId) internal {
		uint8 level = uint8(levelOfToken[_tokenId]);
		uint256 position = tokenToArrayPosition[_tokenId];
		uint256[] storage currentPool = pool[level];
		uint256 length = currentPool.length;
		uint256 lastToken = currentPool[length - 1];
		currentPool[position] = lastToken;
		tokenToArrayPosition[lastToken] = position;
		currentPool[length - 1] = _tokenId;
		currentPool.pop();
	}

	function determineAndPush(uint256 tokenId) internal {
		uint8 tokenLevel = uint8(levelOfToken[tokenId]);
		pool[tokenLevel].push(tokenId);
		tokenToArrayPosition[tokenId] = pool[tokenLevel].length - 1;
	}

	function unstakeBurnCalculator(uint8 tokenLevel) internal pure returns (uint256) {
		return 25 - 5 * tokenLevel;
	}

	function steal(uint256 nonce) internal returns (uint256) {
		uint256 randomNumber = randomNumberGenerator.getRandom("steal random", _nonce++);
		randomNumber = uint256(keccak256(abi.encodePacked(randomNumber, nonce)));
		uint8 level = whichLevelToChoose(randomNumber);

		if (level == 0) return 0; // should not steal because of no token to steal

		uint256 tokenToGet = randomNumber % pool[level].length;
		return pool[level][tokenToGet];
	}

	function whichLevelToChoose(uint256 randomNumber) internal view returns (uint8) {
		uint16[5] memory x = [1000, 875, 750, 625, 500];
		uint256 denom;
		for (uint8 level = 1; level < 6; level++) {
			denom += pool[level].length * x[level - 1];
		}
		if (denom == 0) return 0; // should not steal because of no token to steal

		uint256[5] memory stealing;
		for (uint8 level = 1; level < 6; level++) {
			stealing[level - 1] = (pool[level].length * x[level - 1] * 1000000) / denom;
		}
		uint8 levelToReturn;
		randomNumber = randomNumber % 1000000;
		if (randomNumber < stealing[0]) {
			levelToReturn = 1;
		} else if (randomNumber < stealing[0] + stealing[1]) {
			levelToReturn = 2;
		} else if (randomNumber < stealing[0] + stealing[1] + stealing[2]) {
			levelToReturn = 3;
		} else if (randomNumber < stealing[0] + stealing[1] + stealing[2] + stealing[3]) {
			levelToReturn = 4;
		} else if (randomNumber < stealing[0] + stealing[1] + stealing[2] + stealing[3] + stealing[4]) {
			levelToReturn = 5;
		}
		return levelToReturn;
	}

	function howManyTokensCanSteal() internal view returns (uint256) {
		uint256 totalStaked = getTotalStaked();

		for (uint256 i = 0; i < 5; i++) {
			if (50 <= 10 + 10 * i) {
				if (totalStaked >= 5 - i) {
					return 5 - i;
				}
				return totalStaked;
			}
		}
		if (totalStaked > 0) {
			return 1;
		}
		return 0;
	}

	function executeClaims(
		uint256 randomNumber,
		uint256 tokenId,
		uint256 firstHold,
		uint256 secondHold
	) internal virtual returns (bool) {
		if (randomNumber >= 0 && randomNumber < firstHold) {
			bool query = onSuccess(tokenId);
			return query;
		} else if (randomNumber >= firstHold && randomNumber < secondHold) {
			bool query = onCriticalSuccess(tokenId);
			return query;
		} else {
			bool query = onCriticalFail(tokenId);
			return query;
		}
	}

	function onSuccess(uint256 tokenId) internal virtual returns (bool) {
		require(lastClaim[tokenId] + 12 hours <= block.timestamp, "Claiming before 12 hours");
		lastClaim[tokenId] = block.timestamp;
		uint256 randomNumber = randomNumberGenerator.getRandom("onSuccess", _nonce++);
		randomNumber = uint256(keccak256(abi.encodePacked(randomNumber, "1"))) % 100;
		if (randomNumber < 32 && levelOfToken[tokenId] < 5) {
			moveToLast(tokenId);
			levelOfToken[tokenId]++;
			determineAndPush(tokenId);
			nftToken.restrictedChangeNft(tokenId, uint8(levelOfToken[tokenId]));
			emit LevelUp(msg.sender, tokenId, levelOfToken[tokenId]);
		}
		return false;
	}

	function onCriticalSuccess(uint256 tokenId) internal virtual returns (bool) {
		require(lastClaim[tokenId] + 12 hours <= block.timestamp, "Claiming before 12 hours");
		lastClaim[tokenId] = block.timestamp;
		if (
			uint256(keccak256(abi.encodePacked(randomNumberGenerator.getRandom("onCriticalSuccess", _nonce++), "1"))) % 100 < 40 &&
			levelOfToken[tokenId] < 5
		) {
			moveToLast(tokenId);
			levelOfToken[tokenId]++;
			determineAndPush(tokenId);
			nftToken.restrictedChangeNft(tokenId, uint8(levelOfToken[tokenId]));
			emit LevelUp(msg.sender, tokenId, levelOfToken[tokenId]);
		}
		uint256 value = howManyTokensCanSteal();

		uint256 stolenTokenId;

		for (uint256 i = 0; i < value; i++) {
			stolenTokenId = steal(i + 1);
			if (stolenTokenId != 0) {
				moveToLast(stolenTokenId);
				nftToken.restrictedChangeNft(stolenTokenId, uint8(levelOfToken[stolenTokenId])); //s->1

				// pool[nftType][uint8(levelOfToken[stolenTokenId])].push(stolenTokenId);
				// tokenToArrayPosition[stolenTokenId] = pool[nftType][uint8(levelOfToken[stolenTokenId])].length-1;
				determineAndPush(stolenTokenId);

				emit Steal(msg.sender, nftToken.tokenOwnerCall(stolenTokenId), stolenTokenId);
				nftToken.tokenOwnerSetter(stolenTokenId, msg.sender);
			}
		}
		return false;
	}

	function onCriticalFail(uint256 tokenId) internal returns (bool) {
		emit Die(nftToken.tokenOwnerCall(tokenId), tokenId);
		nftToken.burnNFT(tokenId);
		isStaked[tokenId] = false;
		moveToLast(tokenId);
		return true;
	}

	//VITAL INTERNAL FUNCITONS
	function claimStake(uint256 tokenId) internal returns (bool) {
		uint256 randomNumber = randomNumberGenerator.getRandom("claimStake", _nonce++) % 100;
		uint8 level = nftToken.getTokenLevel(tokenId);

		if (stakeConfirmation[tokenId] == false) {
			require(block.timestamp >= firstStakeLockPeriod[tokenId], "lock not over");
			stakeConfirmation[tokenId] = true;
			bool query = executeClaims(randomNumber, tokenId, 80, 88 + 2 * (level));
			return query;
		} else {
			bool query = executeClaims(randomNumber, tokenId, 80, 88 + 2 * (level));
			return query;
		}
	}

	function unstakeNFT(uint256 tokenId) internal {
		uint256 randomNumber = randomNumberGenerator.getRandom("unstakeNFT", _nonce++);
		if (stakeConfirmation[tokenId] == true) {
			uint256 level = levelOfToken[tokenId];
			uint256 burnPercent = unstakeBurnCalculator(uint8(level));
			if (randomNumber % 100 <= burnPercent) {
				emit Die(nftToken.tokenOwnerCall(tokenId), tokenId);
				nftToken.burnNFT(tokenId);
			} else {
				nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
				wasUnstakedRecently[tokenId] = true;
			}
			moveToLast(tokenId);
		} else {
			uint256 burnPercent = unstakeBurnCalculator(1);
			if (randomNumber % 100 <= burnPercent) {
				emit Die(nftToken.tokenOwnerCall(tokenId), tokenId);
				nftToken.burnNFT(tokenId);
			} else {
				nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
				wasUnstakedRecently[tokenId] = true;
			}
			moveToLast(tokenId);
		}
	}

	function claimAndUnstake(bool claim, uint256[] memory tokenAmount) external nonReentrant {
		for (uint256 i = 0; i < tokenAmount.length; i++) {
			require(nftToken.tokenOwnerCall(tokenAmount[i]) == msg.sender, "Caller not the owner");
			require(nftToken.ownerOf(tokenAmount[i]) == address(this), "Contract not the owner");
			require(isStaked[tokenAmount[i]] = true, "Not Staked");
			require(
				stakeTime[tokenAmount[i]] + tokenToRandomHourInStake[tokenAmount[i]] <= block.timestamp,
				"Be Patient"
			);
			if (claim == true) {
				claimStake(tokenAmount[i]);
			} else {
				bool isBurnt = claimStake(tokenAmount[i]);
				if (isBurnt == false) {
					unstakeNFT(tokenAmount[i]);
					isStaked[tokenAmount[i]] = false;
				}
			}
		}
	}

	function getTotalStaked() public view returns (uint256) {
		uint256 totalStaked;
		for (uint8 j = 1; j < 6; j++) {
			totalStaked += pool[j].length;
		}
		return totalStaked;
	}

	/**
	 * Utility method to get token info
	 *
	 * returns (level, isStaked, stakeTime, lastClaimTime, tokenToRandomHourInStake)
	 */
	function getTokenMeta(uint256 tokenId)
		public
		view
		returns (
			uint8,
			bool,
			uint256,
			uint256,
			uint256
		)
	{
		uint8 level_ = nftToken.getTokenLevel(tokenId);
		return (
			level_, // todo -- levelOfToken[tokenId]?
			isStaked[tokenId],
			stakeTime[tokenId],
			lastClaim[tokenId],
			tokenToRandomHourInStake[tokenId]
		);
	}
}

pragma solidity ^0.8.0;

/// @dev Proxy for NFT Factory
contract ProxyTarget {

    // Storage for this proxy
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
    bytes32 internal constant ADMIN_SLOT          = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    function _getAddress(bytes32 key) internal view returns (address add) {
        add = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
/**
 * Author : Gordon
 */
pragma solidity ^0.8.0;

import "../main/GameEngine.sol";
// import "hardhat/console.sol";

contract GameEngineMumbai is GameEngine {


	function alertStake(uint256 tokenId) external virtual override {
		require(isStaked[tokenId] == false);
		require(nftToken.ownerOf(tokenId) == address(this));
		uint256 randomNo = 2 + (randomNumberGenerator.getRandom("alertStake", _nonce++) % 5);
		firstStakeLockPeriod[tokenId] = block.timestamp + 1;
		isStaked[tokenId] = true;
		stakeTime[tokenId] = block.timestamp;
		tokenToRandomHourInStake[tokenId] = 1;
		levelOfToken[tokenId] = 1;
		determineAndPush(tokenId);
	}

	function stake(uint256[] memory tokenId) external virtual override {
		for (uint256 i; i < tokenId.length; i++) {
			require(isStaked[tokenId[i]] == false);
			if (stakeConfirmation[tokenId[i]] == true) {
				nftToken.safeTransferFrom(msg.sender, address(this), tokenId[i]);
				stakeTime[tokenId[i]] = block.timestamp;
				isStaked[tokenId[i]] = true;
				determineAndPush(tokenId[i]);
			} else {
				require(firstStakeLockPeriod[tokenId[i]] == 0, "AlreadyStaked");
				uint256 randomNo = 2 + (randomNumberGenerator.getRandom("stake", _nonce++) % 5);
				firstStakeLockPeriod[tokenId[i]] = block.timestamp + 1;
				nftToken.safeTransferFrom(msg.sender, address(this), tokenId[i]);
				stakeTime[tokenId[i]] = block.timestamp;
				isStaked[tokenId[i]] = true;
				tokenToRandomHourInStake[tokenId[i]] = 1;
				levelOfToken[tokenId[i]] = 1;
				determineAndPush(tokenId[i]);
			}
		}
	}


	function executeClaims(
		uint256 randomNumber,
		uint256 tokenId,
		uint256 firstHold,
		uint256 secondHold
	) internal virtual override returns (bool) {
			bool query = onCriticalSuccess(tokenId);
			return query;
		// if (randomNumber >= 0 && randomNumber < firstHold) {
		// 	bool query = onSuccess(tokenId);
		// 	return query;
		// } else if (randomNumber >= firstHold && randomNumber < secondHold) {
		// 	bool query = onCriticalSuccess(tokenId);
		// 	return query;
		// } else {
		// 	bool query = onCriticalFail(tokenId);
		// 	return query;
		// }
	}

	function onSuccess(uint256 tokenId) internal virtual override returns (bool) {
		// require(lastClaim[tokenId] + 12 hours <= block.timestamp, "Claiming before 12 hours");
		lastClaim[tokenId] = block.timestamp;
		uint256 randomNumber = randomNumberGenerator.getRandom("onSuccess", _nonce++);
		randomNumber = uint256(keccak256(abi.encodePacked(randomNumber, "1"))) % 100;
		if (randomNumber < 32 && levelOfToken[tokenId] < 5) {
			moveToLast(tokenId);
			levelOfToken[tokenId]++;
			determineAndPush(tokenId);
			nftToken.restrictedChangeNft(tokenId, uint8(levelOfToken[tokenId]));
			emit LevelUp(msg.sender, tokenId, levelOfToken[tokenId]);
		}
		return false;
	}
    
	function onCriticalSuccess(uint256 tokenId) internal virtual override returns (bool) {
		// require(lastClaim[tokenId] + 12 hours <= block.timestamp, "Claiming before 12 hours");
		lastClaim[tokenId] = block.timestamp;
		if (
			uint256(keccak256(abi.encodePacked(randomNumberGenerator.getRandom("onCriticalSuccess", _nonce++), "1"))) % 100 < 40 &&
			levelOfToken[tokenId] < 5
		) {
			moveToLast(tokenId);
			levelOfToken[tokenId]++;
			determineAndPush(tokenId);
			nftToken.restrictedChangeNft(tokenId, uint8(levelOfToken[tokenId]));
			emit LevelUp(msg.sender, tokenId, levelOfToken[tokenId]);
		}
		uint256 value = howManyTokensCanSteal();

		uint256 stolenTokenId;

		for (uint256 i = 0; i < value; i++) {
			stolenTokenId = steal(i + 1);
			if (stolenTokenId != 0) {
				moveToLast(stolenTokenId);
				nftToken.restrictedChangeNft(stolenTokenId, uint8(levelOfToken[stolenTokenId])); //s->1

				// pool[nftType][uint8(levelOfToken[stolenTokenId])].push(stolenTokenId);
				// tokenToArrayPosition[stolenTokenId] = pool[nftType][uint8(levelOfToken[stolenTokenId])].length-1;
				determineAndPush(stolenTokenId);

				emit Steal(msg.sender, nftToken.tokenOwnerCall(stolenTokenId), stolenTokenId);
				nftToken.tokenOwnerSetter(stolenTokenId, msg.sender);
			}
		}
		return false;
	}
}