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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

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
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
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
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { Create2 } from "@openzeppelin/contracts-0.8/utils/Create2.sol";
import { Ownable } from "@openzeppelin/contracts-0.8/access/Ownable.sol";

/**
 * @title   Create2Factory
 * @author  AuraFinance
 * @notice  Deploy contracts using CREATE2 opcode.
 * @dev     A factory contract that uses the CREATE2 opcode to deploy contracts with a deterministic address.
 */
contract Create2Factory is Ownable {
    /**
     * @dev Event emitted when a contract is successfully deployed.
     * @param salt A unique value used as part of the computation to determine the contract's address.
     * @param deployed The address where the contract has been deployed.
     */
    event Deployed(bytes32 indexed salt, address deployed);

    // mapping to track which addresses can deploy contracts.
    mapping(address => bool) public deployer;

    /**
     * @dev Throws error if called by any account other than the deployer.
     */
    modifier onlyDeployer() {
        require(deployer[msg.sender], "!deployer");
        _;
    }

    /**
     * @notice Adds or remove an address from the deployers' whitelist
     * @param _deployer address of the authorized deployer
     * @param _authorized Whether to add or remove deployer
     */
    function updateDeployer(address _deployer, bool _authorized) external onlyOwner {
        deployer[_deployer] = _authorized;
    }

    /**
     * @notice Deploys a contract using the CREATE2 opcode.
     * @param amount The amount of Ether to be sent with the transaction deploying the contract.
     * @param salt A unique value used as part of the computation to determine the contract's address.
     * @param bytecode The bytecode that will be used to create the contract.
     * @param callbacks Callbacks to execute after contract is created.
     * @return The address where the contract has been deployed.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes calldata bytecode,
        bytes[] calldata callbacks
    ) external onlyDeployer returns (address) {
        address deployedAddress = Create2.deploy(amount, salt, bytecode);
        uint256 len = callbacks.length;
        if (len > 0) {
            for (uint256 i = 0; i < len; i++) {
                _execute(deployedAddress, callbacks[i]);
            }
        }

        emit Deployed(salt, deployedAddress);

        return deployedAddress;
    }

    function _execute(address _to, bytes calldata _data) private returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call(_data);
        require(success, "!success");

        return (success, result);
    }

    function computeAddress(bytes32 salt, bytes32 codeHash) external view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }

    /**
     *
     *@dev Fallback function that accepts Ether.
     */
    receive() external payable {}
}