/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.10;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

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
/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

/// @notice Flexible and target agnostic role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/MultiRolesAuthority.sol)
contract MultiRolesAuthority is Auth, Authority {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, bytes4 indexed functionSig, bool enabled);

    event TargetCustomAuthorityUpdated(address indexed target, Authority indexed authority);

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                       CUSTOM TARGET AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => Authority) public getTargetCustomAuthority;

    /*///////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(bytes4 => bool) public isCapabilityPublic;

    mapping(bytes4 => bytes32) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(uint8 role, bytes4 functionSig) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[functionSig]) >> role) & 1 != 0;
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        Authority customAuthority = getTargetCustomAuthority[target];

        if (address(customAuthority) != address(0)) return customAuthority.canCall(user, target, functionSig);

        return
            isCapabilityPublic[functionSig] || bytes32(0) != getUserRoles[user] & getRolesWithCapability[functionSig];
    }

    /*///////////////////////////////////////////////////////////////
               CUSTOM TARGET AUTHORITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setTargetCustomAuthority(address target, Authority customAuthority) public virtual requiresAuth {
        getTargetCustomAuthority[target] = customAuthority;

        emit TargetCustomAuthorityUpdated(target, customAuthority);
    }

    /*///////////////////////////////////////////////////////////////
                  PUBLIC CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(bytes4 functionSig, bool enabled) public virtual requiresAuth {
        isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                      USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                  ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setRoleCapability(
        uint8 role,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, functionSig, enabled);
    }
}

// TODO(These enumerations need mappings to strings to correctly concatenate)
enum Slot {
    Weapon,
    Armor,
    Implant
}

enum Grade {
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary
}

enum Name {
    PlasmaCutter,
    LabCoat,
    PainSuppressor
}

struct LootInfo {
    Slot slot;
    Grade grade;
    Name name;
}

contract Loot is ERC721, MultiRolesAuthority {
    mapping(uint256 => LootInfo) _lootInfo;

    // ID 0 is reserved for "newbie loot"
    uint256 _next_id = 1;

    mapping(address => bool) boards;

    constructor()
        MultiRolesAuthority(msg.sender, Authority(address(0)))
        ERC721("Moloch Rises Loot", "MRL")
    {
        setRoleCapability(0, 0x100af824, true);
        setRoleCapability(0, 0x2affe684, true);
    }

    function addBoard(address boardContract) public requiresAuth {
        boards[boardContract] = true;
    }

    function removeBoard(address boardContract) public requiresAuth {
        boards[boardContract] = false;
    }

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

    function lootInfo(uint256 id) public view returns (LootInfo memory info) {
        info = _lootInfo[id];
    }

    function tokenName(uint256 id) public view returns (string memory) {
        LootInfo memory info = _lootInfo[id];
        string memory grade = "";
        string memory itemName = "";

        // Grade mapping to strings
        if (info.grade == Grade.Common) {
            grade = "Common";
        } else if (info.grade == Grade.Uncommon) {
            grade = "Uncommon";
        } else if (info.grade == Grade.Rare) {
            grade = "Rare";
        } else if (info.grade == Grade.Epic) {
            grade = "Epic";
        } else if (info.grade == Grade.Legendary) {
            grade = "Legendary";
        }

        // Name mapping to strings
        if (info.name == Name.LabCoat) {
            itemName = "Lab Coat";
        } else if (info.name == Name.PlasmaCutter) {
            itemName = "Plasma Cutter";
        } else if (info.name == Name.PainSuppressor) {
            itemName = "Pain Suppressor";
        }

        return string(abi.encodePacked(grade, " ", itemName));
    }

    /* solhint-disable quotes */
    function contractURI() public pure returns (string memory) {
        // TODO(add multisig here in fee_recipient)
        // TODO(update image to correct one in arweave)
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Moloch Rises Loot", "description:": "Loot for playing the Moloch Rises roguelite.", "seller_fee_basis_points": ',
                        toString(250),
                        ', "external_link": "https://molochrises.com/", "image": "ipfs://bafkreihuy7ln4il3ou4ne5gtqnwwuqfb5enbuk5dzqpmcmisinikkdccc4", "fee_recipient": "0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // TODO(Replace loot image with proper item images)
        require(id < _next_id, "loot not yet minted");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenName(id),
                        '", "description": "Loot for fighting moloch.", "image": "ipfs://bafkreihuy7ln4il3ou4ne5gtqnwwuqfb5enbuk5dzqpmcmisinikkdccc4Y"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /* solhint-enable quotes */

    function mint(
        address to,
        Slot slot,
        Grade grade,
        Name name
    ) public virtual {
        require(boards[msg.sender], "Only authz board can call.");
        // Get the next token id
        uint256 tokenId = _next_id;

        // Setup loot lootInfo
        LootInfo storage info = _lootInfo[tokenId];
        info.name = name;
        info.grade = grade;
        info.slot = slot;

        // Increment ID
        _next_id += 1;

        // Mint the NFT
        _safeMint(to, tokenId);
    }
}
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
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
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

contract Avatar is
    MultiRolesAuthority,
    ERC721,
    ERC721TokenReceiver,
    VRFConsumerBase
{
    address public immutable feeRecipient =
        0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5;

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(bytes32 => uint256) private _request_map;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    // TODO(Figure out an elegant way to combine these)
    struct AvatarDetails {
        uint64 hp;
        uint64 dp;
        uint64 ap;
        string armor;
        string weapon;
        string implant;
    }

    struct AvatarSheet {
        bool seeded;
        // Experience counter
        uint64 experience;
        string name;
        // Links to the loot NFT
        uint256 weapon;
        uint256 armor;
        uint256 implant;
        uint256 seed;
    }

    address public loot;
    mapping(address => bool) boards;

    uint256 _next_id = 0;

    // Mapping to get stats of
    mapping(uint256 => AvatarSheet) public sheet;

    // TODO(In an ideal world, the integrated contract addresses would all be precomputed using CREATE3 and not editable)
    constructor(
        address VrfCoordinator,
        address linkToken,
        bytes32 VrfkeyHash,
        uint256 VrfFee
    )
        VRFConsumerBase(VrfCoordinator, linkToken)
        MultiRolesAuthority(msg.sender, Authority(address(0)))
        ERC721("Moloch Rises Avatar", "MRA")
    {
        keyHash = VrfkeyHash;
        fee = VrfFee;
        setRoleCapability(0, 0x87d0040c, true);
        setRoleCapability(0, 0x100af824, true);
        setRoleCapability(0, 0x2affe684, true);
    }

    function updateLoot(address lootContract) public requiresAuth {
        loot = lootContract;
    }

    function addBoard(address boardContract) public requiresAuth {
        boards[boardContract] = true;
        Loot(loot).setApprovalForAll(boardContract, true);
    }

    function removeBoard(address boardContract) public requiresAuth {
        boards[boardContract] = false;
        Loot(loot).setApprovalForAll(boardContract, true);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        revert("Incorrect function paid");
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        revert("Incorrect function paid");
    }

    // TODO(Factor out to library)
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
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        // Get tokenId from pending request
        uint256 tokenId = _request_map[requestId];
        sheet[tokenId].seed = randomness;
        sheet[tokenId].seeded = true;
    }

    /* solhint-disable quotes */
    function contractURI() public pure returns (string memory) {
        // TODO(add multisig here in fee_recipient)
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Moloch Rises Avatars", "description:": "Avatars for playing the Moloch Rises roguelite", "seller_fee_basis_points": ',
                        toString(250),
                        ', "external_link": "https://molochrises.com/", "image": "ipfs://bafkreihlv2vnrwoirui6ox2rxwavk7ufpuukh5q2iyn37ofiiemv67kzwa", "fee_recipient": "0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // TODO(There are almost certainly gas optimizations to be had here)
        require(id < _next_id, "Avatar not yet minted");
        AvatarSheet memory avatarSheet = sheet[id];
        AvatarDetails memory avatarDetails = AvatarDetails(
            5,
            1,
            1,
            "Worn Lab Coat",
            "Used Plasma Cutter",
            "No Implant"
        );

        // Account for experience
        if (avatarSheet.experience >= 100) {
            uint64 buff = avatarSheet.experience / 100;
            avatarDetails.hp += buff;
            avatarDetails.ap += buff;
            avatarDetails.dp += buff;
        }

        // Get Item info

        Loot iLoot = Loot(address(loot));

        if (avatarSheet.armor > 0) {
            avatarDetails.armor = iLoot.tokenName(avatarSheet.armor);
            avatarDetails.dp += uint64(iLoot.lootInfo(avatarSheet.armor).grade);
        }
        if (avatarSheet.weapon > 0) {
            avatarDetails.weapon = iLoot.tokenName(avatarSheet.weapon);
            avatarDetails.ap += uint64(
                iLoot.lootInfo(avatarSheet.weapon).grade
            );
        }
        if (avatarSheet.implant > 0) {
            avatarDetails.implant = iLoot.tokenName(avatarSheet.implant);
            avatarDetails.hp += uint64(
                iLoot.lootInfo(avatarSheet.implant).grade
            );
        }

        // Construct JSON

        string memory encoded;
        {
            // Construct JSON
            bytes memory encoded1;
            {
                encoded1 = abi.encodePacked(
                    '{"name": "',
                    avatarSheet.name,
                    '", "description": "An avatar ready to fight moloch.", "image": "ipfs://bafkreib4ftqeobfmdy7kvurixv55m7nqtvwj3o2hw3clsyo3hjpxwo3sda", "attributes": [{"trait_type": "HP", "value": ',
                    toString(avatarDetails.hp),
                    '}, {"trait_type": "AP", "value": ',
                    toString(avatarDetails.ap),
                    "}, "
                );
            }
            bytes memory encoded2;
            {
                encoded2 = abi.encodePacked(
                    '{"trait_type": "DP", "value": ',
                    toString(avatarDetails.dp),
                    '},{"trait_type": "Armor", "value": "',
                    avatarDetails.armor,
                    '"}, {"trait_type": "Weapon", "value": "',
                    avatarDetails.weapon,
                    '"}, {"trait_type": "Implant", "value": "',
                    avatarDetails.implant,
                    '"}, {"trait_type": "Experience", "value": ',
                    toString(avatarSheet.experience),
                    "}]}"
                );
            }

            encoded = string(abi.encodePacked(encoded1, encoded2));
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(encoded))
                )
            );
    }

    /* solhint-enable quotes */

    function mint(address to, string memory newAvatarName)
        public
        payable
        virtual
    {
        // TODO(change back to 5 matic)
        require(msg.value == 0.001 ether, "Minting requires 5 Matic");
        bool sent = payable(feeRecipient).send(msg.value);
        require(sent, "Failed to send Matic");

        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with link"
        );

        // TODO(Does the character need a VRF seed)

        // Get the next token id
        uint256 tokenId = _next_id;

        // Set Avatar data
        AvatarSheet storage avatarSheet = sheet[tokenId];
        avatarSheet.name = newAvatarName;

        // Increment ID
        _next_id += 1;

        // Mint the NFT
        _safeMint(to, tokenId);

        bytes32 requestId = requestRandomness(keyHash, fee);
        _request_map[requestId] = tokenId;
    }

    // Will equip or re-equip a loot item to an avatar slot
    function equip(uint256 lootId, uint256 avatarId) public {
        require(lootId != 0, "Can't equip default gear");

        // Get info about loot item
        Loot iLoot = Loot(loot);

        // Equipper must be the owner of the item and the avatar
        require(msg.sender == iLoot.ownerOf(lootId), "Must own item to equip.");
        require(
            msg.sender == this.ownerOf(avatarId),
            "Must own avatar to equip."
        );

        // Copy loot info to local memory
        LootInfo memory info = iLoot.lootInfo(lootId);

        uint256 unequipped = 0;
        if (info.slot == Slot.Weapon) {
            unequipped = sheet[avatarId].weapon;
            sheet[avatarId].weapon = lootId;
        } else if (info.slot == Slot.Armor) {
            unequipped = sheet[avatarId].armor;
            sheet[avatarId].armor = lootId;
        } else if (info.slot == Slot.Implant) {
            unequipped = sheet[avatarId].implant;
            sheet[avatarId].implant = lootId;
        }

        // Transfer equipped item from sender to avatar
        iLoot.safeTransferFrom(msg.sender, address(this), lootId);

        // If the character already had equipment
        if (unequipped != 0) {
            // Send the unequipped item to the sender
            iLoot.safeTransferFrom(address(this), msg.sender, unequipped);
        }
    }

    function unequip(
        uint256 lootId,
        uint256 avatarId,
        address to
    ) public {
        require(lootId != 0, "Can't unequip default gear");
        require(
            (msg.sender == this.ownerOf(avatarId) || boards[msg.sender]),
            "Must own avatar to unequip."
        );

        // Get info about loot item
        Loot iLoot = Loot(loot);

        // Copy loot info to local memory
        LootInfo memory info = iLoot.lootInfo(lootId);

        uint256 unequipped = 0;
        if (info.slot == Slot.Weapon) {
            unequipped = sheet[avatarId].weapon;
            require(unequipped != 0, "Item not equipped");
            sheet[avatarId].weapon = 0;
        } else if (info.slot == Slot.Armor) {
            unequipped = sheet[avatarId].armor;
            require(unequipped != 0, "Item not equipped");
            sheet[avatarId].armor = 0;
        } else if (info.slot == Slot.Implant) {
            unequipped = sheet[avatarId].implant;
            require(unequipped != 0, "Item not equipped");
            sheet[avatarId].implant = 0;
        }

        // If the character already had equipment
        if (unequipped != 0) {
            // Send the unequipped item to the sender
            iLoot.safeTransferFrom(address(this), to, unequipped);
        }
    }

    function increaseExperience(uint64 amount, uint256 avatarId) public {
        require(avatarId < _next_id, "Avatar not yet minted");
        require(boards[msg.sender], "Only authz board can call.");
        sheet[avatarId].experience += amount;
    }
}


// TODO(Circom verifier inheritance for zkSnark)
contract Board is MultiRolesAuthority {
    address public immutable feeRecipient =
        0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5;

    address avatar;

    address loot;

    struct Game {
        uint256 avatar;
        uint256 seed;
        bool started;
        bool completed;
        bool victory;
        bool resign;
    }

    // 0 is reserved here to indicate player not in a game
    uint64 _nextPlayId = 1;

    mapping(uint256 => uint64) public avatarGame;

    mapping(uint64 => Game) public gameInfo;

    constructor() MultiRolesAuthority(msg.sender, Authority(address(0))) {
        setRoleCapability(0, 0x4417cb58, true);
        setRoleCapability(0, 0x87d0040c, true);
    }

    function updateAvatar(address avatarContract) public requiresAuth {
        avatar = avatarContract;
    }

    function updateLoot(address lootContract) public requiresAuth {
        loot = lootContract;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        revert("Incorrect function paid");
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        revert("Incorrect function paid");
    }

    function start(uint256 avatarId)
        public
        payable
        returns (uint64 playId, Game memory gameInstance)
    {
        require(avatarGame[avatarId] == 0, "Player already in game");

        // Get avatar info
        Avatar IAvatar = Avatar(payable(avatar));

        require(
            msg.sender == IAvatar.ownerOf(avatarId),
            "Must own character to play"
        );

        // Coin operated game
        // TODO(Reset to 1 matic)
        require(msg.value == 0.001 ether, "Playing requires 1 Matic");
        bool sent = payable(feeRecipient).send(msg.value);
        require(sent, "Failed to send Matic");

        playId = _nextPlayId;

        avatarGame[avatarId] = playId;

        // TODO(Add method to avatar to just get seed, for a huge gas savings (6 sload) - out of time)
        (, , , , , , uint256 seed) = IAvatar.sheet(avatarId);

        gameInstance = Game(
            avatarId,
            uint256(keccak256(abi.encode(seed, playId))),
            true,
            false,
            false,
            false
        );

        gameInfo[playId] = gameInstance;

        _nextPlayId += 1;
    }

    function nftDamage(
        Avatar IAvatar,
        uint256 avatarId,
        uint256 seed
    ) internal {
        // 10% chance to destroy an item
        if (seed % 9 == 9) {
            // Chose item slot
            uint256 slot;
            slot = seed % 2;
            // TODO(Add method to avatar to just get seed, for a huge gas savings (6 sload) - out of time)
            (
                bool seeded,
                uint64 experience,
                string memory name,
                uint256 weapon,
                uint256 armor,
                uint256 implant,
                uint256 seed
            ) = IAvatar.sheet(avatarId);
            uint256 item;
            if (slot == 0) {
                item = weapon;
            } else if (slot == 1) {
                item = weapon;
            } else {
                item = implant;
            }
            if (item != 0) {
                // Loot was damaged beyond repair.
                IAvatar.unequip(item, avatarId, feeRecipient);
            }
        }
    }

    function accrueExperience(
        Avatar IAvatar,
        uint256 avatarId,
        uint256 seed
    ) internal {
        uint256 max = 400;
        // TODO(Add method to avatar to just get seed, for a huge gas savings (6 sload) - out of time)
        (
            bool seeded,
            uint64 experience,
            string memory name,
            uint256 weapon,
            uint256 armor,
            uint256 implant,
            uint256 seed
        ) = IAvatar.sheet(avatarId);
        if (experience < max) {
            max = max - uint256(experience);
            IAvatar.increaseExperience(uint64(seed % max), avatarId);
        }
    }

    function lootDrop(
        Avatar IAvatar,
        uint256 avatarId,
        uint256 seed
    ) internal {
        (, uint64 experience, , , , , ) = IAvatar.sheet(avatarId);
        uint256 slot;
        slot = seed % 2;
        if (experience < 350) {
            // Odds of loot drop
            // Common 15%
            // Uncommon 10%
            // Rare 5%
            // Epic 2%
            // Legendary 1%
            uint256 roll = seed % 99;
            if (roll >= 67 && roll < 82) {
                // drop common
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Common,
                    Name(slot)
                );
            } else if (roll >= 82 && roll < 92) {
                // drop uncommon
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Uncommon,
                    Name(slot)
                );
            } else if (roll >= 92 && roll < 97) {
                // drop rare
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Rare,
                    Name(slot)
                );
            } else if (roll >= 97 && roll < 99) {
                // drop epic
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Epic,
                    Name(slot)
                );
            } else if (roll == 99) {
                // drop legendary
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Legendary,
                    Name(slot)
                );
            }
        }
    }

    function complete(uint64 gameId, Game memory gameData) public {
        require(gameId < _nextPlayId, "Game not found");

        // Get avatar info
        Avatar IAvatar = Avatar(payable(avatar));
        Game storage gameState = gameInfo[gameId];

        require(
            msg.sender == IAvatar.ownerOf(gameState.avatar),
            "Must own character to finish game"
        );

        // Update game state
        bool lost = true;
        if (gameData.resign) {
            // End without validating playthrough
            avatarGame[gameData.avatar] = 0;
            gameState.resign = true;
        } else {
            // TODO(Verify zkSNARK before just accepting this)
            lost = gameData.victory;
        }
        if (lost) {
            gameState.victory = false;
            nftDamage(IAvatar, gameState.avatar, gameState.seed);
        } else {
            accrueExperience(IAvatar, gameState.avatar, gameState.seed);
            lootDrop(IAvatar, gameState.avatar, gameState.seed);
            gameState.victory = true;
        }
        gameState.completed = true;
    }
}