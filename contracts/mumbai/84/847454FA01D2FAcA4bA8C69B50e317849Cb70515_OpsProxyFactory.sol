// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {GelatoBytes} from "../vendor/gelato/GelatoBytes.sol";

// solhint-disable private-vars-leading-underscore
// solhint-disable func-visibility

function _call(
    address _add,
    bytes memory _data,
    uint256 _value,
    bool _revertOnFailure,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.call{value: _value}(_data);

    if (!success && _revertOnFailure)
        GelatoBytes.revertWithError(returnData, _tracingInfo);
}

function _delegateCall(
    address _add,
    bytes memory _data,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.delegatecall(_data);

    if (!success) GelatoBytes.revertWithError(returnData, _tracingInfo);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOpsProxy {
    /**
     * @notice Emitted when proxy calls a contract successfully in `executeCall`
     *
     * @param target Address of contract that is called
     * @param data Data used in the call.
     * @param value Native token value used in the call.
     * @param returnData Data returned by the call.
     */
    event ExecuteCall(
        address indexed target,
        bytes data,
        uint256 value,
        bytes returnData
    );

    /**
     * @notice Multicall to different contracts with different datas.
     *
     * @param targets Addresses of contracts to be called.
     * @param datas Datas for each contract call.
     * @param values Native token value for each contract call.
     */
    function batchExecuteCall(
        address[] calldata targets,
        bytes[] calldata datas,
        uint256[] calldata values
    ) external payable;

    /**
     * @notice Call to a single contract.
     *
     * @param target Address of contracts to be called.
     * @param data Data for contract call.
     * @param value Native token value for contract call.
     */
    function executeCall(
        address target,
        bytes calldata data,
        uint256 value
    ) external payable;

    /**
     * @return address Ops smart contract address
     */
    function ops() external view returns (address);

    /**
     * @return address Owner of the proxy
     */
    function owner() external view returns (address);

    /**
     * @return uint256 version of OpsProxy.
     */
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOpsProxyFactory {
    /**
     * @notice Emitted when an OpsProxy is deployed.
     *
     * @param deployer Address which initiated the deployment
     * @param owner The address which the proxy is for.
     * @param seed Seed used for deployment.
     * @param salt Salt used for deployment.
     * @param proxy Address of deployed proxy.
     */
    event DeployProxy(
        address indexed deployer,
        address indexed owner,
        bytes32 seed,
        bytes32 salt,
        address proxy
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
     * @notice Determines the OpsProxy address when it is not deployed.
     *
     * @param account Address to determine the proxy address for.
     */
    function determineProxyAddress(address account)
        external
        view
        returns (address);

    /**
     * @return bytes32 Next seed which will be used for deployment for an address.
     */
    function getNextSeed(address account) external view returns (bytes32);

    /**
     * @return address Proxy address owned by account.
     * @return bool Whether if proxy is deployed
     */
    function getProxyOf(address account) external view returns (address, bool);

    /**
     * @return address Owner of deployed proxy.
     */
    function getOwnerOf(address proxy) external view returns (address);

    /**
     * @return bool Whether if a contract is an OpsProxy.
     */
    function isProxy(address proxy) external view returns (bool);

    /**
     * @return uint256 version of OpsProxyFactory.
     */
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Proxied} from "../vendor/proxy/EIP173/Proxied.sol";
import {GelatoBytes} from "../vendor/gelato/GelatoBytes.sol";
import {_call} from "../functions/FExec.sol";
import {IOpsProxy} from "../interfaces/IOpsProxy.sol";

contract OpsProxy is Proxied, IOpsProxy {
    using GelatoBytes for bytes;

    // solhint-disable const-name-snakecase
    uint256 public constant override version = 1;
    address public immutable override ops;

    modifier onlyAuth() {
        require(
            msg.sender == ops || msg.sender == owner(),
            "OpsProxy: Not authorised"
        );

        if (msg.sender == ops) {
            address taskCreator = _getTaskCreator();

            require(
                taskCreator == owner(),
                "OpsProxy: Only tasks created by owner"
            );
        }
        _;
    }

    // solhint-disable no-empty-blocks
    constructor(address _ops) {
        ops = _ops;
    }

    receive() external payable {}

    ///@inheritdoc IOpsProxy
    function batchExecuteCall(
        address[] calldata _targets,
        bytes[] calldata _datas,
        uint256[] calldata _values
    ) external payable override onlyAuth {
        uint256 length = _targets.length;
        require(
            length == _datas.length && length == _values.length,
            "OpsProxy: Length mismatch"
        );

        for (uint256 i; i < length; i++)
            _executeCall(_targets[i], _datas[i], _values[i]);
    }

    ///@inheritdoc IOpsProxy
    function executeCall(
        address _target,
        bytes calldata _data,
        uint256 _value
    ) external payable override onlyAuth {
        _executeCall(_target, _data, _value);
    }

    function owner() public view returns (address) {
        return _proxyAdmin();
    }

    function _executeCall(
        address _target,
        bytes calldata _data,
        uint256 _value
    ) private {
        (, bytes memory returnData) = _call(
            _target,
            _data,
            _value,
            true,
            "OpsProxy.executeCall: "
        );

        emit ExecuteCall(_target, _data, _value, returnData);
    }

    function _getTaskCreator() private pure returns (address taskCreator) {
        assembly {
            taskCreator := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    EIP173NonTransferableWithCustomReceive
} from "../vendor/proxy/EIP173/EIP173NonTransferableWithCustomReceive.sol";
import {OpsProxy} from "./OpsProxy.sol";
import {IOpsProxy} from "../interfaces/IOpsProxy.sol";
import {IOpsProxyFactory} from "../interfaces/IOpsProxyFactory.sol";

// solhint-disable max-states-count
contract OpsProxyFactory is IOpsProxyFactory {
    // solhint-disable const-name-snakecase
    uint256 public constant override version = 1;
    address public immutable ops;
    address public immutable implementation;

    ///@dev track the next seed to be used by an EOA.
    mapping(address => bytes32) internal _nextSeeds;

    ///@dev track deployed proxies
    mapping(address => bool) internal _proxies;

    ///@dev track proxy of user
    mapping(address => address) internal _proxyOf;

    ///@dev track owner of proxy
    mapping(address => address) internal _ownerOf;

    modifier onlyOneProxy(address _account) {
        require(_proxyOf[_account] == address(0), "OpsProxyFactory: One proxy");
        _;
    }

    modifier notProxy(address _account) {
        require(!isProxy(_account), "OpsProxyFactory: No proxy");
        _;
    }

    constructor(address _ops, address _implementation) {
        ops = _ops;
        implementation = _implementation;
    }

    ///@inheritdoc IOpsProxyFactory
    function deploy() external override returns (address payable proxy) {
        proxy = deployFor(msg.sender);
    }

    ///@inheritdoc IOpsProxyFactory
    function getNextSeed(address _account)
        external
        view
        override
        returns (bytes32)
    {
        return _nextSeeds[_account];
    }

    ///@inheritdoc IOpsProxyFactory
    function getProxyOf(address _account)
        external
        view
        override
        returns (address, bool)
    {
        address proxyAddress = _proxyOf[_account];

        if (proxyAddress != address(0)) return (proxyAddress, true);

        proxyAddress = determineProxyAddress(_account);
        return (proxyAddress, false);
    }

    ///@inheritdoc IOpsProxyFactory
    function getOwnerOf(address _proxy)
        external
        view
        override
        returns (address)
    {
        require(isProxy(_proxy), "OpsProxyFactory: Not proxy");

        return _ownerOf[_proxy];
    }

    ///@inheritdoc IOpsProxyFactory
    function deployFor(address owner)
        public
        override
        onlyOneProxy(owner)
        notProxy(owner)
        returns (address payable proxy)
    {
        (bytes32 seed, bytes32 salt) = _getSeedAndSalt(owner);

        bytes memory bytecode = _getBytecode(owner);

        proxy = _deploy(salt, bytecode);

        _proxies[proxy] = true;
        _proxyOf[owner] = proxy;
        _ownerOf[proxy] = owner;

        unchecked {
            _nextSeeds[owner] = bytes32(uint256(seed) + 1);
        }

        emit DeployProxy(msg.sender, owner, seed, salt, address(proxy));
    }

    ///@inheritdoc IOpsProxyFactory
    function determineProxyAddress(address _account)
        public
        view
        override
        returns (address)
    {
        address proxyAddress = _proxyOf[_account];
        if (proxyAddress != address(0)) return proxyAddress;

        (, bytes32 salt) = _getSeedAndSalt(_account);

        bytes memory bytecode = _getBytecode(_account);

        bytes32 codeHash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        return address(uint160(uint256(codeHash)));
    }

    ///@inheritdoc IOpsProxyFactory
    function isProxy(address proxy) public view override returns (bool) {
        return _proxies[proxy];
    }

    function _deploy(bytes32 _salt, bytes memory _bytecode)
        internal
        returns (address payable proxy)
    {
        assembly {
            let endowment := 0
            let bytecodeStart := add(_bytecode, 0x20)
            let bytecodeLength := mload(_bytecode)
            proxy := create2(endowment, bytecodeStart, bytecodeLength, _salt)
        }
    }

    function _getSeedAndSalt(address _account)
        internal
        view
        returns (bytes32 seed, bytes32 salt)
    {
        seed = _nextSeeds[_account];

        salt = keccak256(abi.encode(_account, seed));
    }

    function _getBytecode(address _owner) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                type(EIP173NonTransferableWithCustomReceive).creationCode,
                abi.encode(implementation, _owner, bytes(""))
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./Proxy.sol";

interface ERC165 {
    function supportsInterface(bytes4 id) external view returns (bool);
}

/**
 * @notice Proxy implementing EIP173 for ownership management
 * @dev transferProxyAdmin removed
 */
contract EIP173NonTransferable is Proxy {
    // ////////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////

    event ProxyAdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    // /////////////////////// CONSTRUCTOR //////////////////////////////////////////////////////////////////////

    constructor(
        address implementationAddress,
        address adminAddress,
        bytes memory data
    ) payable {
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

    function upgradeTo(address newImplementation) external onlyProxyAdmin {
        _setImplementation(newImplementation, "");
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        onlyProxyAdmin
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

import "./EIP173NonTransferable.sol";

///@notice Proxy implementing EIP173 for ownership management that accept ETH via receive
contract EIP173NonTransferableWithCustomReceive is EIP173NonTransferable {
    constructor(
        address implementationAddress,
        address ownerAddress,
        bytes memory data
    )
        payable
        EIP173NonTransferable(implementationAddress, ownerAddress, data)
    {}

    receive() external payable override {
        _fallback();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
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