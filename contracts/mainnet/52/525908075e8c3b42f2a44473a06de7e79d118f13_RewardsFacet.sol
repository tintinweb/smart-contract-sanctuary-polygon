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

import { IOwnable } from './IOwnable.sol';

interface ISafeOwnable is IOwnable {
    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function nomineeOwner() external view returns (address);

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {
    error SafeOwnable__NotNomineeOwner();
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

import { Ownable } from './Ownable.sol';
import { ISafeOwnable } from './ISafeOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableInternal } from './SafeOwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173 with ownership transfer safety check
 */
abstract contract SafeOwnable is ISafeOwnable, Ownable, SafeOwnableInternal {
    /**
     * @inheritdoc ISafeOwnable
     */
    function nomineeOwner() public view virtual returns (address) {
        return _nomineeOwner();
    }

    /**
     * @inheritdoc ISafeOwnable
     */
    function acceptOwnership() public virtual onlyNomineeOwner {
        _acceptOwnership();
    }

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnableInternal) {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    modifier onlyNomineeOwner() {
        if (msg.sender != _nomineeOwner())
            revert SafeOwnable__NotNomineeOwner();
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        _setOwner(msg.sender);
        delete SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().nomineeOwner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

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

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
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

/**
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IMulticall } from './IMulticall.sol';

/**
 * @title Utility contract for supporting processing of multiple function calls in a single transaction
 */
abstract contract Multicall is IMulticall {
    /**
     * @inheritdoc IMulticall
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        results = new bytes[](data.length);

        unchecked {
            for (uint256 i; i < data.length; i++) {
                (bool success, bytes memory returndata) = address(this)
                    .delegatecall(data[i]);

                if (success) {
                    results[i] = returndata;
                } else {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        }

        return results;
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

import {IApplicationFee} from "./IApplicationFee.sol";
import {ApplicationFeeInternal} from "./ApplicationFeeInternal.sol";

/**
 * @dev The application fee extension can be used by facets to set and pay a percentage fee.
 *
 *      inheriting contracts can use the internal function _applicationFeeInfo to get the amount
 *      and recipient to pay.
 *
 *      See payApplicationFee in ApplicationFeeMock.sol for an implementation example.
 */

abstract contract ApplicationFee is IApplicationFee, ApplicationFeeInternal {
    modifier onlyAcceptedCurrencies(address _currency) {
        if (!_isCurrencyAccepted(_currency)) {
            revert ApplicationFee_currencyNotAccepted();
        }
        _;
    }

    /**
     *   @inheritdoc IApplicationFee
     */

    function applicationFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount) {
        return _applicationFeeInfo(_price);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IERC20, SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {IApplicationFee} from "./IApplicationFee.sol";
import {ApplicationFeeStorage} from "./ApplicationFeeStorage.sol";

abstract contract ApplicationFeeInternal is IApplicationFee {
    /**
     * @dev gets applicationFeeInfo for a given price based on percentBPS
     *      inspired by eip-2981 NFT royalty standard
     */
    function _applicationFeeInfo(uint256 _price) internal view returns (address recipient, uint256 amount) {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        recipient = l.recipient;
        amount = _price == 0 ? 0 : (_price * l.percentageBPS) / 10_000;
    }

    /**
     * @dev sets applicationFeeInfo. reverts if percent exceeds 100% (10_000 BPS)
     */
    function _setApplicationFee(uint16 _percentBPS, address _recipient) internal virtual {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        if (_percentBPS > 10_000) {
            revert ApplicationFee_exceedsMaxPercentBPS();
        }

        l.percentageBPS = _percentBPS;
        l.recipient = _recipient;
    }

    function _setAcceptedCurrencies(address[] memory _currencies, bool[] memory _approvals) internal virtual {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        if (_currencies.length != _approvals.length) {
            revert ApplicationFee_currenciesAndApprovalsMustBeTheSameLength();
        }

        for (uint256 i = 0; i < _currencies.length; i++) {
            l.acceptedCurrencies[_currencies[i]] = _approvals[i];
        }
    }

    function _isCurrencyAccepted(address _currency) internal virtual returns (bool) {
        return ApplicationFeeStorage.layout().acceptedCurrencies[_currency];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library ApplicationFeeStorage {
    struct Layout {
        uint16 percentageBPS;
        address recipient;
        mapping(address => bool) acceptedCurrencies;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ApplicationFee");

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

interface IApplicationFee {
    error ApplicationFee_currenciesAndApprovalsMustBeTheSameLength();
    error ApplicationFee_currencyNotAccepted();
    error ApplicationFee_exceedsMaxPercentBPS();

    event PaidApplicationFee(address currency, uint256 amount);

    /**
     * @notice gets the application fee for a given price
     * @param _price the given price of a transaction
     * @return recipient the address to pay the application fee to
     * @return amount the fee amount
     */
    function applicationFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount);
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

import {SafeOwnable, OwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {ApplicationFee} from "../extensions/applicationFee/ApplicationFee.sol";
import {ApplicationAccess, IApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

interface NFT {
    function mintTo(address to, string memory tokenURI) external;
}

interface Token {
    function mintTo(address to, uint256 amount) external;
    function transferFrom(address holder, address receipient, uint256 amount) external;
}

contract RewardsFacet is Multicall, SafeOwnable {
    event Reward(address token, address recipient, uint256 amount, string id, address appId, string activityType);

    function mintERC20(
        address _token,
        address _recipient,
        uint256 _amount,
        string memory _id,
        address _appId,
        string memory _activityType
    ) public {
        Token(_token).mintTo(_recipient, _amount);
        emit Reward(_token, _recipient, _amount, _id, _appId, _activityType);
    }

    function transferERC20(
        address _holder,
        address _token,
        address _recipient,
        uint256 _amount,
        string memory _id,
        address _appId,
        string memory _activityType
    ) public {
        Token(_token).transferFrom(_holder, _recipient, _amount);
        emit Reward(_token, _recipient, _amount, _id, _appId, _activityType);
    }

    function mintERC721(
        address _token,
        address _recipient,
        string memory _tokenURI,
        string memory _id,
        address _appId,
        string memory _activityType
    ) public {
        NFT(_token).mintTo(_recipient, _tokenURI);
        emit Reward(_token, _recipient, 1, _id, _appId, _activityType);
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