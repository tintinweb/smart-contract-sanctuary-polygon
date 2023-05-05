/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @title IVault
/// @notice Interface for a contract that manages the storage of a single asset.
interface IVault {
    /// @notice Set the strategy for the Vault
    /// @dev Can only be called by the strategySetter
    /// @param newStrategy The new strategy contract address
    function setStrategy(address newStrategy) external;

    /// @notice Set the strategy setter for the Vault
    /// @dev Can only be called by the current strategySetter
    /// @param newStrategySetter The new strategy setter address
    function setStrategySetter(address newStrategySetter) external;

    /// @notice Increase the balance of the Vault
    /// @dev Can only be called by authorized parties
    /// @param amount The amount of assets to increase the balance by.
    function increaseBalance(uint256 amount) external;

    /// @notice Transfers assets from this contract to the specified address.
    /// @dev Can only be called by authorized parties
    /// @param amount The amount of assets to transfer.
    /// @param to The address to transfer the assets to.
    function withdraw(uint256 amount, address to) external;

    /// @notice Returns the ERC20 asset managed by this contract.
    /// @return The ERC20 asset managed by this contract.
    function asset() external view returns (address);

    /// @notice Returns the address of the strategy setter
    /// @return The address of the strategy setter
    function strategySetter() external view returns (address);

    /// @notice Returns the Strategy contract attached to this vault.
    /// @return The Strategy contract attached to this vault.
    function strategy() external view returns (address);

    /// @notice Returns the Strategy contract attached to this vault.
    /// @return The Strategy contract attached to this vault.
    function balance() external view returns (uint256);
}

interface IVaultDeployer {
    struct Params {
        address asset; // The address of the asset the vault will hold
        address router; // The address of the router used to trade the asset
        address strategySetter; // The address that will be able to set the vault's strategy
    }

    /// @notice Deploys a new vault contract
    /// @param index The address of the index contract
    /// @param asset The address of the asset the vault will hold
    /// @return vault The address of the newly deployed vault contract
    function deploy(address index, address asset) external returns (address vault);

    /// @notice Returns the address of the vault for the specified index and asset
    /// @param index The address of the index contract
    /// @param asset The address of the asset the vault holds
    /// @return The address of the vault contract
    function vaultOf(address index, address asset) external view returns (address);

    /// @notice Returns the addresses of the vault for the specified index and assets
    /// @param index The address of the index contract
    /// @param assets The addresses of the asset the vault holds
    /// @return vaults The addresses of the vault contracts
    function vaultsOf(address index, address[] calldata assets) external view returns (address[] memory vaults);

    /// @notice Returns the parameters used to deploy a vault contract
    /// @return asset The address of the asset the vault will hold
    /// @return router The address of the router used to communicate in OMNI
    /// @return strategySetter The address that will be able to set the vault's strategy
    function params() external view returns (address asset, address router, address strategySetter);
}

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

/// @title VaultErrors
/// @notice Defines errors that can be thrown by an asset vault contract.
interface VaultErrors {
    /// @notice Thrown when an operation is forbidden by the contract.
    /// @dev This error can be thrown if the caller does not have sufficient permissions to perform a certain action.
    error VaultForbidden();
}

/// @title Vault
/// @notice A contract that manages the storage of a single asset.
/// @dev This contract allows authorized parties to transfer the asset to other addresses.
contract Vault is IVault, ReentrancyGuard, VaultErrors {
    using SafeTransferLib for ERC20;

    /// @dev The address of the MessageRouter contract that is authorized to call this contract.
    address internal immutable router;

    /// @inheritdoc IVault
    address public immutable override asset;

    /// @inheritdoc IVault
    address public override strategySetter;

    /// @inheritdoc IVault
    address public override strategy;

    /// @inheritdoc IVault
    uint256 public override balance;

    constructor() {
        (asset, router, strategySetter) = IVaultDeployer(msg.sender).params();
    }

    /// @inheritdoc IVault
    function increaseBalance(uint256 amount) external nonReentrant {
        if (!isAuthorized()) {
            revert VaultForbidden();
        }

        balance += amount;
    }

    /// @inheritdoc IVault
    function withdraw(uint256 amount, address to) external override nonReentrant {
        //        if (!isAuthorized()) {
        //            revert VaultForbidden();
        //        }
        //
        ERC20(asset).safeTransfer(to, amount);
        //        balance -= amount;
    }

    /// @inheritdoc IVault
    function setStrategy(address newStrategy) external override {
        if (msg.sender != strategySetter) {
            revert VaultForbidden();
        }

        strategy = newStrategy;
    }

    /// @inheritdoc IVault
    function setStrategySetter(address newStrategySetter) external {
        if (msg.sender != strategySetter) {
            revert VaultForbidden();
        }

        strategySetter = newStrategySetter;
    }

    /// @notice Check if the caller is authorized to perform actions on the Vault
    /// @return True if the caller is authorized, false otherwise
    function isAuthorized() internal view returns (bool) {
        return router == msg.sender || strategy == msg.sender;
    }
}