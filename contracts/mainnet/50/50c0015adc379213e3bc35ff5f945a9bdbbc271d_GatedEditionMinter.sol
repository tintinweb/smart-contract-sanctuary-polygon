// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IEdition {
    event PriceChanged(uint256 amount);
    event ExternalUrlUpdated(string oldExternalUrl, string newExternalUrl);
    event PropertyUpdated(string name, string oldValue, string newValue);

    function contractURI() external view returns (string memory);

    function editionSize() external view returns (uint256);

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _animationUrl,
        string memory _imageUrl,
        uint256 _editionSize,
        uint256 _royaltyBPS,
        uint256 _mintPeriodSeconds
    ) external;

    function enableDefaultOperatorFilter() external;

    function endOfMintPeriod() external view returns (uint256);

    function isMintingEnded() external view returns (bool);

    function mint(address to) external payable returns (uint256);

    function safeMint(address to) external payable returns (uint256);

    function mintBatch(address[] memory recipients) external payable returns (uint256);

    function salePrice() external view returns (uint256);

    function setApprovedMinter(address minter, bool allowed) external;

    function setExternalUrl(string calldata _externalUrl) external;

    function setOperatorFilter(address operatorFilter) external;

    function setStringProperties(string[] calldata names, string[] calldata values) external;

    function setSalePrice(uint256 _salePrice) external;

    function totalSupply() external view returns (uint256);

    function withdraw() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IEdition} from "nft-editions/interfaces/IEdition.sol";

import {IShowtimeVerifier, SignedAttestation} from "src/interfaces/IShowtimeVerifier.sol";
import {IGatedEditionMinter} from "./interfaces/IGatedEditionMinter.sol";

contract GatedEditionMinter is IGatedEditionMinter {
    error NullAddress();
    error VerificationFailed();

    IShowtimeVerifier public immutable override showtimeVerifier;

    constructor(IShowtimeVerifier _showtimeVerifier) {
        if (address(_showtimeVerifier) == address(0)) {
            revert NullAddress();
        }

        showtimeVerifier = _showtimeVerifier;
    }

    /// @param signedAttestation the attestation to verify along with a corresponding signature
    /// @dev the edition to mint will be determined by the attestation's context
    /// @dev the recipient of the minted edition will be determined by the attestation's beneficiary
    function mintEdition(SignedAttestation calldata signedAttestation) public override {
        IEdition collection = IEdition(signedAttestation.attestation.context);

        if (!showtimeVerifier.verifyAndBurn(signedAttestation)) {
            revert VerificationFailed();
        }

        collection.mint(signedAttestation.attestation.beneficiary);
    }

    /// @notice a batch version of mintEdition
    /// @notice any failed call to mintEdition will revert the entire batch
    function mintEditions(SignedAttestation[] calldata signedAttestations) external override {
        uint256 length = signedAttestations.length;
        for (uint256 i = 0; i < length;) {
            mintEdition(signedAttestations[i]);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IShowtimeVerifier, SignedAttestation} from "src/interfaces/IShowtimeVerifier.sol";

interface IGatedEditionMinter {
    function mintEdition(SignedAttestation calldata signedAttestation) external;

    function mintEditions(SignedAttestation[] calldata signedAttestation) external;

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

    function nonces(address) external view returns (uint256);

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

    function registerAndRevoke(address signerToRegister, address signerToRevoke, uint256 validityDays)
        external
        returns (uint256 validUntil);
}