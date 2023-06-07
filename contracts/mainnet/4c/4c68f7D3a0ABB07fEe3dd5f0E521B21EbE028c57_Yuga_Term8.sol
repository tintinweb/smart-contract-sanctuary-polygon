// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract ExpressTerms {
    /// @notice Processes an agreement and returns a string representation of the term.
    /// @dev The term function is abstract in the ExpressTerms interface and must be implemented in derived contracts.
    /// @param agreement The agreement to be processed
    /// @return A string that represents the processed term.
    function term(
        Agreement memory agreement
    ) external pure virtual returns (string memory);

    /// @notice Provides the name of this term
    /// @return A string that represents the name of the term
    function name() external pure virtual returns (string memory);
}

/// @title Agreement
/// @notice A struct representing an agreement
struct Agreement {
    string contractName;
    uint128 id;
    address offerer;
    address promisor;
    address[] terms;
    address assetAddress;
    uint256 tokenId;
    address validatorModule;
    uint256 expiration;
    uint256 paymentAmount;
    address[] signers;
    string dynamicData;
    uint256 nonce;
    uint256 chainId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title TermBase
/// @notice A contract implementing basic ERC165 functionality
/// @dev This contract allows derived contracts to handle and maintain a list of supported interfaces
contract TermBase is IERC165 {
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /// @notice Mapping of the supported interfaces
    mapping(bytes4 => bool) private _supportedInterfaces;

    /// @notice Constructor that registers the interface of ERC165
    constructor() {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /// @notice Returns true if this contract implements the interface defined by `interfaceId`
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceId`, false otherwise
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /// @notice Registers the contract as an implementer of the interface defined by `interfaceId`
    /// @param interfaceId The interface identifier, which must not be 0xffffffff
    /// @dev This function can only be called by derived contracts.
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != _INTERFACE_ID_INVALID, "Invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '../lib/ExpressTerms.sol';
import '../lib/TermBase.sol';

contract Yuga_Term8 is TermBase, ExpressTerms {
    bytes4 private constant _INTERFACE_ID_TERM =
        bytes4(keccak256('term(Agreement)'));

    constructor() {
        _registerInterface(_INTERFACE_ID_TERM);
    }

    function name() external pure override returns (string memory) {
        return 'Miscellaneous';
    }

    function term(
        Agreement memory agreement
    ) public pure override returns (string memory) {
        return
            "**6. <u>Miscellaneous</u>**\n \n > i.  <u>Relationship; Indemnification.</u> Nothing in this License shall be construed as creating a joint venture, partnership, agency or employment relationship between the parties hereto. Except as specified herein, neither party shall have the right, power or implied authority to create any obligation or duty, express or implied, on behalf of the other party hereto. Licensee shall not directly or indirectly imply, state or otherwise cause any third party to believe or conclude that Licensor supports, endorses, or is responsible for any product or service that incorporates or uses, or any use of, in each case in whole or in part, the Mark(s). Licensee shall indemnify, defend and hold harmless Licensor from and against any and all actions, claim, causes of actions, proceedings, losses, damages and costs and expenses (including reasonable attorney's fees) arising out of our relating to Licensee's use of the Mark(s), including, but not limited to, any allegation that Licensee used the Mark(s) in connection with any actual or alleged infringement, misappropriation or violation of any third party's intellectual property rights.\n \n ";
    }
}