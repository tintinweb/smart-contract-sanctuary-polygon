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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ----------------- INTERFACES -----------------

interface ICard {
  function packMint(
    address _to,
    uint256[] memory _types,
    bool _sb
  ) external returns (uint256);
}

// ----------------- CONTRACT -----------------

interface IPack {
  function burn(address _burner, uint256 _id, uint256 _amount) external;
}

contract COEOpenPacks is ReentrancyGuard {
  // ----------------- STRUCTS -----------------

  struct Pack {
    uint256 packId; //id from the pack contract (ilv is 2 i think)
    uint256[] cardIds; // ids from the card contract static no randomness
    bool exists;
  }

  // ----------------- VARIABLES -----------------

  address public cardAddress;
  address public packAddress;

  mapping(uint256 => Pack) public packs;

  // ----------------- EVENTS -----------------

  event PackOpened(
    address indexed _opener,
    uint256 indexed _packId,
    uint256[] _cardIds
  );

  // ----------------- CONSTRUCTOR -----------------

  constructor(address _cardAddress, address _packAddress) {
    roles[OWNER][msg.sender] = true;
    roles[ADMIN][msg.sender] = true;

    cardAddress = _cardAddress;
    packAddress = _packAddress;
  }

  // function that burns a pack and mints the cards
  function openPack(uint256 packId) public nonReentrant {
    require(packs[packId].exists, "Pack does not exist");

    IPack(packAddress).burn(msg.sender, packId, 1);
    Pack memory pack = packs[packId];
    ICard(cardAddress).packMint(msg.sender, pack.cardIds, false);
  }

  // ----------------- GETTERS -----------------

  function getPack(uint256 _packId) public view returns (Pack memory) {
    return packs[_packId];
  }

  // ----------------- SETTERS -----------------

  function setPack(
    uint256 _packId,
    uint256[] memory _cardIds
  ) public onlyRole(ADMIN) {
    packs[_packId] = Pack(_packId, _cardIds, true);
  }

  function setCardAddress(address _cardAddress) public onlyRole(ADMIN) {
    cardAddress = _cardAddress;
  }

  function setPackAddress(address _packAddress) public onlyRole(ADMIN) {
    packAddress = _packAddress;
  }

  // ----------------- PAUSE -----------------

  // ----------------- ACCESS CONTROL -----------------

  mapping(bytes32 => mapping(address => bool)) private roles;
  bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
  bytes32 private constant OWNER = keccak256(abi.encodePacked("OWNER"));

  modifier onlyRole(bytes32 role) {
    require(roles[role][msg.sender], "Not authorized to cards.");
    _;
  }

  function grantRole(bytes32 role, address account) public onlyRole(OWNER) {
    roles[role][account] = true;
  }

  function revokeRole(bytes32 role, address account) public onlyRole(OWNER) {
    roles[role][account] = false;
  }

  function transferOwnershipp(address newOwner) external onlyRole(OWNER) {
    grantRole(OWNER, newOwner);
    grantRole(ADMIN, newOwner);
    revokeRole(OWNER, msg.sender);
    revokeRole(ADMIN, msg.sender);
  }
}