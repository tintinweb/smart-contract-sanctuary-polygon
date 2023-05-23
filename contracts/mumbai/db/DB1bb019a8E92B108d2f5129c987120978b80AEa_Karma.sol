//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAttestationCheckerVerifier {
  function verifyProof(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    // attestation type
    // attestation merkle root
    // entanglement
    // attestation hash
    // attestor pubkey
    uint[5] memory input
  ) external view returns (bool r);
}

//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPasswordCheckerVerifier {
  function verifyProof(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    // attestation type
    // nullifier
    // entanglement merkle root
    uint[3] memory input
  ) external view returns (bool r);
}

//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";
import "./interfaces/IAttestationCheckerVerifier.sol";
import "./interfaces/IPasswordCheckerVerifier.sol";

contract KetlAttestation is ERC1155, Ownable, Versioned, ERC2771Recipient {
  using Counters for Counters.Counter;
  using IncrementalBinaryTree for IncrementalTreeData;

  // Attestations
  uint32 public currentTokenId;
  uint public attestorPublicKey;
  mapping(uint => uint) public attestationMerkleRoots;
  IAttestationCheckerVerifier public attestationCheckerVerifier;
  // Entanglements
  mapping(uint => IncrementalTreeData) public entanglementsTrees;
  mapping(uint => uint[]) public entanglements;
  mapping(uint => mapping(bytes32 => bool)) public entanglementsRoots;
  mapping(uint => bool) private attestationHashesEntangled;

  mapping(uint => Counters.Counter) public entanglementsCounts;
  mapping(uint => uint16) private minimumEntanglementCounts;
  IPasswordCheckerVerifier public passwordCheckerVerifier;
  // Nullifiers
  mapping(uint => bool) public nullifiers;
  // Legacy
  bool public legacyMintLocked;

  constructor(
    string memory _uri,
    string memory _version,
    uint _attestorPublicKey,
    address _attestationCheckerVerifier,
    address _passwordCheckerVerifier,
    address _forwarder
  ) ERC1155(_uri) Versioned(_version) {
    attestorPublicKey = _attestorPublicKey;
    attestationCheckerVerifier = IAttestationCheckerVerifier(
      _attestationCheckerVerifier
    );
    passwordCheckerVerifier = IPasswordCheckerVerifier(
      _passwordCheckerVerifier
    );
    _setTrustedForwarder(_forwarder);
  }

  function setUri(string memory _uri) public onlyOwner {
    _setURI(_uri);
  }

  function setAttestationMerkleRoot(
    uint _id,
    uint _merkleRoot,
    uint16 _minimumEntanglementCount
  ) public onlyOwner {
    attestationMerkleRoots[_id] = _merkleRoot;
    minimumEntanglementCounts[_id] = _minimumEntanglementCount;
    entanglementsTrees[_id].init(20, 0);
  }

  function setMinimumEntanglementCount(
    uint _id,
    uint16 _minimumEntanglementCount
  ) public onlyOwner {
    minimumEntanglementCounts[_id] = _minimumEntanglementCount;
  }

  function setCurrentTokenId(uint32 _currentTokenId) public onlyOwner {
    currentTokenId = _currentTokenId;
  }

  function registerEntanglement(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[5] memory input
  ) external {
    // Destruct the input
    uint attestationType = input[0];
    uint attestationMerkleRoot = input[1];
    uint entanglement = input[2];
    uint attestationHash = input[3];
    uint attestationPublicKey = input[4];
    // Check the proof
    require(
      attestationCheckerVerifier.verifyProof(a, b, c, input),
      "Invalid ZK proof"
    );
    // Check if this attestation has already been used
    require(
      !attestationHashesEntangled[attestationHash],
      "Attestation has already been entangled"
    );
    // Check the attestations merkle root
    require(
      attestationMerkleRoots[attestationType] == attestationMerkleRoot,
      "Attestation merkle root is wrong"
    );
    // Check the attestation pubkey
    require(
      attestationPublicKey == attestorPublicKey,
      "Attestation public key is wrong"
    );
    // Save the entanglement fact
    attestationHashesEntangled[attestationHash] = true;
    // Add the entanglement to the tree
    entanglementsTrees[attestationType].insert(entanglement);
    // Save the entanglement in the array
    entanglements[attestationType].push(entanglement);
    // Increment the entanglement count
    entanglementsCounts[attestationType].increment();
    // Register the entanglement root
    bytes32 merkleRoot = bytes32(entanglementsTrees[attestationType].root);
    entanglementsRoots[attestationType][merkleRoot] = true;
  }

  function mint(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[3] memory input
  ) external {
    // Deconstruct input
    uint _attestationType = input[0];
    uint _nullifier = input[1];
    uint _entanglementMerkleRoot = input[2];
    // Check requirements
    require(
      passwordCheckerVerifier.verifyProof(a, b, c, input),
      "ZKP is not valid"
    );
    require(!nullifiers[_nullifier], "Nullifier has already been used");
    require(
      entanglementsRoots[_attestationType][bytes32(_entanglementMerkleRoot)],
      "Entanglement merkle root is not valid"
    );
    // Save nullifier
    nullifiers[_nullifier] = true;
    // Mint token
    _mint(_msgSender(), _attestationType, 1, "");
  }

  // Legacy mint

  function legacyBatchMint(
    address[] memory _to,
    uint[] memory _ids
  ) external onlyOwner {
    require(!legacyMintLocked, "Legacy mint is locked");
    for (uint i = 0; i < _to.length; i++) {
      _mint(_to[i], _ids[i], 1, "");
    }
  }

  function lockLegacyMint() external onlyOwner {
    legacyMintLocked = true;
  }

  // Make it soulbound

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) internal override {
    require(from == address(0), "This token is soulbound");
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // OpenGSN boilerplate

  function _msgSender()
    internal
    view
    override(Context, ERC2771Recipient)
    returns (address sender)
  {
    sender = ERC2771Recipient._msgSender();
  }

  function _msgData()
    internal
    view
    override(Context, ERC2771Recipient)
    returns (bytes calldata ret)
  {
    return ERC2771Recipient._msgData();
  }
}

//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Versioned {
  string public version;

  constructor(string memory _version) {
    version = _version;
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PoseidonT3} from "poseidon-solidity/PoseidonT3.sol";

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct IncrementalTreeData {
    uint256 depth; // Depth of the tree (levels - 1).
    uint256 root; // Root hash of the tree.
    uint256 numberOfLeaves; // Number of leaves of the tree.
    mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
    mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
    bool useDefaultZeroes;
}

/// @title Incremental binary Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalBinaryTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 public constant Z_0 = 0;
    uint256 public constant Z_1 = 14744269619966411208579211824598458697587494354926760081771325075741142829156;
    uint256 public constant Z_2 = 7423237065226347324353380772367382631490014989348495481811164164159255474657;
    uint256 public constant Z_3 = 11286972368698509976183087595462810875513684078608517520839298933882497716792;
    uint256 public constant Z_4 = 3607627140608796879659380071776844901612302623152076817094415224584923813162;
    uint256 public constant Z_5 = 19712377064642672829441595136074946683621277828620209496774504837737984048981;
    uint256 public constant Z_6 = 20775607673010627194014556968476266066927294572720319469184847051418138353016;
    uint256 public constant Z_7 = 3396914609616007258851405644437304192397291162432396347162513310381425243293;
    uint256 public constant Z_8 = 21551820661461729022865262380882070649935529853313286572328683688269863701601;
    uint256 public constant Z_9 = 6573136701248752079028194407151022595060682063033565181951145966236778420039;
    uint256 public constant Z_10 = 12413880268183407374852357075976609371175688755676981206018884971008854919922;
    uint256 public constant Z_11 = 14271763308400718165336499097156975241954733520325982997864342600795471836726;
    uint256 public constant Z_12 = 20066985985293572387227381049700832219069292839614107140851619262827735677018;
    uint256 public constant Z_13 = 9394776414966240069580838672673694685292165040808226440647796406499139370960;
    uint256 public constant Z_14 = 11331146992410411304059858900317123658895005918277453009197229807340014528524;
    uint256 public constant Z_15 = 15819538789928229930262697811477882737253464456578333862691129291651619515538;
    uint256 public constant Z_16 = 19217088683336594659449020493828377907203207941212636669271704950158751593251;
    uint256 public constant Z_17 = 21035245323335827719745544373081896983162834604456827698288649288827293579666;
    uint256 public constant Z_18 = 6939770416153240137322503476966641397417391950902474480970945462551409848591;
    uint256 public constant Z_19 = 10941962436777715901943463195175331263348098796018438960955633645115732864202;
    uint256 public constant Z_20 = 15019797232609675441998260052101280400536945603062888308240081994073687793470;
    uint256 public constant Z_21 = 11702828337982203149177882813338547876343922920234831094975924378932809409969;
    uint256 public constant Z_22 = 11217067736778784455593535811108456786943573747466706329920902520905755780395;
    uint256 public constant Z_23 = 16072238744996205792852194127671441602062027943016727953216607508365787157389;
    uint256 public constant Z_24 = 17681057402012993898104192736393849603097507831571622013521167331642182653248;
    uint256 public constant Z_25 = 21694045479371014653083846597424257852691458318143380497809004364947786214945;
    uint256 public constant Z_26 = 8163447297445169709687354538480474434591144168767135863541048304198280615192;
    uint256 public constant Z_27 = 14081762237856300239452543304351251708585712948734528663957353575674639038357;
    uint256 public constant Z_28 = 16619959921569409661790279042024627172199214148318086837362003702249041851090;
    uint256 public constant Z_29 = 7022159125197495734384997711896547675021391130223237843255817587255104160365;
    uint256 public constant Z_30 = 4114686047564160449611603615418567457008101555090703535405891656262658644463;
    uint256 public constant Z_31 = 12549363297364877722388257367377629555213421373705596078299904496781819142130;
    uint256 public constant Z_32 = 21443572485391568159800782191812935835534334817699172242223315142338162256601;

    function defaultZero(uint256 index) public pure returns (uint256) {
        if (index == 0) return Z_0;
        if (index == 1) return Z_1;
        if (index == 2) return Z_2;
        if (index == 3) return Z_3;
        if (index == 4) return Z_4;
        if (index == 5) return Z_5;
        if (index == 6) return Z_6;
        if (index == 7) return Z_7;
        if (index == 8) return Z_8;
        if (index == 9) return Z_9;
        if (index == 10) return Z_10;
        if (index == 11) return Z_11;
        if (index == 12) return Z_12;
        if (index == 13) return Z_13;
        if (index == 14) return Z_14;
        if (index == 15) return Z_15;
        if (index == 16) return Z_16;
        if (index == 17) return Z_17;
        if (index == 18) return Z_18;
        if (index == 19) return Z_19;
        if (index == 20) return Z_20;
        if (index == 21) return Z_21;
        if (index == 22) return Z_22;
        if (index == 23) return Z_23;
        if (index == 24) return Z_24;
        if (index == 25) return Z_25;
        if (index == 26) return Z_26;
        if (index == 27) return Z_27;
        if (index == 28) return Z_28;
        if (index == 29) return Z_29;
        if (index == 30) return Z_30;
        if (index == 31) return Z_31;
        if (index == 32) return Z_32;
        revert("IncrementalBinaryTree: defaultZero bad index");
    }

    /// @dev Initializes a tree.
    /// @param self: Tree data.
    /// @param depth: Depth of the tree.
    /// @param zero: Zero value to be used.
    function init(
        IncrementalTreeData storage self,
        uint256 depth,
        uint256 zero
    ) public {
        require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        self.depth = depth;

        for (uint8 i = 0; i < depth; ) {
            self.zeroes[i] = zero;
            zero = PoseidonT3.hash([zero, zero]);

            unchecked {
                ++i;
            }
        }

        self.root = zero;
    }

    function initWithDefaultZeroes(IncrementalTreeData storage self, uint256 depth) public {
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        self.depth = depth;
        self.useDefaultZeroes = true;

        self.root = defaultZero(depth);
    }

    /// @dev Inserts a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be inserted.
    function insert(IncrementalTreeData storage self, uint256 leaf) public returns (uint256) {
        uint256 depth = self.depth;

        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**depth, "IncrementalBinaryTree: tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = leaf;
        bool useDefaultZeroes = self.useDefaultZeroes;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                self.lastSubtrees[i] = [hash, useDefaultZeroes ? defaultZero(i) : self.zeroes[i]];
            } else {
                self.lastSubtrees[i][1] = hash;
            }

            hash = PoseidonT3.hash(self.lastSubtrees[i]);
            index >>= 1;

            unchecked {
                ++i;
            }
        }

        self.root = hash;
        self.numberOfLeaves += 1;
        return hash;
    }

    /// @dev Updates a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be updated.
    /// @param newLeaf: New leaf.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function update(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256 newLeaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        require(newLeaf != leaf, "IncrementalBinaryTree: new leaf cannot be the same as the old one");
        require(newLeaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: new leaf must be < SNARK_SCALAR_FIELD");
        require(
            verify(self, leaf, proofSiblings, proofPathIndices),
            "IncrementalBinaryTree: leaf is not part of the tree"
        );

        uint256 depth = self.depth;
        uint256 hash = newLeaf;
        uint256 updateIndex;

        for (uint8 i = 0; i < depth; ) {
            updateIndex |= uint256(proofPathIndices[i]) << uint256(i);

            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == self.lastSubtrees[i][1]) {
                    self.lastSubtrees[i][0] = hash;
                }

                hash = PoseidonT3.hash([hash, proofSiblings[i]]);
            } else {
                if (proofSiblings[i] == self.lastSubtrees[i][0]) {
                    self.lastSubtrees[i][1] = hash;
                }

                hash = PoseidonT3.hash([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }
        require(updateIndex < self.numberOfLeaves, "IncrementalBinaryTree: leaf index out of range");

        self.root = hash;
    }

    /// @dev Removes a leaf from the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function remove(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        update(self, leaf, self.useDefaultZeroes ? Z_0 : self.zeroes[0], proofSiblings, proofPathIndices);
    }

    /// @dev Verify if the path is correct and the leaf is part of the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    /// @return True or false.
    function verify(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        uint256 depth = self.depth;
        require(
            proofPathIndices.length == depth && proofSiblings.length == depth,
            "IncrementalBinaryTree: length of path is not correct"
        );

        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            require(
                proofSiblings[i] < SNARK_SCALAR_FIELD,
                "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
            );

            require(
                proofPathIndices[i] == 1 || proofPathIndices[i] == 0,
                "IncrementalBinaryTree: path index is neither 0 nor 1"
            );

            if (proofPathIndices[i] == 0) {
                hash = PoseidonT3.hash([hash, proofSiblings[i]]);
            } else {
                hash = PoseidonT3.hash([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }

        return hash == self.root;
    }
}

//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./superclasses/KetlGuarded.sol";

contract Karma is ERC20Upgradeable, KetlGuarded {
  function initializeKarma(
    string memory name,
    string memory symbol,
    uint _ketlTeamTokenId,
    address _allowedCaller
  ) public initializer {
    __ERC20_init(name, symbol);
    KetlGuarded.initialize(address(this), _ketlTeamTokenId, _allowedCaller);
  }

  function mint(address to, uint amount) public onlyAllowedCaller {
    _mint(to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(from == address(0), "Karma: transfer not allowed");
  }
}

//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@big-whale-labs/ketl-attestation-token/contracts/KetlAttestation.sol";

contract KetlGuarded is Initializable, OwnableUpgradeable {
  KetlAttestation public attestationToken;
  uint public ketlTeamTokenId;
  address public allowedCaller;

  function initialize(
    address _attestationToken,
    uint _ketlTeamTokenId,
    address _allowedCaller
  ) public initializer {
    __Ownable_init();
    attestationToken = KetlAttestation(_attestationToken);
    ketlTeamTokenId = _ketlTeamTokenId;
    allowedCaller = _allowedCaller;
  }

  function setAllowedCaller(address _allowedCaller) public onlyOwner {
    allowedCaller = _allowedCaller;
  }

  modifier onlyAllowedCaller() {
    require(
      msg.sender == allowedCaller,
      "AllowedCallerChecker: Only allowed caller can call this function"
    );
    _;
  }

  modifier onlyKetlTokenOwners(address sender) {
    for (uint32 i = 0; i < attestationToken.currentTokenId(); i++) {
      if (attestationToken.balanceOf(sender, i) > 0) {
        _;
        return;
      }
    }
    revert("KetlGuarded: sender not allowed");
  }
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library PoseidonT3 {
  uint constant M00 = 0x109b7f411ba0e4c9b2b70caf5c36a7b194be7c11ad24378bfedb68592ba8118b;
  uint constant M01 = 0x2969f27eed31a480b9c36c764379dbca2cc8fdd1415c3dded62940bcde0bd771;
  uint constant M02 = 0x143021ec686a3f330d5f9e654638065ce6cd79e28c5b3753326244ee65a1b1a7;
  uint constant M10 = 0x16ed41e13bb9c0c66ae119424fddbcbc9314dc9fdbdeea55d6c64543dc4903e0;
  uint constant M11 = 0x2e2419f9ec02ec394c9871c832963dc1b89d743c8c7b964029b2311687b1fe23;
  uint constant M12 = 0x176cc029695ad02582a70eff08a6fd99d057e12e58e7d7b6b16cdfabc8ee2911;

  // See here for a simplified implementation: https://github.com/vimwitch/poseidon-solidity/blob/e57becdabb65d99fdc586fe1e1e09e7108202d53/contracts/Poseidon.sol#L40
  // Based on: https://github.com/iden3/circomlibjs/blob/v0.0.8/src/poseidon_slow.js
  function hash(uint[2] memory) public pure returns (uint) {
    assembly {
      let F := 21888242871839275222246405745257275088548364400416034343698204186575808495617
      let M20 := 0x2b90bba00fca0589f617e7dcbfe82e0df706ab640ceb247b791a93b74e36736d
      let M21 := 0x101071f0032379b697315876690f053d148d4e109f5fb065c8aacc55a0f89bfa
      let M22 := 0x19a3fc0a56702bf417ba7fee3802593fa644470307043f7773279cd71d25d5e0
      // load the inputs from memory
      let state0
      let scratch0
      let state1
      let scratch1
      let state2
      let scratch2

      state1 := addmod(mload(0x80), 0x00f1445235f2148c5986587169fc1bcd887b08d4d00868df5696fff40956e864, F)
      state2 := addmod(mload(0xa0), 0x08dff3487e8ac99e1f29a058d0fa80b930c728730b7ab36ce879f3890ecf73f5, F)
      scratch0 := mulmod(state1, state1, F)
      state1 := mulmod(mulmod(scratch0, scratch0, F), state1, F)
      scratch0 := mulmod(state2, state2, F)
      state2 := mulmod(mulmod(scratch0, scratch0, F), state2, F)
      scratch0 := addmod(
        0x2f27be690fdaee46c3ce28f7532b13c856c35342c84bda6e20966310fadc01d0,
        addmod(addmod(15452833169820924772166449970675545095234312153403844297388521437673434406763, mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x2b2ae1acf68b7b8d2416bebf3d4f6234b763fe04b8043ee48b8327bebca16cf2,
        addmod(addmod(18674271267752038776579386132900109523609358935013267566297499497165104279117, mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x0319d062072bef7ecca5eac06f97d4d55952c175ab6b03eae64b44c7dbf11cfa,
        addmod(addmod(14817777843080276494683266178512808687156649753153012854386334860566696099579, mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := mulmod(scratch1, scratch1, F)
      scratch1 := mulmod(mulmod(state0, state0, F), scratch1, F)
      state0 := mulmod(scratch2, scratch2, F)
      scratch2 := mulmod(mulmod(state0, state0, F), scratch2, F)
      state0 := addmod(
        0x28813dcaebaeaa828a376df87af4a63bc8b7bf27ad49c6298ef7b387bf28526d,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x2727673b2ccbc903f181bf38e1c1d40d2033865200c352bc150928adddf9cb78,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x234ec45ca27727c2e74abd2b2a1494cd6efbd43e340587d6b8fb9e31e65cc632,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := mulmod(state1, state1, F)
      state1 := mulmod(mulmod(scratch0, scratch0, F), state1, F)
      scratch0 := mulmod(state2, state2, F)
      state2 := mulmod(mulmod(scratch0, scratch0, F), state2, F)
      scratch0 := addmod(
        0x15b52534031ae18f7f862cb2cf7cf760ab10a8150a337b1ccd99ff6e8797d428,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x0dc8fad6d9e4b35f5ed9a3d186b79ce38e0e8a8d1b58b132d701d4eecf68d1f6,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x1bcd95ffc211fbca600f705fad3fb567ea4eb378f62e1fec97805518a47e4d9c,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := mulmod(scratch1, scratch1, F)
      scratch1 := mulmod(mulmod(state0, state0, F), scratch1, F)
      state0 := mulmod(scratch2, scratch2, F)
      scratch2 := mulmod(mulmod(state0, state0, F), scratch2, F)
      state0 := addmod(
        0x10520b0ab721cadfe9eff81b016fc34dc76da36c2578937817cb978d069de559,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x1f6d48149b8e7f7d9b257d8ed5fbbaf42932498075fed0ace88a9eb81f5627f6,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x1d9655f652309014d29e00ef35a2089bfff8dc1c816f0dc9ca34bdb5460c8705,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x04df5a56ff95bcafb051f7b1cd43a99ba731ff67e47032058fe3d4185697cc7d,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x0672d995f8fff640151b3d290cedaf148690a10a8c8424a7f6ec282b6e4be828,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x099952b414884454b21200d7ffafdd5f0c9a9dcc06f2708e9fc1d8209b5c75b9,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x052cba2255dfd00c7c483143ba8d469448e43586a9b4cd9183fd0e843a6b9fa6,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x0b8badee690adb8eb0bd74712b7999af82de55707251ad7716077cb93c464ddc,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x119b1590f13307af5a1ee651020c07c749c15d60683a8050b963d0a8e4b2bdd1,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x03150b7cd6d5d17b2529d36be0f67b832c4acfc884ef4ee5ce15be0bfb4a8d09,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x2cc6182c5e14546e3cf1951f173912355374efb83d80898abe69cb317c9ea565,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x005032551e6378c450cfe129a404b3764218cadedac14e2b92d2cd73111bf0f9,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x233237e3289baa34bb147e972ebcb9516469c399fcc069fb88f9da2cc28276b5,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x05c8f4f4ebd4a6e3c980d31674bfbe6323037f21b34ae5a4e80c2d4c24d60280,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x0a7b1db13042d396ba05d818a319f25252bcf35ef3aeed91ee1f09b2590fc65b,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x2a73b71f9b210cf5b14296572c9d32dbf156e2b086ff47dc5df542365a404ec0,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x1ac9b0417abcc9a1935107e9ffc91dc3ec18f2c4dbe7f22976a760bb5c50c460,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x12c0339ae08374823fabb076707ef479269f3e4d6cb104349015ee046dc93fc0,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x0b7475b102a165ad7f5b18db4e1e704f52900aa3253baac68246682e56e9a28e,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x037c2849e191ca3edb1c5e49f6e8b8917c843e379366f2ea32ab3aa88d7f8448,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x05a6811f8556f014e92674661e217e9bd5206c5c93a07dc145fdb176a716346f,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x29a795e7d98028946e947b75d54e9f044076e87a7b2883b47b675ef5f38bd66e,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x20439a0c84b322eb45a3857afc18f5826e8c7382c8a1585c507be199981fd22f,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x2e0ba8d94d9ecf4a94ec2050c7371ff1bb50f27799a84b6d4a2a6f2a0982c887,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x143fd115ce08fb27ca38eb7cce822b4517822cd2109048d2e6d0ddcca17d71c8,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x0c64cbecb1c734b857968dbbdcf813cdf8611659323dbcbfc84323623be9caf1,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x028a305847c683f646fca925c163ff5ae74f348d62c2b670f1426cef9403da53,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x2e4ef510ff0b6fda5fa940ab4c4380f26a6bcb64d89427b824d6755b5db9e30c,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x0081c95bc43384e663d79270c956ce3b8925b4f6d033b078b96384f50579400e,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x2ed5f0c91cbd9749187e2fade687e05ee2491b349c039a0bba8a9f4023a0bb38,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x30509991f88da3504bbf374ed5aae2f03448a22c76234c8c990f01f33a735206,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x1c3f20fd55409a53221b7c4d49a356b9f0a1119fb2067b41a7529094424ec6ad,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x10b4e7f3ab5df003049514459b6e18eec46bb2213e8e131e170887b47ddcb96c,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x2a1982979c3ff7f43ddd543d891c2abddd80f804c077d775039aa3502e43adef,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x1c74ee64f15e1db6feddbead56d6d55dba431ebc396c9af95cad0f1315bd5c91,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x07533ec850ba7f98eab9303cace01b4b9e4f2e8b82708cfa9c2fe45a0ae146a0,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x21576b438e500449a151e4eeaf17b154285c68f42d42c1808a11abf3764c0750,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x2f17c0559b8fe79608ad5ca193d62f10bce8384c815f0906743d6930836d4a9e,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x2d477e3862d07708a79e8aae946170bc9775a4201318474ae665b0b1b7e2730e,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x162f5243967064c390e095577984f291afba2266c38f5abcd89be0f5b2747eab,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x2b4cb233ede9ba48264ecd2c8ae50d1ad7a8596a87f29f8a7777a70092393311,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x2c8fbcb2dd8573dc1dbaf8f4622854776db2eece6d85c4cf4254e7c35e03b07a,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x1d6f347725e4816af2ff453f0cd56b199e1b61e9f601e9ade5e88db870949da9,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x204b0c397f4ebe71ebc2d8b3df5b913df9e6ac02b68d31324cd49af5c4565529,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x0c4cb9dc3c4fd8174f1149b3c63c3c2f9ecb827cd7dc25534ff8fb75bc79c502,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x174ad61a1448c899a25416474f4930301e5c49475279e0639a616ddc45bc7b54,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x1a96177bcf4d8d89f759df4ec2f3cde2eaaa28c177cc0fa13a9816d49a38d2ef,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x066d04b24331d71cd0ef8054bc60c4ff05202c126a233c1a8242ace360b8a30a,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x2a4c4fc6ec0b0cf52195782871c6dd3b381cc65f72e02ad527037a62aa1bd804,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x13ab2d136ccf37d447e9f2e14a7cedc95e727f8446f6d9d7e55afc01219fd649,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x1121552fca26061619d24d843dc82769c1b04fcec26f55194c2e3e869acc6a9a,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x00ef653322b13d6c889bc81715c37d77a6cd267d595c4a8909a5546c7c97cff1,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x0e25483e45a665208b261d8ba74051e6400c776d652595d9845aca35d8a397d3,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x29f536dcb9dd7682245264659e15d88e395ac3d4dde92d8c46448db979eeba89,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x2a56ef9f2c53febadfda33575dbdbd885a124e2780bbea170e456baace0fa5be,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x1c8361c78eb5cf5decfb7a2d17b5c409f2ae2999a46762e8ee416240a8cb9af1,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x151aff5f38b20a0fc0473089aaf0206b83e8e68a764507bfd3d0ab4be74319c5,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x04c6187e41ed881dc1b239c88f7f9d43a9f52fc8c8b6cdd1e76e47615b51f100,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x13b37bd80f4d27fb10d84331f6fb6d534b81c61ed15776449e801b7ddc9c2967,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x01a5c536273c2d9df578bfbd32c17b7a2ce3664c2a52032c9321ceb1c4e8a8e4,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x2ab3561834ca73835ad05f5d7acb950b4a9a2c666b9726da832239065b7c3b02,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x1d4d8ec291e720db200fe6d686c0d613acaf6af4e95d3bf69f7ed516a597b646,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x041294d2cc484d228f5784fe7919fd2bb925351240a04b711514c9c80b65af1d,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x154ac98e01708c611c4fa715991f004898f57939d126e392042971dd90e81fc6,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x0b339d8acca7d4f83eedd84093aef51050b3684c88f8b0b04524563bc6ea4da4,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x0955e49e6610c94254a4f84cfbab344598f0e71eaff4a7dd81ed95b50839c82e,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x06746a6156eba54426b9e22206f15abca9a6f41e6f535c6f3525401ea0654626,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x0f18f5a0ecd1423c496f3820c549c27838e5790e2bd0a196ac917c7ff32077fb,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x04f6eeca1751f7308ac59eff5beb261e4bb563583ede7bc92a738223d6f76e13,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x2b56973364c4c4f5c1a3ec4da3cdce038811eb116fb3e45bc1768d26fc0b3758,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x123769dd49d5b054dcd76b89804b1bcb8e1392b385716a5d83feb65d437f29ef,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x2147b424fc48c80a88ee52b91169aacea989f6446471150994257b2fb01c63e9,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x0fdc1f58548b85701a6c5505ea332a29647e6f34ad4243c2ea54ad897cebe54d,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x12373a8251fea004df68abcf0f7786d4bceff28c5dbbe0c3944f685cc0a0b1f2,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x21e4f4ea5f35f85bad7ea52ff742c9e8a642756b6af44203dd8a1f35c1a90035,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x16243916d69d2ca3dfb4722224d4c462b57366492f45e90d8a81934f1bc3b147,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x1efbe46dd7a578b4f66f9adbc88b4378abc21566e1a0453ca13a4159cac04ac2,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x07ea5e8537cf5dd08886020e23a7f387d468d5525be66f853b672cc96a88969a,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x05a8c4f9968b8aa3b7b478a30f9a5b63650f19a75e7ce11ca9fe16c0b76c00bc,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x20f057712cc21654fbfe59bd345e8dac3f7818c701b9c7882d9d57b72a32e83f,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x04a12ededa9dfd689672f8c67fee31636dcd8e88d01d49019bd90b33eb33db69,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x27e88d8c15f37dcee44f1e5425a51decbd136ce5091a6767e49ec9544ccd101a,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x2feed17b84285ed9b8a5c8c5e95a41f66e096619a7703223176c41ee433de4d1,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x1ed7cc76edf45c7c404241420f729cf394e5942911312a0d6972b8bd53aff2b8,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x15742e99b9bfa323157ff8c586f5660eac6783476144cdcadf2874be45466b1a,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x1aac285387f65e82c895fc6887ddf40577107454c6ec0317284f033f27d0c785,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x25851c3c845d4790f9ddadbdb6057357832e2e7a49775f71ec75a96554d67c77,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x15a5821565cc2ec2ce78457db197edf353b7ebba2c5523370ddccc3d9f146a67,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x2411d57a4813b9980efa7e31a1db5966dcf64f36044277502f15485f28c71727,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x002e6f8d6520cd4713e335b8c0b6d2e647e9a98e12f4cd2558828b5ef6cb4c9b,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x2ff7bc8f4380cde997da00b616b0fcd1af8f0e91e2fe1ed7398834609e0315d2,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x00b9831b948525595ee02724471bcd182e9521f6b7bb68f1e93be4febb0d3cbe,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x0a2f53768b8ebf6a86913b0e57c04e011ca408648a4743a87d77adbf0c9c3512,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x00248156142fd0373a479f91ff239e960f599ff7e94be69b7f2a290305e1198d,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x171d5620b87bfb1328cf8c02ab3f0c9a397196aa6a542c2350eb512a2b2bcda9,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x170a4f55536f7dc970087c7c10d6fad760c952172dd54dd99d1045e4ec34a808,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x29aba33f799fe66c2ef3134aea04336ecc37e38c1cd211ba482eca17e2dbfae1,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x1e9bc179a4fdd758fdd1bb1945088d47e70d114a03f6a0e8b5ba650369e64973,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x1dd269799b660fad58f7f4892dfb0b5afeaad869a9c4b44f9c9e1c43bdaf8f09,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x22cdbc8b70117ad1401181d02e15459e7ccd426fe869c7c95d1dd2cb0f24af38,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x0ef042e454771c533a9f57a55c503fcefd3150f52ed94a7cd5ba93b9c7dacefd,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x11609e06ad6c8fe2f287f3036037e8851318e8b08a0359a03b304ffca62e8284,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x1166d9e554616dba9e753eea427c17b7fecd58c076dfe42708b08f5b783aa9af,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x2de52989431a859593413026354413db177fbf4cd2ac0b56f855a888357ee466,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x3006eb4ffc7a85819a6da492f3a8ac1df51aee5b17b8e89d74bf01cf5f71e9ad,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x2af41fbb61ba8a80fdcf6fff9e3f6f422993fe8f0a4639f962344c8225145086,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x119e684de476155fe5a6b41a8ebc85db8718ab27889e85e781b214bace4827c3,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x1835b786e2e8925e188bea59ae363537b51248c23828f047cff784b97b3fd800,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x28201a34c594dfa34d794996c6433a20d152bac2a7905c926c40e285ab32eeb6,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x083efd7a27d1751094e80fefaf78b000864c82eb571187724a761f88c22cc4e7,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x0b6f88a3577199526158e61ceea27be811c16df7774dd8519e079564f61fd13b,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x0ec868e6d15e51d9644f66e1d6471a94589511ca00d29e1014390e6ee4254f5b,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x2af33e3f866771271ac0c9b3ed2e1142ecd3e74b939cd40d00d937ab84c98591,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x0b520211f904b5e7d09b5d961c6ace7734568c547dd6858b364ce5e47951f178,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x0b2d722d0919a1aad8db58f10062a92ea0c56ac4270e822cca228620188a1d40,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x1f790d4d7f8cf094d980ceb37c2453e957b54a9991ca38bbe0061d1ed6e562d4,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x0171eb95dfbf7d1eaea97cd385f780150885c16235a2a6a8da92ceb01e504233,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x0c2d0e3b5fd57549329bf6885da66b9b790b40defd2c8650762305381b168873,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x1162fb28689c27154e5a8228b4e72b377cbcafa589e283c35d3803054407a18d,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x2f1459b65dee441b64ad386a91e8310f282c5a92a89e19921623ef8249711bc0,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x1e6ff3216b688c3d996d74367d5cd4c1bc489d46754eb712c243f70d1b53cfbb,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x01ca8be73832b8d0681487d27d157802d741a6f36cdc2a0576881f9326478875,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x1f7735706ffe9fc586f976d5bdf223dc680286080b10cea00b9b5de315f9650e,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x2522b60f4ea3307640a0c2dce041fba921ac10a3d5f096ef4745ca838285f019,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x23f0bee001b1029d5255075ddc957f833418cad4f52b6c3f8ce16c235572575b,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x2bc1ae8b8ddbb81fcaac2d44555ed5685d142633e9df905f66d9401093082d59,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x0f9406b8296564a37304507b8dba3ed162371273a07b1fc98011fcd6ad72205f,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x2360a8eb0cc7defa67b72998de90714e17e75b174a52ee4acb126c8cd995f0a8,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x15871a5cddead976804c803cbaef255eb4815a5e96df8b006dcbbc2767f88948,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x193a56766998ee9e0a8652dd2f3b1da0362f4f54f72379544f957ccdeefb420f,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x2a394a43934f86982f9be56ff4fab1703b2e63c8ad334834e4309805e777ae0f,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x1859954cfeb8695f3e8b635dcb345192892cd11223443ba7b4166e8876c0d142,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x04e1181763050e58013444dbcb99f1902b11bc25d90bbdca408d3819f4fed32b,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x0fdb253dee83869d40c335ea64de8c5bb10eb82db08b5e8b1f5e5552bfd05f23,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x058cbe8a9a5027bdaa4efb623adead6275f08686f1c08984a9d7c5bae9b4f1c0,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x1382edce9971e186497eadb1aeb1f52b23b4b83bef023ab0d15228b4cceca59a,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x03464990f045c6ee0819ca51fd11b0be7f61b8eb99f14b77e1e6634601d9e8b5,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x23f7bfc8720dc296fff33b41f98ff83c6fcab4605db2eb5aaa5bc137aeb70a58,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x0a59a158e3eec2117e6e94e7f0e9decf18c3ffd5e1531a9219636158bbaf62f2,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x06ec54c80381c052b58bf23b312ffd3ce2c4eba065420af8f4c23ed0075fd07b,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x118872dc832e0eb5476b56648e867ec8b09340f7a7bcb1b4962f0ff9ed1f9d01,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x13d69fa127d834165ad5c7cba7ad59ed52e0b0f0e42d7fea95e1906b520921b1,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x169a177f63ea681270b1c6877a73d21bde143942fb71dc55fd8a49f19f10c77b,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x04ef51591c6ead97ef42f287adce40d93abeb032b922f66ffb7e9a5a7450544d,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x256e175a1dc079390ecd7ca703fb2e3b19ec61805d4f03ced5f45ee6dd0f69ec,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x30102d28636abd5fe5f2af412ff6004f75cc360d3205dd2da002813d3e2ceeb2,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x10998e42dfcd3bbf1c0714bc73eb1bf40443a3fa99bef4a31fd31be182fcc792,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x193edd8e9fcf3d7625fa7d24b598a1d89f3362eaf4d582efecad76f879e36860,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x18168afd34f2d915d0368ce80b7b3347d1c7a561ce611425f2664d7aa51f0b5d,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x29383c01ebd3b6ab0c017656ebe658b6a328ec77bc33626e29e2e95b33ea6111,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x10646d2f2603de39a1f4ae5e7771a64a702db6e86fb76ab600bf573f9010c711,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x0beb5e07d1b27145f575f1395a55bf132f90c25b40da7b3864d0242dcb1117fb,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x16d685252078c133dc0d3ecad62b5c8830f95bb2e54b59abdffbf018d96fa336,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x0a6abd1d833938f33c74154e0404b4b40a555bbbec21ddfafd672dd62047f01a,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x1a679f5d36eb7b5c8ea12a4c2dedc8feb12dffeec450317270a6f19b34cf1860,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x0980fb233bd456c23974d50e0ebfde4726a423eada4e8f6ffbc7592e3f1b93d6,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x161b42232e61b84cbf1810af93a38fc0cece3d5628c9282003ebacb5c312c72b,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x0ada10a90c7f0520950f7d47a60d5e6a493f09787f1564e5d09203db47de1a0b,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x1a730d372310ba82320345a29ac4238ed3f07a8a2b4e121bb50ddb9af407f451,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x2c8120f268ef054f817064c369dda7ea908377feaba5c4dffbda10ef58e8c556,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x1c7c8824f758753fa57c00789c684217b930e95313bcb73e6e7b8649a4968f70,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x2cd9ed31f5f8691c8e39e4077a74faa0f400ad8b491eb3f7b47b27fa3fd1cf77,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x23ff4f9d46813457cf60d92f57618399a5e022ac321ca550854ae23918a22eea,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x09945a5d147a4f66ceece6405dddd9d0af5a2c5103529407dff1ea58f180426d,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x188d9c528025d4c2b67660c6b771b90f7c7da6eaa29d3f268a6dd223ec6fc630,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x3050e37996596b7f81f68311431d8734dba7d926d3633595e0c0d8ddf4f0f47f,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x15af1169396830a91600ca8102c35c426ceae5461e3f95d89d829518d30afd78,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x1da6d09885432ea9a06d9f37f873d985dae933e351466b2904284da3320d8acc,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := addmod(
        0x2796ea90d269af29f5f8acf33921124e4e4fad3dbe658945e546ee411ddaa9cb,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x202d7dd1da0f6b4b0325c8b3307742f01e15612ec8e9304a7cb0319e01d32d60,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x096d6790d05bb759156a952ba263d672a2d7f9c788f4c831a29dace4c0f8be5f,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := addmod(
        0x054efa1f65b0fce283808965275d877b438da23ce5b13e1963798cb1447d25a4,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x1b162f83d917e93edb3308c29802deb9d8aa690113b2e14864ccf6e18e4165f1,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x21e5241e12564dd6fd9f1cdd2a0de39eedfefc1466cc568ec5ceb745a0506edc,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := mulmod(scratch1, scratch1, F)
      scratch1 := mulmod(mulmod(state0, state0, F), scratch1, F)
      state0 := mulmod(scratch2, scratch2, F)
      scratch2 := mulmod(mulmod(state0, state0, F), scratch2, F)
      state0 := addmod(
        0x1cfb5662e8cf5ac9226a80ee17b36abecb73ab5f87e161927b4349e10e4bdf08,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x0f21177e302a771bbae6d8d1ecb373b62c99af346220ac0129c53f666eb24100,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x1671522374606992affb0dd7f71b12bec4236aede6290546bcef7e1f515c2320,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := mulmod(state1, state1, F)
      state1 := mulmod(mulmod(scratch0, scratch0, F), state1, F)
      scratch0 := mulmod(state2, state2, F)
      state2 := mulmod(mulmod(scratch0, scratch0, F), state2, F)
      scratch0 := addmod(
        0x0fa3ec5b9488259c2eb4cf24501bfad9be2ec9e42c5cc8ccd419d2a692cad870,
        addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F),
        F
      )
      scratch1 := addmod(
        0x193c0e04e0bd298357cb266c1506080ed36edce85c648cc085e8c57b1ab54bba,
        addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F),
        F
      )
      scratch2 := addmod(
        0x102adf8ef74735a27e9128306dcbc3c99f6f7291cd406578ce14ea2adaba68f8,
        addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F),
        F
      )
      state0 := mulmod(scratch0, scratch0, F)
      scratch0 := mulmod(mulmod(state0, state0, F), scratch0, F)
      state0 := mulmod(scratch1, scratch1, F)
      scratch1 := mulmod(mulmod(state0, state0, F), scratch1, F)
      state0 := mulmod(scratch2, scratch2, F)
      scratch2 := mulmod(mulmod(state0, state0, F), scratch2, F)
      state0 := addmod(
        0x0fe0af7858e49859e2a54d6f1ad945b1316aa24bfbdd23ae40a6d0cb70c3eab1,
        addmod(addmod(mulmod(scratch0, M00, F), mulmod(scratch1, M10, F), F), mulmod(scratch2, M20, F), F),
        F
      )
      state1 := addmod(
        0x216f6717bbc7dedb08536a2220843f4e2da5f1daa9ebdefde8a5ea7344798d22,
        addmod(addmod(mulmod(scratch0, M01, F), mulmod(scratch1, M11, F), F), mulmod(scratch2, M21, F), F),
        F
      )
      state2 := addmod(
        0x1da55cc900f0d21f4a3e694391918a1b3c23b2ac773c6b3ef88e2e4228325161,
        addmod(addmod(mulmod(scratch0, M02, F), mulmod(scratch1, M12, F), F), mulmod(scratch2, M22, F), F),
        F
      )
      scratch0 := mulmod(state0, state0, F)
      state0 := mulmod(mulmod(scratch0, scratch0, F), state0, F)
      scratch0 := mulmod(state1, state1, F)
      state1 := mulmod(mulmod(scratch0, scratch0, F), state1, F)
      scratch0 := mulmod(state2, state2, F)
      state2 := mulmod(mulmod(scratch0, scratch0, F), state2, F)

      mstore(0x0, addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F))

      return(0, 0x20)
    }
  }
}