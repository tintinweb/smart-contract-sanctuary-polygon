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

pragma solidity 0.8.17;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IPRouter} from "../interfaces/IPRouter.sol";
import {IPToken} from "../interfaces/IPToken.sol";
import {IPFactory} from "../interfaces/IPFactory.sol";
import {Utils} from "../libraries/Utils.sol";
import {Roles} from "../libraries/Roles.sol";
import {Errors} from "../libraries/Errors.sol";

contract PRouter is IPRouter, Context {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function userSend(
        string calldata destinationAccount,
        bytes4 destinationNetworkId,
        string calldata underlyingAssetName,
        string calldata underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId,
        address assetTokenAddress,
        uint256 assetAmount,
        bytes calldata userData,
        bytes32 optionsMask
    ) external {
        if (
            (assetAmount > 0 && assetTokenAddress == address(0)) ||
            (assetAmount == 0 && assetTokenAddress != address(0))
        ) {
            revert Errors.InvalidAssetParameters(assetAmount, assetTokenAddress);
        }

        if (assetAmount > 0) {
            address pTokenAddress = IPFactory(factory).getPTokenAddress(
                underlyingAssetName,
                underlyingAssetSymbol,
                underlyingAssetDecimals,
                underlyingAssetTokenAddress,
                underlyingAssetNetworkId
            );

            if (pTokenAddress.code.length == 0) {
                revert Errors.PTokenNotCreated(pTokenAddress);
            }

            address msgSender = _msgSender();

            if (underlyingAssetTokenAddress == assetTokenAddress && Utils.isCurrentNetwork(destinationNetworkId)) {
                IPToken(pTokenAddress).routedUserMint(msgSender, assetAmount);
            } else if (
                underlyingAssetTokenAddress == assetTokenAddress && !Utils.isCurrentNetwork(destinationNetworkId)
            ) {
                IPToken(pTokenAddress).routedUserMintAndBurn(msgSender, assetAmount);
            } else if (pTokenAddress == assetTokenAddress && !Utils.isCurrentNetwork(destinationNetworkId)) {
                IPToken(pTokenAddress).routedUserBurn(msgSender, assetAmount);
            } else if (pTokenAddress == assetTokenAddress && Utils.isCurrentNetwork(destinationNetworkId)) {
                revert Errors.NoUserOperation();
            } else {
                revert Errors.InvalidUserOperation();
            }
        } else if (userData.length == 0) {
            revert Errors.NoUserOperation();
        }

        emit UserOperation(
            gasleft(),
            destinationAccount,
            destinationNetworkId,
            underlyingAssetName,
            underlyingAssetSymbol,
            underlyingAssetDecimals,
            underlyingAssetTokenAddress,
            underlyingAssetNetworkId,
            assetTokenAddress,
            assetAmount,
            userData,
            optionsMask
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title IPFactory
 * @author pNetwork
 *
 * @notice
 */
interface IPFactory {
    event PTokenDeployed(address pTokenAddress);

    function deploy(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external payable returns (address);

    function getBytecode(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external view returns (bytes memory);

    function getPTokenAddress(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external view returns (address);

    function setRouter(address _router) external;

    function setStateManager(address _stateManager) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title IPRouter
 * @author pNetwork
 *
 * @notice
 */
interface IPRouter {
    event UserOperation(
        uint256 nonce,
        string destinationAccount,
        bytes4 destinationNetworkId,
        string underlyingAssetName,
        string underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId,
        address assetTokenAddress,
        uint256 assetAmount,
        bytes userData,
        bytes32 optionsMask
    );

    function userSend(
        string calldata destinationAccount,
        bytes4 destinationNetworkId,
        string calldata underlyingAssetName,
        string calldata underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId,
        address assetTokenAddress,
        uint256 assetAmount,
        bytes calldata userData,
        bytes32 optionsMask
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title IPToken
 * @author pNetwork
 *
 * @notice
 */
interface IPToken {
    function routedUserMint(address account, uint256 amount) external;

    function routedUserMintAndBurn(address account, uint256 amount) external;

    function routedUserBurn(address account, uint256 amount) external;

    function stateManagedProtocolMint(address account, uint256 amount) external;

    function stateManagedProtocolBurn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Errors {
    error OperationAlreadyQueued(bytes32 operationId);
    error OperationAlreadyExecuted(bytes32 operationId);
    error OperationCancelled(bytes32 operationId);
    error OperationNotQueued(bytes32 operationId);
    error ExecuteTimestampNotReached(uint64 executeTimestamp);
    error InvalidUnderlyingAssetName(string underlyingAssetName, string expectedUnderlyingAssetName);
    error InvalidUnderlyingAssetSymbol(string underlyingAssetSymbol, string expectedUnderlyingAssetSymbol);
    error InvalidUnderlyingAssetDecimals(uint256 underlyingAssetDecimals, uint256 expectedUnderlyingAssetDecimals);
    error InvalidAssetParameters(uint256 assetAmount, address assetTokenAddress);
    error SenderIsNotRouter();
    error SenderIsNotStateManager();
    error InvalidUserOperation();
    error NoUserOperation();
    error PTokenNotCreated(address pTokenAddress);
    error InvalidNetwork(bytes4 networkId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Roles {
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Utils {
    function isCurrentNetwork(bytes4 networkId) internal view returns (bool) {
        uint256 currentchainId;
        assembly {
            currentchainId := chainid()
        }

        bytes1 version = 0x01;
        bytes1 networkType = 0x01;
        bytes1 extraData = 0x00;
        bytes4 currentNetworkId = bytes4(sha256(abi.encode(version, networkType, currentchainId, extraData)));
        return currentNetworkId == networkId;
    }

    function isBitSet(bytes32 b, uint pos) internal pure returns (bool) {
        return (bytes32(b) & bytes32(1 << (pos + 64))) != 0;
    }

    function normalizeAmount(uint256 amount, uint256 decimals, bool use) internal pure returns (uint256) {
        uint256 difference = (10 ** (18 - decimals));
        return use ? amount * difference : amount / difference;
    }

    function parseAddress(string memory addr) internal pure returns (address) {
        bytes memory tmp = bytes(addr);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
}