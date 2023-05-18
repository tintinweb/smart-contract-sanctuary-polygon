// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IMailbox} from "./interfaces/IMailbox.sol";
import {IInterchainGasPaymaster} from "./interfaces/IInterchainGasPaymaster.sol";
import {IMessageRecipient} from "./interfaces/IMessageRecipient.sol";

contract DeployerX is IMessageRecipient {
    IMailbox constant mailbox =
        IMailbox(0xCC737a94FecaeC165AbCf12dED095BB13F037685);
    IInterchainGasPaymaster constant igp =
        IInterchainGasPaymaster(0xF90cB82a76492614D07B82a7658917f3aC811Ac1);
    uint256 gasAmount = 10000;

    // for access control on handle implementations
    modifier onlyMailbox() {
        require(msg.sender == address(mailbox));
        _;
    }

    // This function is used to deploy the contract across multiple chains
    // @param target - the address of the target contract
    // @param destinationDomain - a array of the destination chain IDs
    // @param salt - the salt used to create the contract address
    // @param bytecode - the bytecode of the contract
    // @param initializable - a boolean to determine if the contract is initializable
    // @param initializeData - the data used to initialize the contract
    function xDeployer(
        bytes32 destinationAddress,
        uint32[] calldata destinationDomain,
        bytes32 salt,
        bytes memory bytecode,
        uint256[] calldata relayerFee,
        bool initializable,
        bytes memory initializeData,
        uint256 totalFee
    ) external payable {
        require(msg.value >= totalFee, "msg.value must equal totalFee");
        if (destinationDomain.length != relayerFee.length) {
            revert("destinationDomain and relayerFee must be the same length");
        }
        // deploy contract on present chain
        deployContract(salt, bytecode, initializable, initializeData);
        // encoding the data to pass to other chains
        bytes memory payload = abi.encode(
            salt,
            bytecode,
            initializable,
            initializeData
        );
        // sending deploy msg to other chains
        for (uint i = 0; i < destinationDomain.length; ) {
            bytes32 messageId = mailbox.dispatch(
                destinationDomain[i],
                destinationAddress,
                payload
            );
            igp.payForGas{value: relayerFee[i]}(
                messageId, // The ID of the message that was just dispatched
                destinationDomain[i], // The destination domain of the message
                gasAmount, // 100k gas to use in the recipient's handle function
                msg.sender // refunds go to msg.sender, who paid the msg.value
            );
            unchecked {
                ++i;
            }
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function handle(
        uint32,
        bytes32,
        bytes memory _body
    ) external override onlyMailbox {
        (
            bytes32 salt,
            bytes memory bytecode,
            bool initializable,
            bytes memory initializeData
        ) = abi.decode(_body, (bytes32, bytes, bool, bytes));
        deployContract(salt, bytecode, initializable, initializeData);
    }

    // This function is used to deploy and initialize a contract
    // @param salt - the salt used to generate the address
    // @param bytecode - the bytecode of the contract
    // @param initializable - whether the contract is initializable
    // @param initializeData - the data used to initialize the contract
    // @return address - the address of the deployed contract
    function deployContract(
        bytes32 salt,
        bytes memory bytecode,
        bool initializable,
        bytes memory initializeData
    ) public returns (address) {
        address deployedAddress = deploy(salt, bytecode);
        // transfer ownership to the _originSender
        if (initializable) {
            (bool success, ) = deployedAddress.call(initializeData);
            require(success, "initiailse failed");
        }
        return deployedAddress;
    }

    // This function is used to deploy a contract using CREATE2
    // @param salt - the salt used to generate the address
    // @param bytecode - the bytecode of the contract
    // @return address - the address of the deployed contract
    function deploy(
        bytes32 salt,
        bytes memory bytecode
    ) public returns (address) {
        return Create2.deploy(0, salt, bytecode);
    }

    // This function is used to compute the address of the contract that will be deployed
    // @param salt - the salt used to generate the address
    // @param bytecode - the bytecode of the contract
    // @return address - the computed address of the contract that will be deployed
    function computeAddress(
        bytes32 salt,
        bytes memory bytecode
    ) public view returns (address) {
        return Create2.computeAddress(salt, keccak256(bytecode));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    /**
     * @notice Emitted when a payment is made for a message's gas costs.
     * @param messageId The ID of the message to pay for.
     * @param gasAmount The amount of destination gas paid for.
     * @param payment The amount of native tokens paid.
     */
    event GasPayment(
        bytes32 indexed messageId,
        uint256 gasAmount,
        uint256 payment
    );

    /**
     * @notice Deposits msg.value as a payment for the relaying of a message
     * to its destination chain.
     * @dev Overpayment will result in a refund of native tokens to the _refundAddress.
     * Callers should be aware that this may present reentrancy issues.
     * @param _messageId The ID of the message to pay for.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasAmount The amount of destination gas to pay for.
     * @param _refundAddress The address to refund any overpayment to.
     */
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    /**
     * @notice Quotes the amount of native tokens to pay for interchain gas.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasAmount The amount of destination gas to pay for.
     * @return The amount of native tokens required to pay for interchain gas.
     */
    function quoteGasPayment(
        uint32 _destinationDomain,
        uint256 _gasAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IMailbox {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);

    function process(
        bytes calldata _metadata,
        bytes calldata _message
    ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    /**
     * @notice Handle an interchain message
     * @param _origin Domain ID of the chain from which the message came
     * @param _sender Address of the message sender on the origin chain as bytes32
     * @param _body Raw bytes content of message body
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external;
}