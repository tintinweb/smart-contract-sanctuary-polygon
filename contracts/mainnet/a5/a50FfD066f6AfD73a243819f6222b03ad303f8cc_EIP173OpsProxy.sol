// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./Proxy.sol";
import {IOpsProxyFactory} from "../../../interfaces/IOpsProxyFactory.sol";

interface ERC165 {
    function supportsInterface(bytes4 id) external view returns (bool);
}

/**
 * @notice Proxy implementing EIP173 for ownership management.
 * @notice This is used for OpsProxy.
 *
 * @dev 1. custom receive can be set in implementation.
 * @dev 2. transferProxyAdmin removed.
 * @dev 3. implementation can only be set to those whitelisted on OpsProxyFactory.
 */
contract EIP173OpsProxy is Proxy {
    // ////////////////////////// STATES ///////////////////////////////////////////////////////////////////////
    IOpsProxyFactory public immutable opsProxyFactory;

    // ////////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////

    event ProxyAdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    // /////////////////////// MODIFIERS //////////////////////////////////////////////////////////////////////
    modifier onlyWhitelistedImplementation(address _implementation) {
        require(
            opsProxyFactory.whitelistedImplementations(_implementation),
            "Implementation not whitelisted"
        );
        _;
    }

    // /////////////////////// FALLBACKS //////////////////////////////////////////////////////////////////////
    receive() external payable override {
        _fallback();
    }

    // /////////////////////// CONSTRUCTOR //////////////////////////////////////////////////////////////////////

    constructor(
        address _opsProxyFactory,
        address implementationAddress,
        address adminAddress,
        bytes memory data
    ) payable {
        opsProxyFactory = IOpsProxyFactory(_opsProxyFactory);
        _setImplementation(implementationAddress, data);
        _setProxyAdmin(adminAddress);
    }

    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

    function proxyAdmin() external view returns (address) {
        return _proxyAdmin();
    }

    function supportsInterface(bytes4 id) external view returns (bool) {
        if (id == 0x01ffc9a7 || id == 0x7f5828d0) {
            return true;
        }
        if (id == 0xFFFFFFFF) {
            return false;
        }

        ERC165 implementation;
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            implementation := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
        }

        // Technically this is not standard compliant as ERC-165 require 30,000 gas which that call cannot ensure
        // because it is itself inside `supportsInterface` that might only get 30,000 gas.
        // In practise this is unlikely to be an issue.
        try implementation.supportsInterface(id) returns (bool support) {
            return support;
        } catch {
            return false;
        }
    }

    function upgradeTo(address newImplementation)
        external
        onlyProxyAdmin
        onlyWhitelistedImplementation(newImplementation)
    {
        _setImplementation(newImplementation, "");
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        onlyProxyAdmin
        onlyWhitelistedImplementation(newImplementation)
    {
        _setImplementation(newImplementation, data);
    }

    // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }

    function _setProxyAdmin(address newAdmin) internal {
        address previousAdmin = _proxyAdmin();
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                newAdmin
            )
        }
        emit ProxyAdminTransferred(previousAdmin, newAdmin);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// EIP-1967
abstract contract Proxy {
    // /////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////////

    event ProxyImplementationUpdated(
        address indexed previousImplementation,
        address indexed newImplementation
    );

    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

    // prettier-ignore
    receive() external payable virtual {
        revert("ETHER_REJECTED"); // explicit reject by default
    }

    fallback() external payable {
        _fallback();
    }

    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

    function _fallback() internal {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            let implementationAddress := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                implementationAddress,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

    function _setImplementation(address newImplementation, bytes memory data)
        internal
    {
        address previousImplementation;
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            previousImplementation := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
        }

        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                newImplementation
            )
        }

        emit ProxyImplementationUpdated(
            previousImplementation,
            newImplementation
        );

        if (data.length > 0) {
            (bool success, ) = newImplementation.delegatecall(data);
            if (!success) {
                assembly {
                    // This assembly ensure the revert contains the exact string data
                    let returnDataSize := returndatasize()
                    returndatacopy(0, 0, returnDataSize)
                    revert(0, returnDataSize)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOpsProxyFactory {
    /**
     * @notice Emitted when an OpsProxy is deployed.
     *
     * @param deployer Address which initiated the deployment
     * @param owner The address which the proxy is for.
     * @param proxy Address of deployed proxy.
     */
    event DeployProxy(
        address indexed deployer,
        address indexed owner,
        address indexed proxy
    );

    /**
     * @notice Emitted when OpsProxy implementation to be deployed is changed.
     *
     * @param oldImplementation Previous OpsProxy implementation.
     * @param newImplementation Current OpsProxy implementation.
     */
    event SetImplementation(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /**
     * @notice Emitted when OpsProxy implementation is added or removed from whitelist.
     *
     * @param implementation OpsProxy implementation.
     * @param whitelisted Added or removed from whitelist.
     */
    event UpdateWhitelistedImplementation(
        address indexed implementation,
        bool indexed whitelisted
    );

    /**
     * @notice Deploys OpsProxy for the msg.sender.
     *
     * @return proxy Address of deployed proxy.
     */
    function deploy() external returns (address payable proxy);

    /**
     * @notice Deploys OpsProxy for another address.
     *
     * @param owner Address to deploy the proxy for.
     *
     * @return proxy Address of deployed proxy.
     */
    function deployFor(address owner) external returns (address payable proxy);

    /**
     * @notice Sets the OpsProxy implementation that will be deployed by OpsProxyFactory.
     *
     * @param newImplementation New implementation to be set.
     */
    function setImplementation(address newImplementation) external;

    /**
     * @notice Add or remove OpsProxy implementation from the whitelist.
     *
     * @param implementation OpsProxy implementation.
     * @param whitelist Added or removed from whitelist.
     */
    function updateWhitelistedImplementations(
        address implementation,
        bool whitelist
    ) external;

    /**
     * @notice Determines the OpsProxy address when it is not deployed.
     *
     * @param account Address to determine the proxy address for.
     */
    function determineProxyAddress(address account)
        external
        view
        returns (address);

    /**
     * @return address Proxy address owned by account.
     * @return bool Whether if proxy is deployed
     */
    function getProxyOf(address account) external view returns (address, bool);

    /**
     * @return address Owner of deployed proxy.
     */
    function ownerOf(address proxy) external view returns (address);

    /**
     * @return bool Whether if implementation is whitelisted.
     */
    function whitelistedImplementations(address implementation)
        external
        view
        returns (bool);
}