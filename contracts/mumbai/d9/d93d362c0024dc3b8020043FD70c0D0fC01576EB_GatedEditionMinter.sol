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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IEditionSingleMintable {
  function mintEdition(address to) external returns (uint256);
  function mintEditions(address[] memory to) external returns (uint256);
  function numberCanMint() external view returns (uint256);
  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IEditionSingleMintable } from "@zoralabs/nft-editions-contracts/contracts/IEditionSingleMintable.sol";
import { IShowtimeVerifier, SignedAttestation } from "src/interfaces/IShowtimeVerifier.sol";
import { IGatedEditionMinter } from "./interfaces/IGatedEditionMinter.sol";
import { TimeCop } from "./TimeCop.sol";

contract GatedEditionMinter is IGatedEditionMinter {
    error NullAddress();
    error TimeLimitReached(IEditionSingleMintable collection);
    error VerificationFailed();

    IShowtimeVerifier public immutable showtimeVerifier;
    TimeCop public immutable timeCop;

    constructor(IShowtimeVerifier _showtimeVerifier, TimeCop _timeCop) {
        if (address(_showtimeVerifier) == address(0) || address(_timeCop) == address(0)) {
            revert NullAddress();
        }

        showtimeVerifier = _showtimeVerifier;
        timeCop = _timeCop;
    }

    /// @param signedAttestation the attestation to verify along with a corresponding signature
    /// @dev the edition to mint will be determined by the attestation's context
    /// @dev the recipient of the minted edition will be determined by the attestation's beneficiary
    function mintEdition(SignedAttestation calldata signedAttestation) external override {
        IEditionSingleMintable collection = IEditionSingleMintable(signedAttestation.attestation.context);

        if (timeCop.timeLimitReached(address(collection))) {
            revert TimeLimitReached(collection);
        }

        if (!showtimeVerifier.verifyAndBurn(signedAttestation)) {
            revert VerificationFailed();
        }

        collection.mintEdition(signedAttestation.attestation.beneficiary);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract TimeCop {
    event TimeLimitSet(address collection, uint256 deadline);

    error InvalidTimeLimit(uint256 offsetSeconds);
    error NotCollectionOwner();
    error TimeLimitAlreadySet();

    uint256 public immutable MAX_DURATION_SECONDS;

    /// @notice the time limits expressed as a timestamp in seconds
    mapping(address => uint256) public timeLimits;

    /// @param _maxDurationSeconds maximum time limit
    /// @dev _maxDurationSeconds can be set to 0 to have no maximum time limit
    constructor(uint256 _maxDurationSeconds) {
        MAX_DURATION_SECONDS = _maxDurationSeconds;
    }

    /// @notice Sets the deadline for the given collection
    /// @notice Only the owner of the collection can set the deadline
    /// @param collection The address to set the deadline for
    /// @param offsetSeconds a duration in seconds that will be used to set the time limit
    function setTimeLimit(address collection, uint256 offsetSeconds) external {
        if (offsetSeconds == 0) {
            revert InvalidTimeLimit(offsetSeconds);
        }

        if (MAX_DURATION_SECONDS > 0 && offsetSeconds > MAX_DURATION_SECONDS) {
            revert InvalidTimeLimit(offsetSeconds);
        }

        if (timeLimitSet(collection)) {
            revert TimeLimitAlreadySet();
        }

        if (msg.sender != Ownable(collection).owner()) {
            revert NotCollectionOwner();
        }

        uint256 deadline = block.timestamp + offsetSeconds;
        timeLimits[collection] = deadline;

        emit TimeLimitSet(collection, deadline);
    }

    function timeLimitSet(address collection) public view returns (bool) {
        return timeLimits[collection] > 0;
    }

    /// @return false if there is no time limit set for that collection
    function timeLimitReached(address collection) public view returns (bool) {
        return timeLimitSet(collection) && block.timestamp > timeLimits[collection];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IShowtimeVerifier, SignedAttestation } from "src/interfaces/IShowtimeVerifier.sol";

interface IGatedEditionMinter {
    function mintEdition(SignedAttestation calldata signedAttestation) external;

    function showtimeVerifier() external view returns (IShowtimeVerifier);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct Attestation {
    address beneficiary;
    address context;
    uint256 nonce;
    uint256 validUntil;
}

struct SignedAttestation {
    Attestation attestation;
    bytes signature;
}

interface IShowtimeVerifier {
    error BadNonce(uint256 expected, uint256 actual);
    error DeadlineTooLong();
    error Expired();
    error NullAddress();
    error SignerExpired(address signer);
    error Unauthorized();
    error UnknownSigner();

    event SignerAdded(address signer, uint256 validUntil);
    event SignerRevoked(address signer);
    event ManagerUpdated(address newManager);

    function verify(SignedAttestation calldata signedAttestation) external view returns (bool);

    function verifyAndBurn(SignedAttestation calldata signedAttestation) external returns (bool);

    function verify(
        Attestation calldata attestation,
        bytes32 typeHash,
        bytes memory encodedData,
        bytes calldata signature
    ) external view returns (bool);

    function verifyAndBurn(
        Attestation calldata attestation,
        bytes32 typeHash,
        bytes memory encodedData,
        bytes calldata signature
    ) external returns (bool);

    function setManager(address _manager) external;

    function registerSigner(address signer, uint256 validityDays) external returns (uint256 validUntil);

    function revokeSigner(address signer) external;

    function registerAndRevoke(
        address signerToRegister,
        address signerToRevoke,
        uint256 validityDays
    ) external returns (uint256 validUntil);
}