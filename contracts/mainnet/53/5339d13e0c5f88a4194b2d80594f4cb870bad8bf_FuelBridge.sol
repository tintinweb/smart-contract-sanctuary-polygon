// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Bytes32AddressLib} from "./Bytes32AddressLib.sol";

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                address(this),
                // Salt:
                salt,
                // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {CREATE3} from "solmate/utils/CREATE3.sol";

import {ICREATE3Factory} from "./ICREATE3Factory.sol";

/// @title Factory for deploying contracts to deterministic addresses via CREATE3
/// @author zefram.eth
/// @notice Enables deploying contracts using CREATE3. Each deployer (msg.sender) has
/// its own namespace for deployed addresses.
contract CREATE3Factory is ICREATE3Factory {
    /// @inheritdoc	ICREATE3Factory
    function deploy(bytes32 salt, bytes memory creationCode)
        external
        payable
        override
        returns (address deployed)
    {
        // hash salt with the deployer address to give each deployer its own namespace
        salt = keccak256(abi.encodePacked(msg.sender, salt));
        return CREATE3.deploy(salt, creationCode, msg.value);
    }

    /// @inheritdoc	ICREATE3Factory
    function getDeployed(address deployer, bytes32 salt)
        external
        view
        override
        returns (address deployed)
    {
        // hash salt with the deployer address to give each deployer its own namespace
        salt = keccak256(abi.encodePacked(deployer, salt));
        return CREATE3.getDeployed(salt);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0;

/// @title Factory for deploying contracts to deterministic addresses via CREATE3
/// @author zefram.eth
/// @notice Enables deploying contracts using CREATE3. Each deployer (msg.sender) has
/// its own namespace for deployed addresses.
interface ICREATE3Factory {
    /// @notice Deploys a contract using CREATE3
    /// @dev The provided salt is hashed together with msg.sender to generate the final salt
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @param creationCode The creation code of the contract to deploy
    /// @return deployed The address of the deployed contract
    function deploy(bytes32 salt, bytes memory creationCode)
        external
        payable
        returns (address deployed);

    /// @notice Predicts the address of a deployed contract
    /// @dev The provided salt is hashed together with the deployer address to generate the final salt
    /// @param deployer The deployer account that will call deploy()
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @return deployed The address of the contract that will be deployed
    function getDeployed(address deployer, bytes32 salt)
        external
        view
        returns (address deployed);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import {IChildERC20} from "./interfaces/IChildERC20.sol";
import {IFuelBridge} from "./interfaces/IFuelBridge.sol";
import {CREATE3Factory} from "../lib/create3-factory/src/CREATE3Factory.sol";

/**
 * @title  Fuel Bridge from Polygon to Ethereum
 * @notice Burned tokens may take up to 6 hours to be checkpointed by PoS validators.
 * @author GET Protocol DAO
 */
contract FuelBridge is IFuelBridge {
    IChildERC20 public childToken;
    address public owner;
    uint256 public lastRun;
    uint256 public tokenLowerLimit;
    uint256 public dayLimit;
    uint256 private locked = 1; // Used in reentrancy check.

    constructor(address childToken_, address owner_, uint256 tokenLowerLimit_, uint256 dayLimit_) {
        childToken = IChildERC20(childToken_);
        owner = owner_;
        tokenLowerLimit = tokenLowerLimit_ * 1 ether;
        dayLimit = dayLimit_ * 1 days;
        lastRun = block.timestamp;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                             Modifiers                             ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    modifier onlyOwner() {
        require(msg.sender == owner, "FB:CALLER_NOT_OWNER");
        _;
    }
    
    modifier nonReentrant() {
        require(locked == 1, "FB:LOCKED");

        locked = 2;

        _;

        locked = 1;
    }

    modifier canBurn() {
        require(childToken.balanceOf(address(this)) > tokenLowerLimit, "FB:INSUFFICIENT_BALANCE");
        require(block.timestamp - lastRun > (dayLimit), "FB:BURN_CALLED_TOO_SOON");
        _;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc IFuelBridge
     */
    function burn() external override nonReentrant canBurn {
        uint256 childTokenBalance_ = childToken.balanceOf(address(this));

        childToken.withdraw(childTokenBalance_);
        lastRun = block.timestamp;

        emit Burn(childTokenBalance_);
    }

    /**
     * @inheritdoc IFuelBridge
     */
    function setTokenLowerLimit(uint256 tokenLowerLimit_) external override onlyOwner {
        require(tokenLowerLimit_ >= 0, "FB:LOWER_TOKEN_LIMIT_LESS_THAN_0");
        tokenLowerLimit = tokenLowerLimit_ * 1 ether;

        emit TokenLowerLimitChanged(tokenLowerLimit_);
    }

    /**
     * @inheritdoc IFuelBridge
     */
    function setDayLimit(uint256 dayLimit_) external override onlyOwner {
        require(dayLimit_ >= 0, "FB:DAY_LIMIT_LESS_THAN_0");
        dayLimit = dayLimit_ * 1 days;

        emit DayLimitChanged(dayLimit_);
    }

    /**
     * @inheritdoc IFuelBridge
     */
    function emergencyWithdraw(address to_, uint256 amount_) external override onlyOwner {
        require(childToken.transfer(to_, amount_), "FB:TRANSFER_FAILED");

        emit EmergencyWithdraw(to_, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface IChildERC20 {
    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param  account Account address to view balance of.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Represents withdraw function from ChildERC20 from Polygon PoS-portal.
     * @notice Called when user wants to withdraw tokens back to root chain.
     * @dev Should burn user's tokens. This transaction will be verified once it exists on the root chain.
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Moves `amount` tokens from the caller's account to `to`.
     * @param  recipient Address of recipient to receive tokens.
     * @param  amount Amount of tokens to be transferred.
     * @return Boolean status value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface IFuelBridge {
    /**
     * @notice Emitted when childToken is burned for the Polygon PoS withdrawal.
     * @param  tokenAmount_ amount of childToken burned.
     */
    event Burn(uint256 tokenAmount_);

    /**
     * @notice Emitted when the lower limit of childToken required to allow `burn` is changed.
     * @param  tokenLowerLimit_ Updated lower limit value.
     */
    event TokenLowerLimitChanged(uint256 tokenLowerLimit_);  

    /**
     * @notice Emitted when the day limit required to allow `burn` is changed.
     * @param  dayLimit_ Updated day limit value.
     */
    event DayLimitChanged(uint256 dayLimit_);

    /**
     * @notice Emitted when assets are withdrawn from the contract.
     * @param  to_ Address the childToken is withdrawn to.
     * @param  amount_ Amount of childToken withdrawn.
     */
    event EmergencyWithdraw(address to_, uint256 amount_);

    /**
     * @notice Burns of the total balance of childTokens within the contract.
     */
    function burn() external;

    /**
     * @notice Sets the lower limit of childToken required to allow `burn`.
     * @param  tokenLowerLimit_ Value to set lower limit to.
     */
    function setTokenLowerLimit(uint256 tokenLowerLimit_) external;

    /**
     * @notice Sets the day limit required to allow `burn`.
     * @param  dayLimit_ Value to set day limit to.
     */
    function setDayLimit(uint256 dayLimit_) external;

    /**
     * @notice Owner-protected withdrawal of childToken.
     * @param  to_ Address to withdraw to.
     * @param  amount_ Amount of tokens to withdraw.
     */
    function emergencyWithdraw(address to_, uint256 amount_) external;
}