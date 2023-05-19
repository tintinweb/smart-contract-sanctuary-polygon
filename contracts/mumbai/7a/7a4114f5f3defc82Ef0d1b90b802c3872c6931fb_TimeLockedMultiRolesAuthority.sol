// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnershipTransferred(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
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

    function transferOwnership(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Auth, Authority} from "../Auth.sol";

/// @notice Flexible and target agnostic role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/authorities/MultiRolesAuthority.sol)
contract MultiRolesAuthority is Auth, Authority {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, bytes4 indexed functionSig, bool enabled);

    event TargetCustomAuthorityUpdated(address indexed target, Authority indexed authority);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*//////////////////////////////////////////////////////////////
                     CUSTOM TARGET AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => Authority) public getTargetCustomAuthority;

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
                  PUBLIC CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(bytes4 functionSig, bool enabled) public virtual requiresAuth {
        isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

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
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

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
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

pragma solidity >=0.7.0 <0.9.0;

import "./utility/SafeMath.sol";
import "./interfaces/IBancorFormula.sol";

contract BancorFormula is IBancorFormula {
    using SafeMath for uint256;

    string public version = "0.3";

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    // /**
    //     Auto-generated via 'PrintIntScalingFactors.py'
    // */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    // /**
    //     Auto-generated via 'PrintLn2ScalingFactors.py'
    // */
    uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    // /**
    //     Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    // */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    // /**
    //     Auto-generated via 'PrintFunctionConstructor.py'
    // */
    uint256[128] private maxExpArray;

    constructor() {
        //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
        //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
        //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
        //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
        //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
        //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
        //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
        //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
        //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
        //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
        //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
        //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
        //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
        //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
        //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
        //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
        //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
        //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
        //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
        //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
        //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
        //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
        //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
        //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
        //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
        //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
        //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
        //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
        //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
        //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
        //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
        //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    /**
     * @dev given a token supply, connector balance, weight and a deposit amount (in the connector token),
     *       calculates the return for a given conversion (in the main token)
     *
     *       Formula:
     *       Return = supply * ((1 + depositAmount / connectorBalance) ^ (connectorWeight / 1000000) - 1)
     *
     *       @param supply              token total supply
     *       @param connectorBalance    total connector balance
     *       @param connectorWeight     connector weight, represented in ppm, 1-1000000
     *       @param depositAmount       deposit amount, in connector token
     *
     *       @return purchase return amount
     */
    function calculatePurchaseReturn(
        uint256 supply,
        uint256 connectorBalance,
        uint32 connectorWeight,
        uint256 depositAmount
    ) public view override returns (uint256) {
        // validate input
        require(supply > 0 && connectorBalance > 0 && connectorWeight > 0 && connectorWeight <= MAX_WEIGHT);

        // special case for 0 deposit amount
        if (depositAmount == 0) {
            return 0;
        }

        // special case if the weight = 100%
        if (connectorWeight == MAX_WEIGHT) {
            return supply.mul(depositAmount) / connectorBalance;
        }

        uint256 result;
        uint8 precision;
        uint256 baseN = depositAmount.add(connectorBalance);
        (result, precision) = power(baseN, connectorBalance, connectorWeight, MAX_WEIGHT);
        uint256 temp = supply.mul(result) >> precision;
        return temp - supply;
    }

    /**
     * @dev given a token supply, connector balance, weight and a sell amount (in the main token),
     *       calculates the return for a given conversion (in the connector token)
     *
     *       Formula:
     *       Return = connectorBalance * (1 - (1 - _sellAmount / supply) ^ (1 / (connectorWeight / 1000000)))
     *
     *       @param supply              token total supply
     *       @param connectorBalance    total connector
     *       @param connectorWeight     constant connector Weight, represented in ppm, 1-1000000
     *       @param _sellAmount          sell amount, in the token itself
     *
     *       @return sale return amount
     */
    function calculateSaleReturn(uint256 supply, uint256 connectorBalance, uint32 connectorWeight, uint256 _sellAmount)
        public
        view
        override
        returns (uint256)
    {
        // validate input
        require(
            supply > 0 && connectorBalance > 0 && connectorWeight > 0 && connectorWeight <= MAX_WEIGHT
                && _sellAmount <= supply
        );

        // special case for 0 sell amount
        if (_sellAmount == 0) {
            return 0;
        }

        // special case for selling the entire supply
        if (_sellAmount == supply) {
            return connectorBalance;
        }

        // special case if the weight = 100%
        if (connectorWeight == MAX_WEIGHT) {
            return connectorBalance.mul(_sellAmount) / supply;
        }

        uint256 result;
        uint8 precision;
        uint256 baseD = supply - _sellAmount;
        (result, precision) = power(supply, baseD, MAX_WEIGHT, connectorWeight);
        uint256 temp1 = connectorBalance.mul(result);
        uint256 temp2 = connectorBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given two connector balances/weights and a sell amount (in the first connector token),
     *       calculates the return for a conversion from the first connector token to the second connector token (in the second connector token)
     *
     *       Formula:
     *       Return = _toConnectorBalance * (1 - (_fromConnectorBalance / (_fromConnectorBalance + _amount)) ^ (_fromConnectorWeight / _toConnectorWeight))
     *
     *       @param _fromConnectorBalance    input connector balance
     *       @param _fromConnectorWeight     input connector weight, represented in ppm, 1-1000000
     *       @param _toConnectorBalance      output connector balance
     *       @param _toConnectorWeight       output connector weight, represented in ppm, 1-1000000
     *       @param _amount                  input connector amount
     *
     *       @return second connector amount
     */
    function calculateCrossConnectorReturn(
        uint256 _fromConnectorBalance,
        uint32 _fromConnectorWeight,
        uint256 _toConnectorBalance,
        uint32 _toConnectorWeight,
        uint256 _amount
    ) public view override returns (uint256) {
        // validate input
        require(
            _fromConnectorBalance > 0 && _fromConnectorWeight > 0 && _fromConnectorWeight <= MAX_WEIGHT
                && _toConnectorBalance > 0 && _toConnectorWeight > 0 && _toConnectorWeight <= MAX_WEIGHT
        );

        // special case for equal weights
        if (_fromConnectorWeight == _toConnectorWeight) {
            return _toConnectorBalance.mul(_amount) / _fromConnectorBalance.add(_amount);
        }

        uint256 result;
        uint8 precision;
        uint256 baseN = _fromConnectorBalance.add(_amount);
        (result, precision) = power(baseN, _fromConnectorBalance, _fromConnectorWeight, _toConnectorWeight);
        uint256 temp1 = _toConnectorBalance.mul(result);
        uint256 temp2 = _toConnectorBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * General Description:
     *           Determine a value of precision.
     *           Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
     *           Return the result along with the precision used.
     *
     *       Detailed Description:
     *           Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
     *           The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
     *           The larger "precision" is, the more accurately this value represents the real value.
     *           However, the larger "precision" is, the more bits are required in order to store this value.
     *           And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
     *           This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     *           Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
     *           This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
     *           This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
     */
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        } else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
     * Compute log(x / FIXED_1) * FIXED_1.
     *       This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
     */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

    /**
     * Compute the largest integer smaller than or equal to the binary logarithm of the input.
     */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
     * The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
     *       - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
     *       - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
     */
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x) {
                lo = mid;
            } else {
                hi = mid;
            }
        }

        if (maxExpArray[hi] >= _x) {
            return hi;
        }
        if (maxExpArray[lo] >= _x) {
            return lo;
        }

        require(false);
        return 0;
    }

    /**
     * This function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
     *       It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
     *       It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
     *       The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
     *       The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
     * Return log(x / FIXED_1) * FIXED_1
     *       Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
     *       Auto-generated via 'PrintFunctionOptimalLog.py'
     *       Detailed description:
     *       - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     *       - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     *       - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     *       - The natural logarithm of the input is calculated by summing up the intermediate results above
     *       - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
            res += 0x40000000000000000000000000000000;
            x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
        } // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
            res += 0x20000000000000000000000000000000;
            x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;
        } // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
            res += 0x10000000000000000000000000000000;
            x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;
        } // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
            res += 0x08000000000000000000000000000000;
            x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;
        } // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
            res += 0x04000000000000000000000000000000;
            x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;
        } // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
            res += 0x02000000000000000000000000000000;
            x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;
        } // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {
            res += 0x01000000000000000000000000000000;
            x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;
        } // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {
            res += 0x00800000000000000000000000000000;
            x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;
        } // add 1 / 2^8

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000;
        z = z * w / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000;
        z = z * w / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000;
        z = z * w / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000;
        z = z * w / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000;
        z = z * w / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000;
        z = z * w / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000;
        z = z * w / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
     * Return e ^ (x / FIXED_1) * FIXED_1
     *       Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     *       Auto-generated via 'PrintFunctionOptimalExp.py'
     *       Detailed description:
     *       - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     *       - The exponentiation of each binary exponent is given (pre-calculated)
     *       - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     *       - The exponentiation of the input is calculated by multiplying the intermediate results above
     *       - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = z * y / FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0) {
            res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776;
        } // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0) {
            res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4;
        } // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0) {
            res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f;
        } // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0) {
            res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9;
        } // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0) {
            res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea;
        } // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0) {
            res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d;
        } // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0) {
            res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11;
        } // multiply by e^2^(+3)

        return res;
    }
}

pragma solidity >=0.8.0;

/// @title Bancor Formula interface
interface IBancorFormula {
    function calculatePurchaseReturn(
        uint256 supply,
        uint256 connectorBalance,
        uint32 connectorWeight,
        uint256 depositAmount
    ) external view returns (uint256);
    function calculateSaleReturn(uint256 supply, uint256 connectorBalance, uint32 connectorWeight, uint256 sellAmount)
        external
        view
        returns (uint256);
    function calculateCrossConnectorReturn(
        uint256 fromConnectorBalance,
        uint32 fromConnectorWeight,
        uint256 toConnectorBalance,
        uint32 toConnectorWeight,
        uint256 amount
    ) external view returns (uint256);
}

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 * @dev Copy paste from old openzeppelin PR [TEMPORARY SOLUTION]
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// Copied from https://github.com/ensdomains/buffer/blob/master/contracts/Buffer.sol

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for appending to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library Buffer {
    /**
     * @dev Represents a mutable buffer. Buffers have a current value (buf) and
     *      a capacity. The capacity may be longer than the current value, in
     *      which case it can be extended without the need to allocate more memory.
     */
    struct buffer {
        bytes buf;
        uint256 capacity;
    }

    /**
     * @dev Initializes a buffer with an initial capacity.
     * @param buf The buffer to initialize.
     * @param capacity The number of bytes of space to allocate the buffer.
     * @return The buffer, for chaining.
     */
    function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            let fpm := add(32, add(ptr, capacity))
            if lt(fpm, ptr) { revert(0, 0) }
            mstore(0x40, fpm)
        }
        return buf;
    }

    /**
     * @dev Initializes a new buffer from an existing bytes object.
     *      Changes to the buffer may mutate the original value.
     * @param b The bytes object to initialize the buffer with.
     * @return A new buffer.
     */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint256 capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    /**
     * @dev Sets buffer length to 0.
     * @param buf The buffer to truncate.
     * @return The original buffer, for chaining..
     */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
     * @dev Appends len bytes of a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function append(buffer memory buf, bytes memory data, uint256 len) internal pure returns (buffer memory) {
        require(len <= data.length);

        uint256 off = buf.buf.length;
        uint256 newCapacity = off + len;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        uint256 dest;
        uint256 src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(newCapacity, buflen) { mstore(bufptr, newCapacity) }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint256 mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
     * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return append(buf, data, data.length);
    }

    /**
     * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
        uint256 off = buf.buf.length;
        uint256 offPlusOne = off + 1;
        if (off >= buf.capacity) {
            resize(buf, offPlusOne * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if gt(offPlusOne, mload(bufptr)) { mstore(bufptr, offPlusOne) }
        }

        return buf;
    }

    /**
     * @dev Appends len bytes of bytes32 to a buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to write (left-aligned).
     * @return The original buffer, for chaining.
     */
    function append(buffer memory buf, bytes32 data, uint256 len) private pure returns (buffer memory) {
        uint256 off = buf.buf.length;
        uint256 newCapacity = len + off;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        unchecked {
            uint256 mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + newCapacity
                let dest := add(bufptr, newCapacity)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(newCapacity, mload(bufptr)) { mstore(bufptr, newCapacity) }
            }
        }
        return buf;
    }

    /**
     * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chhaining.
     */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return append(buf, bytes32(data), 20);
    }

    /**
     * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return append(buf, data, 32);
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to write (right-aligned).
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint256 data, uint256 len) internal pure returns (buffer memory) {
        uint256 off = buf.buf.length;
        uint256 newCapacity = len + off;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        uint256 mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + newCapacity
            let dest := add(bufptr, newCapacity)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(newCapacity, mload(bufptr)) { mstore(bufptr, newCapacity) }
        }
        return buf;
    }
}

/**
 * @dev A library for populating CBOR encoded payload in Solidity.
 *
 * https://datatracker.ietf.org/doc/html/rfc7049
 *
 * The library offers various write* and start* methods to encode values of different types.
 * The resulted buffer can be obtained with data() method.
 * Encoding of primitive types is staightforward, whereas encoding of sequences can result
 * in an invalid CBOR if start/write/end flow is violated.
 * For the purpose of gas saving, the library does not verify start/write/end flow internally,
 * except for nested start/end pairs.
 */

library CBOR {
    using Buffer for Buffer.buffer;

    struct CBORBuffer {
        Buffer.buffer buf;
        uint256 depth;
    }

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    uint8 private constant TAG_TYPE_BIGNUM = 2;
    uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

    uint8 private constant CBOR_FALSE = 20;
    uint8 private constant CBOR_TRUE = 21;
    uint8 private constant CBOR_NULL = 22;
    uint8 private constant CBOR_UNDEFINED = 23;

    function create(uint256 capacity) internal pure returns (CBORBuffer memory cbor) {
        Buffer.init(cbor.buf, capacity);
        cbor.depth = 0;
        return cbor;
    }

    function data(CBORBuffer memory buf) internal pure returns (bytes memory) {
        require(buf.depth == 0, "Invalid CBOR");
        return buf.buf.buf;
    }

    function writeUInt256(CBORBuffer memory buf, uint256 value) internal pure {
        buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
        writeBytes(buf, abi.encode(value));
    }

    function writeInt256(CBORBuffer memory buf, int256 value) internal pure {
        if (value < 0) {
            buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
            writeBytes(buf, abi.encode(uint256(-1 - value)));
        } else {
            writeUInt256(buf, uint256(value));
        }
    }

    function writeUInt64(CBORBuffer memory buf, uint64 value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_INT, value);
    }

    function writeInt64(CBORBuffer memory buf, int64 value) internal pure {
        if (value >= 0) {
            writeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
        } else {
            writeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(-1 - value));
        }
    }

    function writeBytes(CBORBuffer memory buf, bytes memory value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
        buf.buf.append(value);
    }

    function writeString(CBORBuffer memory buf, string memory value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
        buf.buf.append(bytes(value));
    }

    function writeBool(CBORBuffer memory buf, bool value) internal pure {
        writeContentFree(buf, value ? CBOR_TRUE : CBOR_FALSE);
    }

    function writeNull(CBORBuffer memory buf) internal pure {
        writeContentFree(buf, CBOR_NULL);
    }

    function writeUndefined(CBORBuffer memory buf) internal pure {
        writeContentFree(buf, CBOR_UNDEFINED);
    }

    function startArray(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
        buf.depth += 1;
    }

    function startFixedArray(CBORBuffer memory buf, uint64 length) internal pure {
        writeDefiniteLengthType(buf, MAJOR_TYPE_ARRAY, length);
    }

    function startMap(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
        buf.depth += 1;
    }

    function startFixedMap(CBORBuffer memory buf, uint64 length) internal pure {
        writeDefiniteLengthType(buf, MAJOR_TYPE_MAP, length);
    }

    function endSequence(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
        buf.depth -= 1;
    }

    function writeKVString(CBORBuffer memory buf, string memory key, string memory value) internal pure {
        writeString(buf, key);
        writeString(buf, value);
    }

    function writeKVBytes(CBORBuffer memory buf, string memory key, bytes memory value) internal pure {
        writeString(buf, key);
        writeBytes(buf, value);
    }

    function writeKVUInt256(CBORBuffer memory buf, string memory key, uint256 value) internal pure {
        writeString(buf, key);
        writeUInt256(buf, value);
    }

    function writeKVInt256(CBORBuffer memory buf, string memory key, int256 value) internal pure {
        writeString(buf, key);
        writeInt256(buf, value);
    }

    function writeKVUInt64(CBORBuffer memory buf, string memory key, uint64 value) internal pure {
        writeString(buf, key);
        writeUInt64(buf, value);
    }

    function writeKVInt64(CBORBuffer memory buf, string memory key, int64 value) internal pure {
        writeString(buf, key);
        writeInt64(buf, value);
    }

    function writeKVBool(CBORBuffer memory buf, string memory key, bool value) internal pure {
        writeString(buf, key);
        writeBool(buf, value);
    }

    function writeKVNull(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        writeNull(buf);
    }

    function writeKVUndefined(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        writeUndefined(buf);
    }

    function writeKVMap(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        startMap(buf);
    }

    function writeKVArray(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        startArray(buf);
    }

    function writeFixedNumeric(CBORBuffer memory buf, uint8 major, uint64 value) private pure {
        if (value <= 23) {
            buf.buf.appendUint8(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.buf.appendUint8(uint8((major << 5) | 24));
            buf.buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.buf.appendUint8(uint8((major << 5) | 25));
            buf.buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.buf.appendUint8(uint8((major << 5) | 26));
            buf.buf.appendInt(value, 4);
        } else {
            buf.buf.appendUint8(uint8((major << 5) | 27));
            buf.buf.appendInt(value, 8);
        }
    }

    function writeIndefiniteLengthType(CBORBuffer memory buf, uint8 major) private pure {
        buf.buf.appendUint8(uint8((major << 5) | 31));
    }

    function writeDefiniteLengthType(CBORBuffer memory buf, uint8 major, uint64 length) private pure {
        writeFixedNumeric(buf, major, length);
    }

    function writeContentFree(CBORBuffer memory buf, uint8 value) private pure {
        buf.buf.appendUint8(uint8((MAJOR_TYPE_CONTENT_FREE << 5) | value));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import { CBOR, Buffer } from "src/chainlink-functions/CBOR.sol";

/**
 * @title Library for Chainlink Functions
 */
library Functions {
    uint256 internal constant DEFAULT_BUFFER_SIZE = 256;

    using CBOR for Buffer.buffer;

    enum Location {
        Inline,
        Remote
    }

    enum CodeLanguage { JavaScript }
    // In future version we may add other languages

    struct Request {
        Location codeLocation;
        Location secretsLocation;
        CodeLanguage language;
        string source; // Source code for Location.Inline or url for Location.Remote
        bytes secrets; // Encrypted secrets blob for Location.Inline or url for Location.Remote
        string[] args;
    }

    error EmptySource();
    error EmptyUrl();
    error EmptySecrets();
    error EmptyArgs();
    error NoInlineSecrets();

    /**
     * @notice Encodes a Request to CBOR encoded bytes
     * @param self The request to encode
     * @return CBOR encoded bytes
     */
    function encodeCBOR(Request memory self) internal pure returns (bytes memory) {
        CBOR.CBORBuffer memory buffer;
        Buffer.init(buffer.buf, DEFAULT_BUFFER_SIZE);

        CBOR.writeString(buffer, "codeLocation");
        CBOR.writeUInt256(buffer, uint256(self.codeLocation));

        CBOR.writeString(buffer, "language");
        CBOR.writeUInt256(buffer, uint256(self.language));

        CBOR.writeString(buffer, "source");
        CBOR.writeString(buffer, self.source);

        if (self.args.length > 0) {
            CBOR.writeString(buffer, "args");
            CBOR.startArray(buffer);
            for (uint256 i = 0; i < self.args.length; i++) {
                CBOR.writeString(buffer, self.args[i]);
            }
            CBOR.endSequence(buffer);
        }

        if (self.secrets.length > 0) {
            if (self.secretsLocation == Location.Inline) {
                revert NoInlineSecrets();
            }
            CBOR.writeString(buffer, "secretsLocation");
            CBOR.writeUInt256(buffer, uint256(self.secretsLocation));
            CBOR.writeString(buffer, "secrets");
            CBOR.writeBytes(buffer, self.secrets);
        }

        return buffer.buf.buf;
    }

    /**
     * @notice Initializes a Chainlink Functions Request
     * @dev Sets the codeLocation and code on the request
     * @param self The uninitialized request
     * @param location The user provided source code location
     * @param language The programming language of the user code
     * @param source The user provided source code or a url
     */
    function initializeRequest(Request memory self, Location location, CodeLanguage language, string memory source)
        internal
        pure
    {
        if (bytes(source).length == 0) revert EmptySource();

        self.codeLocation = location;
        self.language = language;
        self.source = source;
    }

    /**
     * @notice Initializes a Chainlink Functions Request
     * @dev Simplified version of initializeRequest for PoC
     * @param self The uninitialized request
     * @param javaScriptSource The user provided JS code (must not be empty)
     */
    function initializeRequestForInlineJavaScript(Request memory self, string memory javaScriptSource) internal pure {
        initializeRequest(self, Location.Inline, CodeLanguage.JavaScript, javaScriptSource);
    }

    /**
     * @notice Adds Remote user encrypted secrets to a Request
     * @param self The initialized request
     * @param encryptedSecretsURLs Encrypted comma-separated string of URLs pointing to off-chain secrets
     */
    function addRemoteSecrets(Request memory self, bytes memory encryptedSecretsURLs) internal pure {
        if (encryptedSecretsURLs.length == 0) revert EmptySecrets();

        self.secretsLocation = Location.Remote;
        self.secrets = encryptedSecretsURLs;
    }

    /**
     * @notice Adds args for the user run function
     * @param self The initialized request
     * @param args The array of args (must not be empty)
     */
    function addArgs(Request memory self, string[] memory args) internal pure {
        if (args.length == 0) revert EmptyArgs();

        self.args = args;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import { Functions } from "./Functions.sol";
import { IFunctionsClient } from "./interfaces/IFunctionsClient.sol";
import { IFunctionsOracle } from "./interfaces/IFunctionsOracle.sol";

/**
 * @title The Chainlink Functions client contract
 * @notice Contract writers can inherit this contract in order to create Chainlink Functions requests
 */
abstract contract FunctionsClient is IFunctionsClient {
    IFunctionsOracle internal s_oracle;
    mapping(bytes32 => address) internal s_pendingRequests;

    event RequestSent(bytes32 indexed id);
    event RequestFulfilled(bytes32 indexed id);

    error SenderIsNotRegistry();
    error RequestIsAlreadyPending();
    error RequestIsNotPending();

    constructor(address oracle) {
        setOracle(oracle);
    }

    /**
     * @inheritdoc IFunctionsClient
     */
    function getDONPublicKey() external view override returns (bytes memory) {
        return s_oracle.getDONPublicKey();
    }

    /**
     * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
     * @param req The initialized Functions.Request
     * @param subscriptionId The subscription ID
     * @param gasLimit gas limit for the fulfillment callback
     * @return billedCost Cost in Juels (1e18) of LINK
     */
    function estimateCost(Functions.Request memory req, uint64 subscriptionId, uint32 gasLimit, uint256 gasPrice)
        public
        view
        returns (uint96)
    {
        return s_oracle.estimateCost(subscriptionId, Functions.encodeCBOR(req), gasLimit, gasPrice);
    }

    /**
     * @notice Sends a Chainlink Functions request to the stored oracle address
     * @param req The initialized Functions.Request
     * @param subscriptionId The subscription ID
     * @param gasLimit gas limit for the fulfillment callback
     * @return requestId The generated request ID
     */
    function sendRequest(Functions.Request memory req, uint64 subscriptionId, uint32 gasLimit)
        internal
        returns (bytes32)
    {
        bytes32 requestId = s_oracle.sendRequest(subscriptionId, Functions.encodeCBOR(req), gasLimit);
        s_pendingRequests[requestId] = s_oracle.getRegistry();
        emit RequestSent(requestId);
        return requestId;
    }

    /**
     * @notice User defined function to handle a response
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual;

    /**
     * @inheritdoc IFunctionsClient
     */
    function handleOracleFulfillment(bytes32 requestId, bytes memory response, bytes memory err)
        external
        override
        recordChainlinkFulfillment(requestId)
    {
        fulfillRequest(requestId, response, err);
    }

    /**
     * @notice Sets the stored Oracle address
     * @param oracle The address of Functions Oracle contract
     */
    function setOracle(address oracle) internal {
        s_oracle = IFunctionsOracle(oracle);
    }

    /**
     * @notice Gets the stored address of the oracle contract
     * @return The address of the oracle contract
     */
    function getChainlinkOracleAddress() internal view returns (address) {
        return address(s_oracle);
    }

    /**
     * @notice Allows for a request which was created on another contract to be fulfilled
     * on this contract
     * @param oracleAddress The address of the oracle contract that will fulfill the request
     * @param requestId The request ID used for the response
     */
    function addExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
        s_pendingRequests[requestId] = oracleAddress;
    }

    /**
     * @dev Reverts if the sender is not the oracle that serviced the request.
     * Emits RequestFulfilled event.
     * @param requestId The request ID for fulfillment
     */
    modifier recordChainlinkFulfillment(bytes32 requestId) {
        if (msg.sender != s_pendingRequests[requestId]) {
            revert SenderIsNotRegistry();
        }
        delete s_pendingRequests[requestId];
        emit RequestFulfilled(requestId);
        _;
    }

    /**
     * @dev Reverts if the request is already pending
     * @param requestId The request ID for fulfillment
     */
    modifier notPendingRequest(bytes32 requestId) {
        if (s_pendingRequests[requestId] != address(0)) {
            revert RequestIsAlreadyPending();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Chainlink Functions billing subscription registry interface.
 */
interface IFunctionsBillingRegistry {
    struct RequestBilling {
        // a unique subscription ID allocated by billing system,
        uint64 subscriptionId;
        // the client contract that initiated the request to the DON
        // to use the subscription it must be added as a consumer on the subscription
        address client;
        // customer specified gas limit for the fulfillment callback
        uint32 gasLimit;
        // the expected gas price used to execute the transaction
        uint256 gasPrice;
    }

    enum FulfillResult {
        USER_SUCCESS,
        USER_ERROR,
        INVALID_REQUEST_ID
    }

    /**
     * @notice Get configuration relevant for making requests
     * @return uint32 global max for request gas limit
     * @return address[] list of registered DONs
     */
    function getRequestConfig() external view returns (uint32, address[] memory);

    /**
     * @notice Determine the charged fee that will be paid to the Registry owner
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param billing The request's billing configuration
     * @return fee Cost in Juels (1e18) of LINK
     */
    function getRequiredFee(bytes calldata data, RequestBilling memory billing) external view returns (uint96);

    /**
     * @notice Estimate the total cost to make a request: gas re-imbursement, plus DON fee, plus Registry fee
     * @param gasLimit Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param gasPrice The request's billing configuration
     * @param donFee Fee charged by the DON that is paid to Oracle Node
     * @param registryFee Fee charged by the DON that is paid to Oracle Node
     * @return costEstimate Cost in Juels (1e18) of LINK
     */
    function estimateCost(uint32 gasLimit, uint256 gasPrice, uint96 donFee, uint96 registryFee)
        external
        view
        returns (uint96);

    /**
     * @notice Initiate the billing process for an Functions request
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param billing Billing configuration for the request
     * @return requestId - A unique identifier of the request. Can be used to match a request to a response in fulfillRequest.
     * @dev Only callable by a node that has been approved on the Registry
     */
    function startBilling(bytes calldata data, RequestBilling calldata billing) external returns (bytes32);

    /**
     * @notice Finalize billing process for an Functions request by sending a callback to the Client contract and then charging the subscription
     * @param requestId identifier for the request that was generated by the Registry in the beginBilling commitment
     * @param response response data from DON consensus
     * @param err error from DON consensus
     * @param transmitter the Oracle who sent the report
     * @param signers the Oracles who had a part in generating the report
     * @param signerCount the number of signers on the report
     * @param reportValidationGas the amount of gas used for the report validation. Cost is split by all fulfillments on the report.
     * @param initialGas the initial amount of gas that should be used as a baseline to charge the single fulfillment for execution cost
     * @return result fulfillment result
     * @dev Only callable by a node that has been approved on the Registry
     * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
     */
    function fulfillAndBill(
        bytes32 requestId,
        bytes calldata response,
        bytes calldata err,
        address transmitter,
        address[31] memory signers, // 31 comes from OCR2Abstract.sol's maxNumOracles constant
        uint8 signerCount,
        uint256 reportValidationGas,
        uint256 initialGas
    ) external returns (FulfillResult);

    /**
     * @notice Gets subscription owner.
     * @param subscriptionId - ID of the subscription
     * @return owner - owner of the subscription.
     */
    function getSubscriptionOwner(uint64 subscriptionId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Chainlink Functions client interface.
 */
interface IFunctionsClient {
    /**
     * @notice Returns the DON's secp256k1 public key used to encrypt secrets
     * @dev All Oracles nodes have the corresponding private key
     * needed to decrypt the secrets encrypted with the public key
     * @return publicKey DON's public key
     */
    function getDONPublicKey() external view returns (bytes memory);

    /**
     * @notice Chainlink Functions response handler called by the designated transmitter node in an OCR round.
     * @param requestId The requestId returned by FunctionsClient.sendRequest().
     * @param response Aggregated response from the user code.
     * @param err Aggregated error either from the user code or from the execution pipeline.
     * Either response or error parameter will be set, but never both.
     */
    function handleOracleFulfillment(bytes32 requestId, bytes memory response, bytes memory err) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import { IFunctionsBillingRegistry } from "./IFunctionsBillingRegistry.sol";

/**
 * @title Chainlink Functions oracle interface.
 */
interface IFunctionsOracle {
    /**
     * @notice Gets the stored billing registry address
     * @return registryAddress The address of Chainlink Functions billing registry contract
     */
    function getRegistry() external view returns (address);

    /**
     * @notice Sets the stored billing registry address
     * @param registryAddress The new address of Chainlink Functions billing registry contract
     */
    function setRegistry(address registryAddress) external;

    /**
     * @notice Returns the DON's secp256k1 public key that is used to encrypt secrets
     * @dev All nodes on the DON have the corresponding private key
     * needed to decrypt the secrets encrypted with the public key
     * @return publicKey the DON's public key
     */
    function getDONPublicKey() external view returns (bytes memory);

    /**
     * @notice Sets DON's secp256k1 public key used to encrypt secrets
     * @dev Used to rotate the key
     * @param donPublicKey The new public key
     */
    function setDONPublicKey(bytes calldata donPublicKey) external;

    /**
     * @notice Sets a per-node secp256k1 public key used to encrypt secrets for that node
     * @dev Callable only by contract owner and DON members
     * @param node node's address
     * @param publicKey node's public key
     */
    function setNodePublicKey(address node, bytes calldata publicKey) external;

    /**
     * @notice Deletes node's public key
     * @dev Callable only by contract owner or the node itself
     * @param node node's address
     */
    function deleteNodePublicKey(address node) external;

    /**
     * @notice Return two arrays of equal size containing DON members' addresses and their corresponding
     * public keys (or empty byte arrays if per-node key is not defined)
     */
    function getAllNodePublicKeys() external view returns (address[] memory, bytes[] memory);

    /**
     * @notice Determine the fee charged by the DON that will be split between signing Node Operators for servicing the request
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param billing The request's billing configuration
     * @return fee Cost in Juels (1e18) of LINK
     */
    function getRequiredFee(bytes calldata data, IFunctionsBillingRegistry.RequestBilling calldata billing)
        external
        view
        returns (uint96);

    /**
     * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
     * @param subscriptionId A unique subscription ID allocated by billing system,
     * a client can make requests from different contracts referencing the same subscription
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param gasLimit Gas limit for the fulfillment callback
     * @return billedCost Cost in Juels (1e18) of LINK
     */
    function estimateCost(uint64 subscriptionId, bytes calldata data, uint32 gasLimit, uint256 gasPrice)
        external
        view
        returns (uint96);

    /**
     * @notice Sends a request (encoded as data) using the provided subscriptionId
     * @param subscriptionId A unique subscription ID allocated by billing system,
     * a client can make requests from different contracts referencing the same subscription
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param gasLimit Gas limit for the fulfillment callback
     * @return requestId A unique request identifier (unique per DON)
     */
    function sendRequest(uint64 subscriptionId, bytes calldata data, uint32 gasLimit) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

///@dev Curve 3Pool interface
///@dev TokenIds: 0 = DAI, 1 = USDC, 2 = USDT
interface ICurve3Pool {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 amount, uint256[3] calldata min_amounts) external;

    function remove_liquidity_one_coin(uint256 token_amount, int128 token_id, uint256 min_amount) external;

    ///@notice Swaps `sold_token_id` token for `bought_token_id`
    function exchange(int128 sold_token_id, int128 bought_token_id, uint256 amount, uint256 min_output_amount)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /**
     * @dev Mints `amount` tokens to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     */
    function mint(address to, uint256 amount) external returns (bool);

    /**
     * @dev Burns `amount` tokens from `from`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     */
    function burn(address from, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

///@dev Oracle interface
interface IOracle {
    /// @return uint256 USD value of the vault multiplied by 10 ** 18
    function getUsdValue() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { TokenType } from "src/structs/TokenType.sol";
import { PositionReceipt } from "src/structs/PositionReceipt.sol";

/// @title IStrategy
/// @author Daoism Systems
/// @notice IStrategy is an interface that various strategies must implement
/// @custom:security-contact [email protected]
interface IStrategy {
    /// @notice Invests token `amounts`
    /// @param amounts The amounts of tokens to invest
    /// @param msgSender The sender of the transaction
    /// @dev Should transfer received LP tokens/NFT to the vault
    /// @return receipt The position receipt
    function invest(address msgSender, uint256[] calldata amounts) external returns (PositionReceipt memory receipt);

    /// @notice Claims the rewards and transfers it to the vault
    /// @param msgSender The sender of the transaction
    function claimRewards(address msgSender) external;

    /// @notice Withdraws token `amounts` and transfers it to the vault
    /// @param msgSender The sender of the transaction
    /// @param amounts The amounts of tokens to withdraw
    function withdrawInvestment(address msgSender, uint256[] calldata amounts) external;

    /// @dev Rescues tokens that are stuck in this strategy
    /// @param token address of the token to rescue
    /// @param typ type of the token to rescue
    function rescueTokens(address token, uint256 tokenId, TokenType typ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { Strategy } from "src/structs/Strategy.sol";

/// @title IStrategyModule Interface
/// @author Daoism Systems
/// @notice This interface defines the required functions for the Strategy Module,
///         which is responsible for managing and interacting with different strategies.
/// @custom:security-contact [email protected]
interface IStrategyModule {
    /// @notice Emitted when a new strategy is enabled.
    /// @param strategyAddress The address of the enabled strategy contract.
    event StrategyEnabled(address strategyAddress);

    /// @notice Emitted when a strategy is disabled.
    /// @param strategyAddress The address of the disabled strategy contract.
    event StrategyDisabled(address strategyAddress);

    /// @notice Emitted when a deposit is executed for a specific strategy.
    /// @param strategyAddress The address of the strategy contract that received the deposit.
    /// @param tokens An array of token addresses that were deposited.
    /// @param amounts An array of token amounts corresponding to each deposited token.
    event ExecutedStrategyDeposit(address strategyAddress, address[] tokens, uint256[] amounts);

    /// @notice Enables a strategy by providing the necessary information and the strategy's address.
    /// @param strategy A struct containing the details of the strategy to be enabled.
    /// @param strategyAddress The address of the strategy contract.
    function enableStrategy(Strategy calldata strategy, address strategyAddress) external;

    /// @notice Disables a strategy by providing its address.
    /// @param strategyAddress The address of the strategy contract to be disabled.
    function disableStrategy(address strategyAddress) external;

    /// @notice Executes a deposit to the specified strategy.
    /// @dev It approves the necessary tokens from the Vault to the strategy
    /// @param strategyAddress The address of the strategy contract to deposit into.
    /// @param amounts An array of token amounts to be deposited.
    function executeStrategyDeposit(address strategyAddress, uint256[] calldata amounts) external;

    /// @notice Claims rewards from the specified strategy.
    /// @param strategyAddress The address of the strategy contract to claim rewards from.
    function claimRewardsFromStrategy(address strategyAddress) external;

    /// @notice Executes a withdrawal from the specified strategy.
    /// @dev @dev It approves the necessary LP tokens from the Vault to the strategy
    /// @param strategyAddress The address of the strategy contract to withdraw from.
    /// @param amounts An array of token amounts to be withdrawn.
    function executeStrategyWithdrawal(address strategyAddress, uint256[] calldata amounts) external;

    /// @notice Retrieves the details of the specified strategy.
    /// @param strategy The address of the strategy contract to retrieve the details of.
    /// @return A Strategy struct containing the details of the specified strategy.
    function getStrategy(address strategy) external view returns (Strategy memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { MultiRolesAuthority } from "lib/solmate/src/auth/authorities/MultiRolesAuthority.sol";

/// @title IVault Interface
/// @author Daoism Systems
/// @notice This interface defines the basic functions for enabling and disabling modules for a vault
/// @custom:security-contact [email protected]
interface IVault {
    function authority() external view returns (MultiRolesAuthority);

    /// @title Result
    /// @notice A struct that represents the outcome of a smart contract call.
    /// @dev This struct is used to store and return the success status and return data of a smart contract call.
    struct Result {
        bool success; // Indicates whether the call was successful or not.
        bytes returnData; // Contains the return data of the call, if successful.
    }

    /// @notice Executes multiple smart contract calls in a single transaction.
    /// @dev This function takes an array of target addresses, calldata, and ether values,
    ///      and executes calls to the respective targets with the provided calldata and values.
    ///      It returns an array of Result structs containing the success status and return data of each call.
    /// @param targets An array of target addresses to call.
    /// @param calldatas An array of calldata to be used for each target call.
    /// @param values An array of ether values to be sent with each target call.
    /// @return An array of Result structs containing the success status and return data of each executed call.
    function multicall(address[] memory targets, bytes[] memory calldatas, uint256[] memory values)
        external
        returns (Result[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

________                                          ______________________ 
__  ___/___  ____________________________ ___________  __ \__    |_  __ \
_____ \_  / / /__  __ \_  ___/  _ \_  __ `__ \  _ \_  / / /_  /| |  / / /
____/ // /_/ /__  /_/ /  /   /  __/  / / / / /  __/  /_/ /_  ___ / /_/ / 
/____/ \__,_/ _  .___//_/    \___//_/ /_/ /_/\___//_____/ /_/  |_\____/  
              /_/                                                        
             _      __    _  _____  ___   _     ____  _     
            | |_/  / /\  | |  | |  / / \ | |_/ | |_  | |\ | 
            |_| \ /_/--\ |_|  |_|  \_\_/ |_| \ |_|__ |_| \| */

pragma solidity >=0.7.0 <0.9.0;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { Unauthorized } from "src/utils/Errors.sol";

/// @title KAI Token
/// @author Daoism Systems
/// @notice KAIToken
/// @custom:security-contact [email protected]
contract KAIToken is ERC20 {
    address internal _curve; // SupplyCurve address

    modifier restricted() {
        // maybe a shitty name, should be changed
        if (msg.sender != _curve) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address curve) ERC20("SupremeDAO KAI Currency", "KAI", 18) {
        _curve = curve;
    }

    function mint(address to, uint256 amount) external restricted returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external restricted returns (bool) {
        _burn(from, amount);
        return true;
    }

    function getCurve() external view returns (address) {
        return _curve;
    }
}

pragma solidity >=0.7.0 <0.9.0;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint256 public constant initialSupply = 20_000_000 * 1 ether;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 18) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract ERC20BrokenApprove {
    function approve(address, uint256) public virtual returns (bool) {
        return false;
    }
}

contract ERC20BrokenApprove2 {
    function approve(address, uint256) public virtual returns (bool) {
        require(false, "revert approve");
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { MultiRolesAuthority } from "lib/solmate/src/auth/authorities/MultiRolesAuthority.sol";
import { IOracle } from "src/interfaces/IOracle.sol";
import { IERC20 } from "src/interfaces/IERC20.sol";

contract MockOracle is IOracle {
    IERC20 public dai;
    address public vault;

    constructor(IERC20 DAIMock, address vaultAddress) {
        dai = DAIMock;
        vault = vaultAddress;
    }

    function getUsdValue() external view returns (uint256) {
        return dai.balanceOf(vault);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { PositionReceipt } from "src/structs/PositionReceipt.sol";
import { TokenType } from "src/structs/TokenType.sol";
import { ERC20Mock } from "src/mocks/ERC20Mock.sol";
import { IStrategy } from "src/interfaces/IStrategy.sol";
import { ICurve3Pool } from "src/interfaces/ICurve3Pool.sol";
import { StrategyBase } from "src/StrategyBase.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";

contract MockStrategy is StrategyBase {
    event RewardsClaimed();

    address token;

    constructor(address strategyModuleAddress, address vaultAddress)
        StrategyBase(strategyModuleAddress, vaultAddress)
    {
        token = address(new ERC20Mock("mock tkn","mck"));
    }

    function _invest(address, uint256[] calldata) internal pure override returns (PositionReceipt memory receipt) {
        return PositionReceipt({ tokenType: TokenType.ERC20, token: address(0), amount: 0, tokenId: 0 });
    }

    function _claimRewards(address) internal override {
        emit RewardsClaimed();
    }

    function _withdrawInvestment(address, uint256[] calldata) internal override { }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { IStrategyModule } from "src/interfaces/IStrategyModule.sol";
import { IVault } from "src/interfaces/IVault.sol";
import { IERC20 } from "src/interfaces/IERC20.sol";
import { IStrategy } from "src/interfaces/IStrategy.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { ERC721 } from "lib/solmate/src/tokens/ERC721.sol";
import { TokenType } from "src/structs/TokenType.sol";
import { Strategy } from "src/structs/Strategy.sol";
import { PositionReceipt } from "src/structs/PositionReceipt.sol";
import "src/utils/Errors.sol";

/// @title StrategyModule
/// @author Daoism Systems
/// @notice StrategyModule
/// @custom:security-contact [email protected]
contract StrategyModule is IStrategyModule {
    using SafeTransferLib for ERC20;

    IVault private immutable _vault;

    mapping(address strategyAddress => Strategy strategy) internal _strategies;

    constructor(IVault vault) {
        _vault = vault;
    }

    modifier onlyAuthorised() {
        if (!_vault.authority().canCall(msg.sender, address(this), msg.sig)) {
            revert Unauthorized();
        }
        _;
    }

    /// @inheritdoc IStrategyModule
    function enableStrategy(Strategy calldata strategy, address strategyAddress) external onlyAuthorised {
        _validateStrategy(strategy);
        _strategies[strategyAddress] = strategy;
        // TODO: decide what we want to emit
        emit StrategyEnabled(strategyAddress);
    }

    /// @inheritdoc IStrategyModule
    function disableStrategy(address strategyAddress) external onlyAuthorised {
        _strategies[strategyAddress].enabled = false;

        uint256[] memory amounts = _strategies[strategyAddress].invested;
        _strategyWithdrawal(strategyAddress, amounts);

        emit StrategyDisabled(strategyAddress);
    }

    /// @inheritdoc IStrategyModule
    function executeStrategyDeposit(address strategyAddress, uint256[] calldata amounts) external {
        Strategy memory strategy = _strategies[strategyAddress];

        if (!strategy.enabled) {
            revert StrategyNotEnabled();
        }

        // Validates amounts approve ERC20 tokens from the Vault to the strategy
        for (uint256 i = 0; i < strategy.tokens.length; ++i) {
            if (amounts[i] + strategy.invested[i] > strategy.allowed[i]) {
                revert InvalidAmount(amounts[i]);
            }

            if (amounts[i] != 0) {
                strategy.invested[i] += amounts[i];
            }
        }

        _approveERC20FromTheVault(strategyAddress, strategy.tokens, amounts);

        emit ExecutedStrategyDeposit(strategyAddress, strategy.tokens, amounts);

        PositionReceipt memory positionReceipt =
            IStrategy(strategyAddress).invest({ msgSender: msg.sender, amounts: amounts });

        // Update just the amount, add previous amount and amount from new investment together
        positionReceipt.amount = positionReceipt.amount + strategy.position.amount;

        strategy.position = positionReceipt;

        // Update strategy
        _strategies[strategyAddress] = strategy;
    }

    /// @inheritdoc IStrategyModule
    function claimRewardsFromStrategy(address strategyAddress) external {
        PositionReceipt memory position = _strategies[strategyAddress].position;

        if (position.tokenType == TokenType.ERC721) {
            return _uniswapClaimRewards(strategyAddress, position.token, position.tokenId);
        }
        // TODO: ERC20/ERC1155 cases, extend logic

        // Todo figure out and test this case
        IStrategy(strategyAddress).claimRewards(msg.sender);
    }

    /// @inheritdoc IStrategyModule
    function executeStrategyWithdrawal(address strategyAddress, uint256[] calldata amounts) external {
        _strategyWithdrawal(strategyAddress, amounts);
    }

    /// @inheritdoc IStrategyModule
    function getStrategy(address strategy) external view returns (Strategy memory) {
        return _strategies[strategy];
    }

    function _validateStrategy(Strategy calldata strategy) internal view {
        // Unchecked for gas optimisation
        unchecked {
            if (strategy.tokens.length == 0) {
                revert InvalidInputParameters();
            }

            // Array lengths need to match
            if ((strategy.tokens.length * 2) != (strategy.allowed.length + strategy.invested.length)) {
                revert InvalidInputParameters();
            }

            // We must not have zero address or duplicates
            for (uint256 i = 0; i < strategy.tokens.length; ++i) {
                if (!_isContract(strategy.tokens[i])) {
                    revert InvalidToken();
                }

                // Invested should be zero
                if (strategy.invested[i] != 0) {
                    revert InvalidInputParameters();
                }

                for (uint256 j = i + 1; j < strategy.tokens.length; ++j) {
                    if (strategy.tokens[i] == strategy.tokens[j]) {
                        revert DuplicateTokens();
                    }
                }
            }

            // Make sure that deposit contract is a contract
            if (!_isContract(strategy.depositContract)) {
                revert InvalidInputParameters();
            }
        }
    }

    function _strategyWithdrawal(address strategyAddress, uint256[] memory amounts) internal {
        PositionReceipt memory position = _strategies[strategyAddress].position;

        if (position.tokenType == TokenType.ERC721) {
            _approveERC721FromTheVault({
                token: position.token,
                strategyAddress: strategyAddress,
                tokenId: position.tokenId
            });
            return IStrategy(strategyAddress).withdrawInvestment({ msgSender: msg.sender, amounts: amounts });
        }

        if (position.tokenType == TokenType.ERC20) {
            if (position.amount == 0) {
                // TODO: should we trigger `withdrawInvestment` anyways without trying to transfer erc20?
                return;
            }

            address[] memory tokens = new address[](1);
            tokens[0] = position.token;

            _approveERC20FromTheVault({ strategyAddress: strategyAddress, tokens: tokens, amounts: amounts });

            return IStrategy(strategyAddress).withdrawInvestment({ msgSender: msg.sender, amounts: amounts });
        }

        // TODO: handle ERC1155 case
    }

    function _uniswapClaimRewards(address strategyAddress, address token, uint256 tokenId) internal {
        _approveERC721FromTheVault({ token: token, strategyAddress: strategyAddress, tokenId: tokenId });

        IStrategy(strategyAddress).claimRewards(msg.sender);

        // Make sure that we get back the NFT
        require(ERC721(token).ownerOf(tokenId) == address(_vault));
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // Approves ERC20 tokens from the Vault to the Strategy address
    function _approveERC20FromTheVault(address strategyAddress, address[] memory tokens, uint256[] memory amounts)
        private
    {
        bytes[] memory calldatas = new bytes[](tokens.length);
        uint256[] memory values = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length;) {
            calldatas[i] = abi.encodeWithSelector(IERC20.approve.selector, strategyAddress, amounts[i]);
            values[i] = 0;

            unchecked {
                i++;
            }
        }

        IVault.Result[] memory results = _vault.multicall({ targets: tokens, calldatas: calldatas, values: values });

        for (uint256 i = 0; i < results.length;) {
            _validateApprovalCall(results[i]);

            unchecked {
                ++i;
            }
        }
    }

    // Approves ERC721 token from the Vault to the Strategy address
    function _approveERC721FromTheVault(address token, address strategyAddress, uint256 tokenId) private {
        bytes[] memory calldatas = new bytes[](1);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);

        targets[0] = token;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(ERC721.approve.selector, strategyAddress, tokenId);

        IVault.Result[] memory results = _vault.multicall({ targets: targets, calldatas: calldatas, values: values });

        for (uint256 i = 0; i < results.length;) {
            _validateApprovalCall(results[i]);

            unchecked {
                ++i;
            }
        }
    }

    // Validates that the approval is successful
    function _validateApprovalCall(IVault.Result memory result) private pure {
        // Check if the call reverted
        if (!result.success) {
            revert ApprovalFailed();
        }

        // If it returned any call data, make sure that it returned `true`
        if (result.returnData.length > 0) {
            if (!abi.decode(result.returnData, (bool))) {
                revert ApprovalFailed();
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { MultiRolesAuthority } from "lib/solmate/src/auth/authorities/MultiRolesAuthority.sol";
import { IOracle } from "src/interfaces/IOracle.sol";
import { FunctionsClient, Functions } from "src/chainlink-functions/FunctionsClient.sol";
import { IVault } from "src/interfaces/IVault.sol";
import { Unauthorized } from "src/utils/Errors.sol";

/// @title Oracle
/// @author Daoism Systems
/// @custom:security-contact [email protected]
contract Oracle is IOracle, FunctionsClient {
    using Functions for Functions.Request;

    IVault public immutable vault;

    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    string public code =
        "if(!secrets.zerionApiKey)throw Error('API_KEY');async function fetchBalanceFromZerion(e){let t={method:'GET',headers:{accept:'application/json',authorization:`Basic ${secrets.zerionApiKey}`},url:`https://api.zerion.io/v1/wallets/${e}/portfolio/?currency=usd`},a=await Functions.makeHttpRequest(t);if(a.error)throw Error(a.response.data.message);let o=1e18*a.data.data.attributes.total.positions;return o}const address=args[0],balance=await fetchBalanceFromZerion(address);return Functions.encodeUint256(balance);";
    string[] public args = ["0x5F9a7EA6A79Ef04F103bfe7BD45dA65476a5155C"];
    uint64 public subscriptionId = 979;
    uint32 public gasLimit = 100_000;

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

    constructor(address vaultAddress, address oracle) FunctionsClient(oracle) {
        vault = IVault(vaultAddress);
    }

    modifier onlyAuthorised() {
        if (!IVault(vault).authority().canCall(msg.sender, address(this), msg.sig)) {
            revert Unauthorized();
        }
        _;
    }

    function getUsdValue() external view returns (uint256) {
        return abi.decode(latestResponse, (uint256));
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        latestResponse = response;
        latestError = err;
        emit OCRResponse(requestId, response, err);
    }

    function executeRequest(bytes calldata secrets) public onlyAuthorised returns (bytes32) {
        Functions.Request memory req;
        req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, code);
        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }
        if (args.length > 0) req.addArgs(args);

        bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
        latestRequestId = assignedReqID;
        return assignedReqID;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { ContractIsPaused } from "./utils/Errors.sol";

/// @title Pausable
/// @author Daoism Systems
/// @notice Pausable
/// @custom:security-contact [email protected]
contract Pausable {
    event Paused();
    event Unpaused();

    bool internal _paused;

    modifier whenNotPaused() {
        if (_paused) {
            revert ContractIsPaused();
        }
        _;
    }

    function _pause() internal {
        _paused = true;
        emit Paused();
    }

    function _unpause() internal {
        _paused = false;
        emit Unpaused();
    }

    /// @notice Retuns the paused state
    /// @return bool indicating if the contract is paused
    function getPaused() external view returns (bool) {
        return _paused;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { PositionReceipt } from "src/structs/PositionReceipt.sol";
import { TokenType } from "src/structs/TokenType.sol";
import { IStrategy } from "src/interfaces/IStrategy.sol";
import { ICurve3Pool } from "src/interfaces/ICurve3Pool.sol";
import { StrategyBase } from "src/StrategyBase.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";

/// @custom:security-contact [email protected]
contract Curve3PoolDAI is StrategyBase {
    using SafeTransferLib for ERC20;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant CURVE_3POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    ERC20 public constant LP_TOKEN_3CRV = ERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    constructor(address strategyModuleAddress, address vaultAddress)
        StrategyBase(strategyModuleAddress, vaultAddress)
    { }

    function _invest(address, uint256[] calldata amounts) internal override returns (PositionReceipt memory receipt) {
        // Order of tokens for 3pool is [DAI, USDC, USDT];
        uint256[3] memory values = [amounts[0], amounts[1], amounts[2]];

        // Deposit DAI amount to 3pool
        if (values[0] != 0) {
            ERC20(DAI).safeTransferFrom(vault, address(this), amounts[0]);
            ERC20(DAI).safeApprove(CURVE_3POOL, amounts[0]);
        }

        if (values[1] != 0) {
            ERC20(USDC).safeTransferFrom(vault, address(this), amounts[1]);
            ERC20(USDC).safeApprove(CURVE_3POOL, amounts[1]);
        }

        if (values[2] != 0) {
            ERC20(USDT).safeTransferFrom(vault, address(this), amounts[2]);
            ERC20(USDT).safeApprove(CURVE_3POOL, 0);
            ERC20(USDT).safeApprove(CURVE_3POOL, amounts[2]);
        }

        // TODO: min amount shouldn't be 0
        // For example strategy could calculate and set slippage to 5% or whatever
        ICurve3Pool(CURVE_3POOL).add_liquidity(values, 0);

        uint256 lpTokenBalance = LP_TOKEN_3CRV.balanceOf(address(this));

        // Transfer LP tokens received back to vault
        LP_TOKEN_3CRV.safeTransfer(address(vault), lpTokenBalance);

        return PositionReceipt({
            tokenType: TokenType.ERC20,
            token: address(LP_TOKEN_3CRV),
            amount: lpTokenBalance,
            tokenId: 0
        });
    }

    function _claimRewards(address) internal override {
        // any logic for claiming extra rewards rewards
    }

    function _withdrawInvestment(address, uint256[] calldata amounts) internal override {
        ERC20(LP_TOKEN_3CRV).safeTransferFrom(vault, address(this), amounts[0]);

        // Order of tokens for 3pool is [DAI, USDC, USDT];
        // uint256[3] memory values = [amount, 0, 0];

        // TODO: min amount shouldn't be 0
        // For example strategy could calculate and set slippage to 5% or whatever
        ICurve3Pool(CURVE_3POOL).remove_liquidity_one_coin(amounts[0], 0, 0);

        // Transfer DAI back to vault
        ERC20(DAI).safeTransfer(vault, ERC20(DAI).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { PositionReceipt } from "src/structs/PositionReceipt.sol";
import { TokenType } from "src/structs/TokenType.sol";
import { IStrategy } from "src/interfaces/IStrategy.sol";
import { ICurve3Pool } from "src/interfaces/ICurve3Pool.sol";
import { StrategyBase } from "src/StrategyBase.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { INonfungiblePositionManager } from "src/uniswap-v3/INonfungiblePositionManager.sol";

/// @custom:security-contact [email protected]
contract UniswapV3DaiUsdc is StrategyBase {
    using SafeTransferLib for ERC20;

    event FeesCollected(address token0, uint256 amount0, address token1, uint256 amount1);
    event Invested(address token0, uint256 amount0, address token1, uint256 amount1);

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint24 public constant poolFee = 100;

    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    uint256 nftTokenId;
    uint128 positionLiquidity;

    constructor(address strategyModuleAddress, address vaultAddress)
        StrategyBase(strategyModuleAddress, vaultAddress)
    { }

    function _invest(address, uint256[] calldata amounts) internal override returns (PositionReceipt memory receipt) {
        // Transfer DAI and USDC from the Vault to strategy
        ERC20(DAI).safeTransferFrom(vault, address(this), amounts[0]);
        ERC20(USDC).safeTransferFrom(vault, address(this), amounts[1]);

        // Approve DAI and USDC to Uniswap
        ERC20(DAI).safeApprove(address(nonfungiblePositionManager), amounts[0]);
        ERC20(USDC).safeApprove(address(nonfungiblePositionManager), amounts[1]);

        (uint256 tokenId, uint128 liquidity, uint256 daiAmountInvested, uint256 usdcAmountInvested) =
        nonfungiblePositionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: DAI,
                token1: USDC,
                fee: poolFee,
                tickLower: MIN_TICK,
                tickUpper: MAX_TICK,
                amount0Desired: amounts[0],
                amount1Desired: amounts[1],
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this), // TODO: we can transfer tokens directly to Vault, replaces line #73
                deadline: block.timestamp // TODO adapt this and slippage
             })
        );

        // Refund extra to the vault
        if (daiAmountInvested < amounts[0]) {
            ERC20(DAI).safeTransfer(msg.sender, amounts[0] - daiAmountInvested);
        }

        if (usdcAmountInvested < amounts[1]) {
            ERC20(USDC).safeTransfer(msg.sender, amounts[1] - usdcAmountInvested);
        }

        nftTokenId = tokenId;
        positionLiquidity = liquidity;

        emit Invested(address(DAI), daiAmountInvested, address(USDC), usdcAmountInvested);

        nonfungiblePositionManager.safeTransferFrom(address(this), vault, tokenId);

        return PositionReceipt({
            tokenType: TokenType.ERC721,
            token: address(nonfungiblePositionManager),
            amount: 0,
            tokenId: tokenId
        });
    }

    function _claimRewards(address) internal override {
        // Transfer NFT from the Vault so that we can claim the reward
        nonfungiblePositionManager.safeTransferFrom(address(vault), address(this), nftTokenId);

        _collectFeesToVault();

        // Transfer NFT back to vault after claiming the reward
        nonfungiblePositionManager.safeTransferFrom(address(this), address(vault), nftTokenId);
    }

    function _collectFeesToVault() internal {
        // set amount0Max and amount1Max to uint256.max to collect all fees

        (uint256 daiAMount, uint256 usdcAmount) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: nftTokenId,
                recipient: address(vault), // Send funds directly to Vault
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        emit FeesCollected(address(DAI), daiAMount, address(USDC), usdcAmount);
    }

    function _withdrawInvestment(address, uint256[] calldata amounts) internal override {
        // Remove liquidity is a 3 step process in Uniswap V3

        // 1. decrease liquidity
        // 2. collect tokens
        // 3. burn the nft
        (uint256 daiamt, uint256 usdcamt) = nonfungiblePositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: nftTokenId,
                liquidity: positionLiquidity,
                amount0Min: 0, // TODO price slippage
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        _collectFeesToVault();

        nonfungiblePositionManager.burn(nftTokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { IStrategy } from "src/interfaces/IStrategy.sol";
import { TokenType } from "src/structs/TokenType.sol";
import { ERC721, ERC721TokenReceiver } from "lib/solmate/src/tokens/ERC721.sol";
import { ERC1155TokenReceiver } from "lib/solmate/src/tokens/ERC1155.sol";
import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { ERC1155 } from "lib/solmate/src/tokens/ERC1155.sol";
import { InvalidAddress, Unauthorized } from "src/utils/Errors.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { PositionReceipt } from "src/structs/PositionReceipt.sol";

/// @title StrategyBase
/// @author Daoism Systems
/// @notice StrategyBase contract that is supposed to be extended by various strategies
/// @custom:security-contact [email protected]
abstract contract StrategyBase is IStrategy, ERC721TokenReceiver, ERC1155TokenReceiver {
    using SafeTransferLib for ERC20;

    address public immutable strategyModule;
    address public immutable vault;

    constructor(address strategyModuleAddress, address vaultAddress) {
        if (strategyModuleAddress == address(0) || vaultAddress == address(0)) {
            revert InvalidAddress();
        }
        strategyModule = strategyModuleAddress;
        vault = vaultAddress;
    }

    modifier onlyStrategyModule() {
        if (msg.sender != strategyModule) {
            revert Unauthorized();
        }
        _;
    }

    /// @inheritdoc IStrategy
    function invest(address msgSender, uint256[] calldata amounts)
        external
        onlyStrategyModule
        returns (PositionReceipt memory receipt)
    {
        return _invest(msgSender, amounts);
    }

    /// @inheritdoc IStrategy
    function claimRewards(address msgSender) external onlyStrategyModule {
        _claimRewards(msgSender);
    }

    /// @inheritdoc IStrategy
    function withdrawInvestment(address msgSender, uint256[] calldata amounts) external onlyStrategyModule {
        _withdrawInvestment(msgSender, amounts);
    }

    /// @inheritdoc IStrategy
    function rescueTokens(address token, uint256 tokenId, TokenType typ) external {
        if (typ == TokenType.ERC20) {
            return ERC20(token).safeTransfer(vault, ERC20(token).balanceOf(address(this)));
        }

        if (typ == TokenType.ERC721) {
            return ERC721(token).safeTransferFrom(address(this), vault, tokenId);
        }

        if (typ == TokenType.ERC1155) {
            return ERC1155(token).safeTransferFrom(
                address(this), vault, tokenId, ERC1155(token).balanceOf(address(this), tokenId), ""
            );
        }
    }

    /// @notice Invests token `amounts`
    /// @param amounts The amounts of tokens to invest
    /// @param msgSender The sender of the transaction
    /// @dev MUST transfer received LP tokens/NFT to the vault
    ///      MUST return the correct receipt
    /// @return receipt The position receipt
    function _invest(address msgSender, uint256[] calldata amounts)
        internal
        virtual
        returns (PositionReceipt memory receipt);

    /// @notice Withdraws token `amounts` and transfers it to the Vault
    /// @param msgSender The sender of the transaction
    /// @param amounts The amounts of tokens to withdraw
    function _withdrawInvestment(address msgSender, uint256[] calldata amounts) internal virtual;

    /// @notice Claims the rewards and transfers it to the Vault
    /// @param msgSender The sender of the transaction
    function _claimRewards(address msgSender) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { TokenType } from "src/structs/TokenType.sol";

// Represents a receipt for a LP position or an investment.
struct PositionReceipt {
    TokenType tokenType; // Specifies the type of token involved in the position or investment.
    address token; // Stores the address of the token.
    uint256 amount; // Specifies the amount of the token involved in the position or investment.
    uint256 tokenId; // Stores the token ID, in case of ERC721/ERC1155 tokens.
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { PositionReceipt } from "src/structs/PositionReceipt.sol";

struct Strategy {
    address depositContract; // External protocol deposit contract that the strategy will use.
    address[] tokens; // Array of tokens that the strategy will use.
    uint256[] allowed; // Array of allowed amounts of tokens.
    uint256[] invested; // Array of invested amounts of tokens.
    bool enabled; // Specifies whether the strategy is currently enabled.
    bool ignorePositinReceipt; // Specifies whether the Vault is ignoring the PositionReceipt.
    PositionReceipt position; // Struct representing the position or investment involved in the strategy.
    bytes data; // Used to store additional data relevant to the strategy.
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

________                                          ______________________ 
__  ___/___  ____________________________ ___________  __ \__    |_  __ \
_____ \_  / / /__  __ \_  ___/  _ \_  __ `__ \  _ \_  / / /_  /| |  / / /
____/ // /_/ /__  /_/ /  /   /  __/  / / / / /  __/  /_/ /_  ___ / /_/ / 
/____/ \__,_/ _  .___//_/    \___//_/ /_/ /_/\___//_____/ /_/  |_\____/  
              /_/                                                        */

pragma solidity >=0.7.0 <0.9.0;

import { IBancorFormula } from "src/bancor-formula/interfaces/IBancorFormula.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { IERC20 } from "src/interfaces/IERC20.sol";
import { IVault } from "src/interfaces/IVault.sol";
import { Unauthorized, InvalidAddress } from "src/utils/Errors.sol";
import { IOracle } from "src/interfaces/IOracle.sol";

/// @title Supply Curve
/// @author Daoism Systems
/// @custom:security-contact [email protected]

contract SupplyCurve {
    address public immutable vault;
    IOracle public _oracle;

    event ConnectorWeightChanged(uint32 oldConnectorWeight, uint32 newConnectorWeight);
    event SplitRateChanged(uint256 oldSplitRate, uint256 newSplitRate);
    event OracleChanged(address oldOracle, address newOracle);
    event Split(uint256 splitAmount);

    bool internal _initialized;
    IERC20 internal _kai; // TODO: do we need Kai token in separate contract? can kai be this contract?
    IERC20 internal _connector;
    IBancorFormula internal immutable _formula; // TODO: is this supposed to change ever? use immutable?
    uint256 internal _splitRate; // DAO governed
    uint32 internal _connectorWeight; // DAO governed

    constructor(address formula, address vaultAddress) {
        if (vaultAddress == address(0)) {
            revert InvalidAddress();
        }
        _formula = IBancorFormula(formula);
        vault = vaultAddress;
    }

    modifier onlyAuthorised() {
        if (!IVault(vault).authority().canCall(msg.sender, address(this), msg.sig)) {
            revert Unauthorized();
        }
        _;
    }

    function _setOracle(IOracle oracle) private {
        if (address(oracle) == address(0)) {
            revert InvalidAddress();
        }

        emit OracleChanged(address(_oracle), address(oracle));
        _oracle = oracle;
    }

    function setOracle(IOracle oracle) external onlyAuthorised {
        _setOracle(oracle);
    }

    /// @dev Initialize the curve, works only once
    /// @param kai token address
    /// @param connector token address
    /// @param mintAmount amount of tokens to be minted by the curve
    /// @param transferAmount amount of tokens to be minted by the curve
    /// @param splitRate split rate of the curve
    /// @param connectorWeight connector weight of the curve
    function initialize(
        address kai,
        address connector,
        uint256 mintAmount,
        uint256 transferAmount,
        uint256 splitRate,
        uint32 connectorWeight
    ) public {
        if (_initialized) {
            revert();
        }
        _initialized = true;
        _kai = IERC20(kai);
        _connector = IERC20(connector);

        _setConnectorWeight(connectorWeight);
        _setSplitRate(splitRate);

        // mint some number to boost a curve
        _kai.mint({ to: vault, amount: mintAmount });
        // transfer connector tokens to the curve
        _connector.transferFrom({ from: msg.sender, to: address(this), amount: transferAmount });
    }

    /// @dev Enter the curve and mint DAO tokens
    /// @param amount amount of tokens you give to the curve

    /// @notice Enters the system and mints the KAI to the user
    /// @dev This function takes the user's DAI and mints the KAI to the user
    /// @param amount The amount of DAI to be transferred from the usen
    function enter(uint256 amount) external {
        uint256 mintAmount = getMintAmount(amount);
        _kai.mint(msg.sender, mintAmount);
        _connector.transferFrom({ from: msg.sender, to: address(this), amount: amount });
        // suboptimal way to do the split, should be changed
        _split(amount);
    }

    /// @notice Exits the system and transfers the DAI to the user
    /// @dev This function burns the user's KAI and transfers the DAI to the user
    /// @param amount The amount of KAI to be burned and exchanged for connector tokens
    function exit(uint256 amount) external {
        uint256 returnAmount = getReturnAmount(amount);
        _connector.transfer({ to: msg.sender, amount: returnAmount });
        _kai.burn({ from: msg.sender, amount: amount });
    }

    // DAO Governed functions

    /// @notice Sets the weight of the connector in the smart contract
    /// @dev This function can only be called by authorized parties and updates the connector weight state variable
    /// @param newConnectorWeight The new weight of the connector to be set
    function setConnectorWeight(uint32 newConnectorWeight) external onlyAuthorised {
        // TODO: weight validation?
        _setConnectorWeight(newConnectorWeight);
    }

    /// @notice Sets the split rate used in the smart contract
    /// @dev This function can only be called by authorized parties and updates the split rate state variable
    /// @param newSplitRate The new split rate to be set
    function setSplitRate(uint256 newSplitRate) external onlyAuthorised {
        // TODO: newSplitRate validations?
        _setSplitRate(newSplitRate);
    }

    // Internal functions

    function _split(uint256 amount) internal {
        if (_splitRate == 0) {
            return;
        }
        uint256 splitAmount = (_splitRate * amount) / 100;
        _connector.transfer({ to: vault, amount: splitAmount });
        emit Split(splitAmount);
    }

    function _setConnectorWeight(uint32 weight) internal {
        uint32 oldConnectorWeight = _connectorWeight;
        _connectorWeight = weight;
        emit ConnectorWeightChanged(oldConnectorWeight, weight);
    }

    function _setSplitRate(uint256 splitRate) internal {
        uint256 oldSplitRate = _splitRate;
        _splitRate = splitRate;
        emit SplitRateChanged(oldSplitRate, splitRate);
    }

    // Getters

    /// @notice Gets the split rate used in the smart contract
    /// @dev This function is for informational purposes only and does not modify any state
    /// @return The split rate as a uint256 value
    function getSplitRate() external view returns (uint256) {
        return _splitRate;
    }

    /// @notice Gets the Oracle
    /// @dev This function is for informational purposes only and does not modify any state
    /// @return The Oracle as a IOracle
    function getOracle() external view returns (IOracle) {
        return _oracle;
    }

    /// @notice Gets the weight of the connector in the smart contract
    /// @dev This function is for informational purposes only and does not modify any state
    /// @return The weight of the connector as a uint32 value
    function getConnectorWeight() external view returns (uint32) {
        return _connectorWeight;
    }

    /// @notice Calculates the amount of KAI tokens that will be minted based on the given input amount
    /// @dev This function is purely for informational purposes and does not actually mint any tokens
    /// @param inputAmount The input amount of tokens to be used for the minting calculation
    /// @return The amount of tokens that will be minted based on the input amount
    function getMintAmount(uint256 inputAmount) public view returns (uint256) {
        return _formula.calculatePurchaseReturn({
            supply: _kai.totalSupply(),
            connectorBalance: getTotalBalance(),
            connectorWeight: _connectorWeight,
            depositAmount: inputAmount
        });
    }

    /// @notice Calculates the expected output amount based on the given input amount of KAI
    /// @dev This function is purely for informational purposes and does not perform any actual token swaps
    /// @param inputAmount The input amount of tokens to be used for the swap calculation
    /// @return The expected output amount of tokens based on the input amount
    function getReturnAmount(uint256 inputAmount) public view returns (uint256) {
        return _formula.calculateSaleReturn({
            supply: _kai.totalSupply(),
            connectorBalance: getTotalBalance(),
            connectorWeight: _connectorWeight,
            sellAmount: inputAmount
        });
    }

    /// @notice Gets the total DAI balance of the system
    /// @dev This function is for informational purposes only and does not modify any state
    /// @return The total balance of the smart contract as a uint256 value
    function getTotalBalance() public view returns (uint256) {
        return _connector.balanceOf(address(this)) + _oracle.getUsdValue();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { MultiRolesAuthority, Authority } from "lib/solmate/src/auth/authorities/MultiRolesAuthority.sol";

contract TimeLockedMultiRolesAuthority is MultiRolesAuthority {
    error Locked();

    event InitiatedSetUserRole(address user, uint8 role, bool enabled);
    event InitiatedSetRoleCapability(uint8 role, bytes4 functionSig, bool enabled);

    uint256 public immutable TIMELOCK_DELAY;

    mapping(bytes32 hash => uint256 expirationTimestamp) public userRoleTimelock;

    mapping(bytes32 hash => uint256 expirationTimestamp) public roleCapabilityTimelock;

    constructor(address _owner, uint256 delay) MultiRolesAuthority(_owner, Authority(address(0))) {
        TIMELOCK_DELAY = delay;
    }

    function initiateSetUserRole(address user, uint8 role, bool enabled) public requiresAuth {
        bytes32 hash = keccak256(abi.encode(user, role, enabled));
        userRoleTimelock[hash] = block.timestamp + TIMELOCK_DELAY;
        emit InitiatedSetUserRole(user, role, enabled);
    }

    function initiateSetRoleCapability(uint8 role, bytes4 functionSig, bool enabled) public requiresAuth {
        // TODO: maybe timelock only if enabled == true?
        bytes32 hash = keccak256(abi.encode(role, functionSig, enabled));
        roleCapabilityTimelock[hash] = block.timestamp + TIMELOCK_DELAY;
        emit InitiatedSetRoleCapability(role, functionSig, enabled);
    }

    function setRoleCapability(uint8 role, bytes4 functionSig, bool enabled) public override requiresAuth {
        bytes32 hash = keccak256(abi.encode(role, functionSig, enabled));
        uint256 timelockExpirationTimestamp = roleCapabilityTimelock[hash];
        _validateTime(timelockExpirationTimestamp);
        delete roleCapabilityTimelock[hash];
        super.setRoleCapability(role, functionSig, enabled);
    }

    function setUserRole(address user, uint8 role, bool enabled) public override requiresAuth {
        bytes32 hash = keccak256(abi.encode(user, role, enabled));
        uint256 timelockExpirationTimestamp = userRoleTimelock[hash];
        _validateTime(timelockExpirationTimestamp);
        delete userRoleTimelock[hash];
        super.setUserRole(user, role, enabled);
    }

    function _validateTime(uint256 timelockExpirationTimestamp) private view {
        if (timelockExpirationTimestamp == 0 || block.timestamp < timelockExpirationTimestamp) {
            revert Locked();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

interface INonfungiblePositionManager {
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function safeTransferFrom(address from, address to, uint256 id) external;

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external;

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

/// @custom:security-contact [email protected]
error Unauthorized();
error InvalidAddress();
error InvalidToken();
error InvalidAmount(uint256);
error StrategyNotEnabled();
error ContractIsPaused();
error InvalidInputParameters();
error DuplicateTokens();
error ApprovalFailed();

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import { ERC721TokenReceiver } from "lib/solmate/src/tokens/ERC721.sol";
import { ERC1155TokenReceiver } from "lib/solmate/src/tokens/ERC1155.sol";
import { ReentrancyGuard } from "lib/solmate/src/utils/ReentrancyGuard.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { IVault } from "src/interfaces/IVault.sol";
import { MultiRolesAuthority } from "lib/solmate/src/auth/authorities/MultiRolesAuthority.sol";
import { Unauthorized } from "src/utils/Errors.sol";

/// @title Vault
/// @author Daoism Systems
/// @notice Vault
/// @custom:security-contact [email protected]
contract Vault is ERC721TokenReceiver, ERC1155TokenReceiver, ReentrancyGuard, IVault {
    MultiRolesAuthority public immutable authority;

    constructor(MultiRolesAuthority rolesAuthority) {
        authority = rolesAuthority;
    }

    modifier onlyAuthorised() {
        if (!authority.canCall(msg.sender, address(this), msg.sig)) {
            revert Unauthorized();
        }
        _;
    }

    function multicall(address[] memory targets, bytes[] memory calldatas, uint256[] memory values)
        external
        nonReentrant
        onlyAuthorised
        returns (Result[] memory returnData)
    {
        returnData = new Result[](targets.length);

        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory ret) = targets[i].call{ value: values[i] }(calldatas[i]);
            returnData[i] = Result(success, ret);
        }
    }
}