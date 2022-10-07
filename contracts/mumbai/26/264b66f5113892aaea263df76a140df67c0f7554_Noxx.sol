// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import './interfaces/INoxx.sol';
import './interfaces/INoxxABT.sol';
import './interfaces/IVerifier.sol';

/// @title Contract that manages proof verification/minting
/// @author Tomo
/// @dev does proof verification and mint in the separate process.
contract Noxx is INoxx {
  IVerifier verifier;
  INoxxABT noxxABT;

  /// mapping for checking verifications
  mapping(address => bool) private verifiedAccounts;

  constructor(IVerifier _verifier, INoxxABT _noxxABT) {
    verifier = _verifier;
    noxxABT = _noxxABT;
  }

  /// @dev Verify zk proof, if valid then add to the allowed list
  function executeProofVerification(
    uint256[8] calldata proof,
    uint256[4] calldata input,
    address from
  ) external returns (bool) {
    // See IVerifier for detail
    bool isValid = verifier.verifyProof(
      [proof[0], proof[1]],
      [[proof[2], proof[3]], [proof[4], proof[5]]],
      [proof[6], proof[7]],
      input
    );
    require(isValid, 'Proof Verification failed');
    verifiedAccounts[from] = true;
    return isValid;
  }

  /// @dev mintNFT if user is in the allowed list
  function mintNFT(address to, string memory _tokenURI) external {
    require(verifiedAccounts[to], 'Not verified to mint NFT');
    noxxABT.mint(to, _tokenURI);
  }

  function isVerifiedAccount(address account) public view returns (bool) {
    return verifiedAccounts[account];
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface INoxx {
  /// @dev Verify zk proof, if valid then add to the allowed list
  function executeProofVerification(
    uint256[8] calldata proof,
    uint256[4] calldata input,
    address from
  ) external returns (bool);

  /// @dev mintNFT if user is in the allowed list
  function mintNFT(address to, string memory _tokenURI) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface INoxxABT {
  /// @dev Mint token to a specific address. Token can be minted only once per address.
  /// @param to The address that will receive the minted tokens.
  /// @param tokenURI the tokenURI
  function mint(address to, string memory tokenURI) external;

  /// @dev Update tokenURI
  /// @param tokenId Id that requires update.
  /// @param tokenURI the new tokenURI
  function updateTokenURI(uint256 tokenId, string memory tokenURI) external;

  /// @dev Return tokenId from owner address
  /// @param owner owner address
  function tokenByOwner(address owner) external view returns (uint256);

  /// @dev Return tokenURI from owner address
  /// @param owner owner address
  function tokenURIByOwner(address owner) external view returns (string memory);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @title Verifier interface.
/// @dev Interface of Verifier contract.
interface IVerifier {
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    // Public input. in the order of commits[3](name, age, countrycode) and age
    uint256[4] memory input
  ) external view returns (bool);
}