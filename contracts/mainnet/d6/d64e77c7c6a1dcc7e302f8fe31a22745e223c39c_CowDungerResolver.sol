// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "./interfaces/oz/IERC20.sol";
import {ICowDungerModule} from "./interfaces/ICowDungerModule.sol";
import {ISafe} from "./interfaces/safe/ISafe.sol";

/// @title CowDungerResolver
/// @author gosuto.eth
/// @notice A Gelato resolver which signals if there are any whitelisted tokens
/// to sell in the CowDungerModule's multisig
/// @dev https://docs.gelato.network/developer-services/automate/guides/custom-logic-triggers/smart-contract-resolvers
contract CowDungerResolver {
    function checker(address cowDungerModule) external view returns (bool canExec, bytes memory execPayload) {
        ICowDungerModule module = ICowDungerModule(cowDungerModule);
        ISafe safe = module.safe();
        uint256 l = ICowDungerModule(cowDungerModule).whitelistLength();
        uint256[] memory toSell = new uint256[](l);
        for (uint256 idx = 0; idx < l; idx++) {
            uint256 balance = IERC20(module.whitelist(idx)).balanceOf(address(safe));
            if (balance > 0) {
                toSell[idx] = balance;
                canExec = true;
            }
        }
        if (canExec) {
            execPayload = abi.encodeCall(ICowDungerModule.dung, toSell);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISafe} from "./safe/ISafe.sol";

interface ICowDungerModule {
    function safe() external view returns (ISafe);

    function dung(uint256[] calldata toSell) external;

    function whitelistLength() external view returns (uint256);

    function whitelist(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    event AddedOwner(address indexed owner);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event ChangedFallbackHandler(address indexed handler);
    event ChangedGuard(address indexed guard);
    event ChangedThreshold(uint256 threshold);
    event DisabledModule(address indexed module);
    event EnabledModule(address indexed module);
    event ExecutionFailure(bytes32 indexed txHash, uint256 payment);
    event ExecutionFromModuleFailure(address indexed module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionSuccess(bytes32 indexed txHash, uint256 payment);
    event RemovedOwner(address indexed owner);
    event SafeReceived(address indexed sender, uint256 value);
    event SafeSetup(
        address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler
    );
    event SignMsg(bytes32 indexed msgHash);

    fallback() external;

    function VERSION() external view returns (string memory);

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function approveHash(bytes32 hashToApprove) external;

    function approvedHashes(address, bytes32) external view returns (uint256);

    function changeThreshold(uint256 _threshold) external;

    function checkNSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, uint256 requiredSignatures)
        external
        view;

    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures) external view;

    function disableModule(address prevModule, address module) external;

    function domainSeparator() external view returns (bytes32);

    function enableModule(address module) external;

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes memory);

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);

    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success, bytes memory returnData);

    function getChainId() external view returns (uint256);

    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);

    function getOwners() external view returns (address[] memory);

    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

    function getThreshold() external view returns (uint256);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function isModuleEnabled(address module) external view returns (bool);

    function isOwner(address owner) external view returns (bool);

    function nonce() external view returns (uint256);

    function removeOwner(address prevOwner, address owner, uint256 _threshold) external;

    function setFallbackHandler(address handler) external;

    function setGuard(address guard) external;

    function setup(
        address[] memory _owners,
        uint256 _threshold,
        address to,
        bytes memory data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address paymentReceiver
    ) external;

    function signedMessages(bytes32) external view returns (uint256);

    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external;

    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;

    receive() external payable;
}