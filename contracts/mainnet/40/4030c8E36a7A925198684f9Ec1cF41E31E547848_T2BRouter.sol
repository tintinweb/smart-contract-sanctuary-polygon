pragma solidity ^0.8.13;

import "./utils/Ownable.sol";
import "./interfaces/IT2BRouter.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract T2BApproval is Ownable {
    using SafeTransferLib for ERC20;

    error ZeroAddress();
    error InvalidTokenAddress();

    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Constructor
    constructor(address _owner, address _t2bRouter) Ownable(_owner) {
        // Set T2b Router.
        IT2BRouter t2bRouter = IT2BRouter(_t2bRouter);

        // Set Max Approvals for supported tokens.
        uint256 tokenIndex = 0;
        while (t2bRouter.supportedTokens(tokenIndex) != address(0)) {
            ERC20(t2bRouter.supportedTokens(tokenIndex)).approve(
                address(t2bRouter),
                type(uint256).max
            );
            unchecked {
                ++tokenIndex;
            }
        }

        selfdestruct(payable(msg.sender));
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTION    *
     *******************************************/

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) internal {
        if (userAddress_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(userAddress_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), userAddress_, amount_);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    error OnlyOwner();
    error OnlyNominee();

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IT2BRouter
 * @notice Interface for T2B Router.
 * @dev functions can be added here for invocation from external contracts or off-chain
 * @author Socket dot tech.
 */
abstract contract IT2BRouter {
    // tokenlist in IT2BRouter
    address[] public supportedTokens;
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
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

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
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

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
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

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

pragma solidity ^0.8.13;

import "./T2BApproval.sol";
import "./utils/Ownable.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract T2BFactory is Ownable {
    address public immutable t2bRouter;

    event NewT2BAddressDeployed(address receiver, uint256 toChainId);

    error ZeroAddress();
    error InvalidTokenAddress();

    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    constructor(address _owner, address _t2bRouter) Ownable(_owner) {
        t2bRouter = _t2bRouter;
    }

    // Deploys the T2BApproval contract.
    function deploy(
        address receiver,
        uint256 toChainId
    ) public payable onlyOwner returns (address) {
        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        bytes32 uniqueSalt = keccak256(abi.encode(receiver, toChainId));
        emit NewT2BAddressDeployed(receiver, toChainId);
        return address(new T2BApproval{salt: uniqueSalt}(owner(), t2bRouter));
    }

    // Returns the pre determined address given receiver and to chain id.
    function getAddressFor(
        address receiver,
        uint256 toChainId
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(receiver, toChainId));
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        type(T2BApproval).creationCode,
                                        abi.encode(owner(), t2bRouter)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTION    *
     *******************************************/

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) internal {
        if (userAddress_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(userAddress_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), userAddress_, amount_);
        }
    }
}

pragma solidity ^0.8.13;

import "./utils/Ownable.sol";
import "./interfaces/IT2BFactory.sol";
import "./interfaces/IT2BRequest.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract T2BRouter is Ownable {
    using SafeTransferLib for ERC20;

    // Errors
    error VerificationCallFailed();
    error InvalidTokenAddress();
    error BalanceMismatch();
    error BridgingFailed();
    error UnsupportedBridge();
    error ZeroAddress();

    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Socket Gateway.
    address public immutable socketGateway;

    address public feeTakerAddress;

    address[] public supportedTokens;

    // IT2B Factory
    IT2BFactory public t2bFactory;

    // mapping of routeids against verifier contracts
    mapping(uint32 => address) public bridgeVerifiers;

    event SocketT2BBridge(bytes32 transferId);

    // Constructor
    constructor(
        address _owner,
        address _socketGateway,
        address _feeTakerAddress
    ) Ownable(_owner) {
        socketGateway = _socketGateway;
        feeTakerAddress = _feeTakerAddress;
    }

    // Set the t2b factory address
    function setT2bFactory(address _t2bFactory) external onlyOwner {
        t2bFactory = IT2BFactory(_t2bFactory);
    }

    // Set the t2b factory address
    function setFeeTakerAddress(address _feeTakerAddress) external onlyOwner {
        feeTakerAddress = _feeTakerAddress;
    }

    // Set bridge verifier contract address against routeId
    function setBridgeVerifier(
        uint32 routeId,
        address bridgeVerifier
    ) external onlyOwner {
        bridgeVerifiers[routeId] = bridgeVerifier;
    }

    // function to add tokens to supportedTokens
    function setSupportedTokens(address[] memory _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            supportedTokens.push(_tokens[i]);
        }
        supportedTokens.push(address(0));
    }

    // function to empty supported tokens array
    function emptyTokenList() external onlyOwner {
        address[] memory emptyList;
        supportedTokens = emptyList;
    }

    // Function that bridges taking amount from the t2bAddress where the user funds are parked.
    function bridgeERC20(
        uint256 fees,
        bytes32 transferId,
        bytes calldata bridgeData
    ) external onlyOwner {
        // note - I think native tokens cannot be supported. Need to think if we need to add a check or not.

        if (bridgeVerifiers[uint32(bytes4(bridgeData[0:4]))] == address(0))
            revert UnsupportedBridge();
        (bool parseSuccess, bytes memory parsedData) = bridgeVerifiers[
            uint32(bytes4(bridgeData[0:4]))
        ].call(bridgeData[4:bridgeData.length - 1]);

        if (!parseSuccess) revert VerificationCallFailed();

        IT2BRequest.T2BRequest memory t2bRequest = abi.decode(
            parsedData,
            (IT2BRequest.T2BRequest)
        );

        address t2bAddress = IT2BFactory(t2bFactory).getAddressFor(
            t2bRequest.recipient,
            t2bRequest.toChainId
        );

        ERC20(t2bRequest.token).safeTransferFrom(
            t2bAddress,
            address(this),
            t2bRequest.amount + fees
        );

        if (fees > 0)
            ERC20(t2bRequest.token).safeTransfer(feeTakerAddress, fees);

        if (
            t2bRequest.amount >
            ERC20(t2bRequest.token).allowance(address(this), socketGateway)
        ) {
            ERC20(t2bRequest.token).safeApprove(
                address(socketGateway),
                type(uint256).max
            );
        }

        (bool bridgeSuccess, ) = socketGateway.call(bridgeData);

        if (!bridgeSuccess) revert BridgingFailed();

        emit SocketT2BBridge(transferId);
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTION    *
     *******************************************/

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) internal {
        if (userAddress_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(userAddress_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), userAddress_, amount_);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IT2BFactory
 * @notice Interface for T2B Factory.
 * @dev functions can be added here for invocation from external contracts or off-chain
 * @author Socket dot tech.
 */
interface IT2BFactory {
    // @notice view to get owner-address
    function getAddressFor(
        address receiver,
        uint256 toChainId
    ) external view returns (address);
}

pragma solidity ^0.8.13;

interface IT2BRequest {
    struct T2BRequest {
        uint256 amount;
        address recipient;
        uint256 toChainId;
        address token;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../interfaces/ISynapseImpl.sol";

contract SynapseVerifier {
    address NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint256 toChainId,
        ISynapseImpl.SwapQuery calldata originQuery,
        ISynapseImpl.SwapQuery calldata destinationQuery
    ) external payable returns (ISynapseImpl.T2BRequest memory) {
        return
            ISynapseImpl.T2BRequest(amount, receiverAddress, toChainId, token);
    }

    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId,
        ISynapseImpl.SwapQuery calldata originQuery,
        ISynapseImpl.SwapQuery calldata destinationQuery
    ) external view returns (ISynapseImpl.T2BRequest memory) {
        return
            ISynapseImpl.T2BRequest(
                amount,
                receiverAddress,
                toChainId,
                NATIVE_TOKEN_ADDRESS
            );
    }
}

pragma solidity ^0.8.13;

interface ISynapseImpl {
    struct SwapQuery {
        address swapAdapter;
        address tokenOut;
        uint256 minAmountOut;
        uint256 deadline;
        bytes rawParams;
    }

    struct T2BRequest {
        uint256 amount;
        address recipient;
        uint256 toChainId;
        address token;
    }

    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint256 toChainId,
        SwapQuery calldata originQuery,
        SwapQuery calldata destinationQuery
    ) external view returns (T2BRequest memory);

    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId,
        SwapQuery calldata originQuery,
        SwapQuery calldata destinationQuery
    ) external view returns (T2BRequest memory);
}