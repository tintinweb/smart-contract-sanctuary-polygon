// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Factory for arbitrary code deployment using the "CREATE" and "CREATE2" opcodes
 */
abstract contract Factory {
    error Factory__FailedDeployment();

    /**
     * @notice deploy contract code using "CREATE" opcode
     * @param initCode contract initialization code
     * @return deployment address of deployed contract
     */
    function _deploy(
        bytes memory initCode
    ) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create(0, encoded_data, encoded_size)
        }

        if (deployment == address(0)) revert Factory__FailedDeployment();
    }

    /**
     * @notice deploy contract code using "CREATE2" opcode
     * @dev reverts if deployment is not successful (likely because salt has already been used)
     * @param initCode contract initialization code
     * @param salt input for deterministic address calculation
     * @return deployment address of deployed contract
     */
    function _deploy(
        bytes memory initCode,
        bytes32 salt
    ) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create2(0, encoded_data, encoded_size, salt)
        }

        if (deployment == address(0)) revert Factory__FailedDeployment();
    }

    /**
     * @notice calculate the _deployMetamorphicContract deployment address for a given salt
     * @param initCodeHash hash of contract initialization code
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function _calculateDeploymentAddress(
        bytes32 initCodeHash,
        bytes32 salt
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex'ff',
                                address(this),
                                salt,
                                initCodeHash
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { Factory } from './Factory.sol';

/**
 * @title Factory for the deployment of EIP1167 minimal proxies
 * @dev derived from https://github.com/optionality/clone-factory (MIT license)
 */
abstract contract MinimalProxyFactory is Factory {
    bytes private constant MINIMAL_PROXY_INIT_CODE_PREFIX =
        hex'3d602d80600a3d3981f3_363d3d373d3d3d363d73';
    bytes private constant MINIMAL_PROXY_INIT_CODE_SUFFIX =
        hex'5af43d82803e903d91602b57fd5bf3';

    /**
     * @notice deploy an EIP1167 minimal proxy using "CREATE" opcode
     * @param target implementation contract to proxy
     * @return minimalProxy address of deployed proxy
     */
    function _deployMinimalProxy(
        address target
    ) internal returns (address minimalProxy) {
        return _deploy(_generateMinimalProxyInitCode(target));
    }

    /**
     * @notice deploy an EIP1167 minimal proxy using "CREATE2" opcode
     * @dev reverts if deployment is not successful (likely because salt has already been used)
     * @param target implementation contract to proxy
     * @param salt input for deterministic address calculation
     * @return minimalProxy address of deployed proxy
     */
    function _deployMinimalProxy(
        address target,
        bytes32 salt
    ) internal returns (address minimalProxy) {
        return _deploy(_generateMinimalProxyInitCode(target), salt);
    }

    /**
     * @notice calculate the deployment address for a given target and salt
     * @param target implementation contract to proxy
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function _calculateMinimalProxyDeploymentAddress(
        address target,
        bytes32 salt
    ) internal view returns (address) {
        return
            _calculateDeploymentAddress(
                keccak256(_generateMinimalProxyInitCode(target)),
                salt
            );
    }

    /**
     * @notice concatenate elements to form EIP1167 minimal proxy initialization code
     * @param target implementation contract to proxy
     * @return bytes memory initialization code
     */
    function _generateMinimalProxyInitCode(
        address target
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                MINIMAL_PROXY_INIT_CODE_PREFIX,
                target,
                MINIMAL_PROXY_INIT_CODE_SUFFIX
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../interfaces/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    error SafeERC20__ApproveFromNonZeroToNonZero();
    error SafeERC20__DecreaseAllowanceBelowZero();
    error SafeERC20__OperationFailed();

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if ((value != 0) && (token.allowance(address(this), spender) != 0))
            revert SafeERC20__ApproveFromNonZeroToNonZero();

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            if (oldAllowance < value)
                revert SafeERC20__DecreaseAllowanceBelowZero();
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            if (!abi.decode(returndata, (bool)))
                revert SafeERC20__OperationFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";

import {IERC20Factory} from "./IERC20Factory.sol";
import {ERC20FactoryInternal} from "./ERC20FactoryInternal.sol";

/**
 * @dev ERC20 implementations must have an initialize function
 */
interface CompatibleERC20Implementation {
    // forgefmt: disable-next-item
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes memory _data
    ) external;
}

/**
 * @title   "ERC20Factory Extension"
 * @notice  A factory contract for creating ECR20 contracts
 * @dev     deploys minimal proxies that point to ERC20Base implementation
 *          compatible to be inherited by facet contract
 *          there is an internal dependency on the globals extension.
 * @dev     inheriting contracts must override the internal _canCreate function
 */

abstract contract ERC20Factory is IERC20Factory, ERC20FactoryInternal, MinimalProxyFactory, ReentrancyGuard {
    /**
     * @notice creates an erc20 contract based on implementation
     * @dev the hash of the name is used as a "salt" so each contract is deployed to a different address
     *      the deployed contract is a minimal proxy that points to the implementation chosen
     * @param _name the name of the erc20 contract
     * @param _symbol the symbol of the erc20 contract
     * @param _decimals the decimals for currency
     * @param _supply the initial minted supply, mints to caller
     * @param _implementationId the chosen implementation of erc20 contract
     */
    function createERC20(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes32 _implementationId
    ) external payable virtual nonReentrant returns (address id) {
        if (!_canCreate()) {
            revert ERC20Factory_doNotHavePermission();
        }

        address implementation = _getImplementation(_implementationId);
        if (implementation == address(0)) {
            revert ERC20Factory_noImplementationFound();
        }

        // hook to add functionality before create
        _beforeCreate();

        // deploys new proxy using CREATE2
        id = _deployMinimalProxy(implementation, _getSalt(msg.sender));
        _increaseContractCount(msg.sender);

        // add the app address and globals as encoded data
        // this enables ERC20 contracts to grant minter role to the app and pay platform fee's
        bytes memory data = abi.encode(address(this), _getGlobalsAddress());

        // initialize ERC20 contract
        try CompatibleERC20Implementation(payable(id)).initialize(msg.sender, _name, _symbol, _decimals, _supply, data)
        {
            emit Created(id, msg.sender, _name, _symbol, _decimals, _supply, _implementationId);
        } catch {
            revert ERC20Factory_failedToInitialize();
        }
    }

    function getERC20FactoryImplementation(bytes32 _implementationId) external view returns (address) {
        return _getImplementation(_implementationId);
    }

    /**
     * @notice returns the deterministic deployment address of ERC20 contract based on the name an implementation chosen
     * @dev    The contract deployed is a minimal proxy pointing to the implementation
     * @return deploymentAddress the address the erc20 contract will be deployed to
     */
    function calculateERC20FactoryDeploymentAddress(bytes32 _implementationId) external view returns (address) {
        address implementation = _getImplementation(_implementationId);
        if (implementation == address(0)) {
            revert ERC20Factory_noImplementationFound();
        }

        return _calculateMinimalProxyDeploymentAddress(implementation, _getSalt(msg.sender));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC20FactoryStorage} from "./ERC20FactoryStorage.sol";
import {Global} from "../../extensions/global/Global.sol";

abstract contract ERC20FactoryInternal is Global {
    function _getImplementation(bytes32 _implementationId) internal view virtual returns (address) {
        return _getGlobals().getERC20Implementation(_implementationId);
    }

    /**
     * @dev hash of address and the number of created contracts from that address
     */
    function _getSalt(address _account) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_account, _getContractCount(_account)));
    }

    function _getContractCount(address _account) internal view virtual returns (uint256) {
        return ERC20FactoryStorage.layout().contractCount[_account];
    }

    function _increaseContractCount(address _account) internal virtual {
        ERC20FactoryStorage.layout().contractCount[_account]++;
    }

    function _canCreate() internal view virtual returns (bool);

    /**
     * @dev override to add functionality before create
     */
    function _beforeCreate() internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library ERC20FactoryStorage {
    struct Layout {
        mapping(address => uint256) contractCount; // account => number of contracts created
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ERC20Factory");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IERC20Factory {
    error ERC20Factory_doNotHavePermission();
    error ERC20Factory_noImplementationFound();
    error ERC20Factory_failedToInitialize();

    event Created(
        address id,
        address creator,
        string name,
        string symbol,
        uint8 decimals,
        uint256 supply,
        bytes32 implementationId
    );

    function createERC20(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes32 _implementationId
    ) external payable returns (address id);

    function getERC20FactoryImplementation(bytes32 _implementationId) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IApplicationAccess} from "./IApplicationAccess.sol";
import {ApplicationAccessInternal} from "./ApplicationAccessInternal.sol";

abstract contract ApplicationAccess is IApplicationAccess, ApplicationAccessInternal {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {IApplicationAccess} from "./IApplicationAccess.sol";
import {ApplicationAccessStorage} from "./ApplicationAccessStorage.sol";

abstract contract ApplicationAccessInternal is IApplicationAccess, Ownable {
    /**
     * @dev checks if account can create new contracts
     *      zero address approved (open to all) or
     *      _account address approved (whitelisted) or
     *      _account is the app owner
     * @param _account wallet or contract address to check for creator approval
     */
    function _hasCreatorAccess(address _account) internal view returns (bool) {
        ApplicationAccessStorage.Layout storage l = ApplicationAccessStorage.layout();

        return (l.approvedCreators[address(0)] || l.approvedCreators[_account] || _account == _owner());
    }

    /**
     * @dev sets an array of accounts and their approvals, approve the zero address to open creating to all
     *      will revert if accounts and approvals arrays are different lengths.
     * @param _accounts wallets or contract addresses to set approval
     */
    function _setCreatorAccess(address[] calldata _accounts, bool[] calldata _approvals) internal {
        ApplicationAccessStorage.Layout storage l = ApplicationAccessStorage.layout();

        if (_accounts.length != _approvals.length) {
            revert ApplicationAccess_AccountsAndApprovalsMustBeTheSameLength();
        }

        for (uint256 i = 0; i < _accounts.length; i++) {
            l.approvedCreators[_accounts[i]] = _approvals[i];
        }

        emit CreatorAccessUpdated(_accounts, _approvals);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library ApplicationAccessStorage {
    /**
     * @dev assuming the approved creators will change over time a simple
     *      mapping will be sufficient over a merkle tree implementation.
     */

    struct Layout {
        mapping(address => bool) approvedCreators;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ApplicationAccess");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IApplicationAccess {
    error ApplicationAccess_AccountsAndApprovalsMustBeTheSameLength();
    error ApplicationAccess_notAuthorised();

    event CreatorAccessUpdated(address[] accounts, bool[] approvals);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {GlobalInternal} from "./GlobalInternal.sol";
/**
 * @title Global Facet
 * @notice This allows inherited contract to get/set global address in diamond storage
 * @dev the global address is a contract that holds global state that should be the same for every proxy
 */

abstract contract Global is GlobalInternal {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Globals} from "../../globals/Globals.sol";
import {GlobalStorage} from "./GlobalStorage.sol";

abstract contract GlobalInternal {
    /**
     * @dev returns Globals contract so inherited contracts can call without the need to explicitly import Globals
     */
    function _getGlobals() internal view returns (Globals) {
        return Globals(GlobalStorage.layout().globals);
    }

    function _getGlobalsAddress() internal view returns (address) {
        return GlobalStorage.layout().globals;
    }

    function _setGlobals(address _globals) internal {
        GlobalStorage.layout().globals = _globals;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library GlobalStorage {
    struct Layout {
        address globals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.Global");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IPlatformFee {
    event PaidPlatformFee(address currency, uint256 amount);

    /**
     * @notice gets the platform fee for a given price
     * @param _price the given price of a transaction
     * @return recipient the address to pay the platform fee to
     * @return amount the fee amount
     */
    function platformFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IPlatformFee} from "./IPlatformFee.sol";
import {PlatformFeeInternal} from "./PlatformFeeInternal.sol";

abstract contract PlatformFee is IPlatformFee, PlatformFeeInternal {
    /**
     *   @inheritdoc IPlatformFee
     */
    function platformFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount) {
        (recipient, amount) = _platformFeeInfo(_price);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Global} from "../global/Global.sol";
import {IPlatformFee} from "./IPlatformFee.sol";

abstract contract PlatformFeeInternal is IPlatformFee, Global {
    /**
     * @dev wrapper that calls platformFeeInfo from globals contract
     *      inspired by eip-2981 NFT royalty standard
     */
    function _platformFeeInfo(uint256 _price) internal view returns (address recipient, uint256 amount) {
        (recipient, amount) = _getGlobals().platformFeeInfo(_price);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {ERC20Factory} from "../extensions/ERC20Factory/ERC20Factory.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";
import {ApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";

/**
 * @title   "ERC20Factory Facet"
 * @notice  A facet of the ERC20Factory contract that provides functionality for creating new ERC20 tokens.
 *          This contract also includes extensions for Ownable, PlatformFee, and ApplicationAccess, which allow for ownership management,
 *          platform fee collection, and restricted access to contract creation, respectively.
 *          Before creating a new contract, a platform fee is added, which must be paid in ether.
 */

contract ERC20FactoryFacet is ERC20Factory, Ownable, PlatformFee, ApplicationAccess {
    /**
     * @dev uses applicationAccess extension for create access for new erc20 contracts
     */
    function _canCreate() internal view override returns (bool) {
        return _hasCreatorAccess(msg.sender);
    }

    /**
     * @dev override before create to add platform fee
     *      requires msg.value to be equal or more than base platform fee
     *      when calling createERC20
     */
    function _beforeCreate() internal override {
        (address recipient, uint256 amount) = _platformFeeInfo(0);

        if (amount == 0) {
            return;
        }

        // ensure the ether being sent was included in the transaction
        if (msg.value < amount) {
            revert CurrencyTransferLib.CurrencyTransferLib_insufficientValue();
        }

        CurrencyTransferLib.safeTransferNativeToken(recipient, amount);

        emit PaidPlatformFee(address(0), amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
/**
 * @title Globals
 * @notice holds all global variables that need to be shared between all proxy apps
 * @dev facets can access global variables by calling this contract via `extensions/global`
 *      for example:
 *      ```solidity
 *             import {Global} from "./extensions/Global.sol";
 *
 *             contract Example is Global {
 *                 exampleFunction() {
 *                     address ERC721Implementation = _getGlobals.ERC721Implementation();
 *                 }
 *
 *             }
 *         ```
 * @dev Note: if this is deployed behind an upgradable proxy the global variables can be added to
 */

contract Globals is Ownable {
    error Globals_percentageFeeCannotExceed100();

    event ERC721ImplementationUpdated(bytes32 _implementationId, address _implementation);
    event ERC20ImplementationUpdated(bytes32 _implementationId, address _implementation);

    struct PlatformFee {
        uint256 base;
        uint16 percentageBPS;
        address recipient;
    }

    mapping(bytes32 => address) ERC721Implementations;
    mapping(bytes32 => address) ERC20Implementations;

    PlatformFee platformFee;

    constructor() {
        _setOwner(msg.sender);
    }

    function setERC721Implementation(bytes32 _implementationId, address _implementation) public onlyOwner {
        ERC721Implementations[_implementationId] = _implementation;
        emit ERC721ImplementationUpdated(_implementationId, _implementation);
    }

    function getERC721Implementation(bytes32 _implementationId) public view returns (address) {
        return ERC721Implementations[_implementationId];
    }

    function setERC20Implementation(bytes32 _implementationId, address _implementation) public onlyOwner {
        ERC20Implementations[_implementationId] = _implementation;
        emit ERC20ImplementationUpdated(_implementationId, _implementation);
    }

    function getERC20Implementation(bytes32 _implementationId) public view returns (address) {
        return ERC20Implementations[_implementationId];
    }

    function setPlatformFee(uint256 _base, uint16 _percentageBPS, address recipient) public onlyOwner {
        if (_percentageBPS > 10_000) {
            revert Globals_percentageFeeCannotExceed100();
        }
        platformFee = PlatformFee(_base, _percentageBPS, recipient);
    }

    function setPlatformBaseFee(uint256 _base) public onlyOwner {
        platformFee.base = _base;
    }

    function setPlatformPercentageFee(uint16 _percentageBPS) public onlyOwner {
        if (_percentageBPS > 10_000) {
            revert Globals_percentageFeeCannotExceed100();
        }
        platformFee.percentageBPS = _percentageBPS;
    }

    function platformFeeInfo(uint256 _price) external view returns (address recipient, uint256 fee) {
        recipient = platformFee.recipient;
        fee = (_price > 0) ? platformFee.base + (_price * platformFee.percentageBPS) / 10_000 : platformFee.base;
    }
}

// SPDX-License-Identifier:  Apache-2.0
pragma solidity ^0.8.16;

/**
 * @dev derived from thirdweb https://github.com/thirdweb-dev/contracts/blob/main/contracts/lib/CurrencyTransferLib.sol
 */

// Helper interfaces
// import { IWETH } from "../interfaces/IWETH.sol";

import {IERC20, SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

library CurrencyTransferLib {
    using SafeERC20 for IERC20;

    error CurrencyTransferLib_insufficientValue();
    error CurrencyTransferLib_nativeTokenTransferFailed();

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = address(0);

    /// @dev Transfers a given amount of currency.
    function transferCurrency(address _currency, address _from, address _to, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    // function transferCurrencyWithWrapper(
    //     address _currency,
    //     address _from,
    //     address _to,
    //     uint256 _amount,
    //     address _nativeTokenWrapper
    // ) internal {
    //     if (_amount == 0) {
    //         return;
    //     }

    //     if (_currency == NATIVE_TOKEN) {
    //         if (_from == address(this)) {
    //             // withdraw from weth then transfer withdrawn native token to recipient
    //             IWETH(_nativeTokenWrapper).withdraw(_amount);
    //             safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
    //         } else if (_to == address(this)) {
    //             // store native currency in weth
    //             require(_amount == msg.value, "msg.value != amount");
    //             IWETH(_nativeTokenWrapper).deposit{value: _amount}();
    //         } else {
    //             safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
    //         }
    //     } else {
    //         safeTransferERC20(_currency, _from, _to, _amount);
    //     }
    // }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(address _currency, address _from, address _to, uint256 _amount) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        // slither-disable-next-line low-level-calls
        (bool success,) = to.call{value: value}("");
        if (!success) {
            revert CurrencyTransferLib_nativeTokenTransferFailed();
        }
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    // function safeTransferNativeTokenWithWrapper(address to, uint256 value, address _nativeTokenWrapper) internal {
    //     // solhint-disable avoid-low-level-calls
    //     // slither-disable-next-line low-level-calls
    //     (bool success,) = to.call{value: value}("");
    //     if (!success) {
    //         IWETH(_nativeTokenWrapper).deposit{value: value}();
    //         IERC20(_nativeTokenWrapper).safeTransfer(to, value);
    //     }
    // }
}