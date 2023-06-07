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

contract Yuga_Term9 is TermBase, ExpressTerms {
    bytes4 private constant _INTERFACE_ID_TERM =
        bytes4(keccak256('term(Agreement)'));

    constructor() {
        _registerInterface(_INTERFACE_ID_TERM);
    }

    function name() external pure override returns (string memory) {
        return 'Confidentiality';
    }

    function term(
        Agreement memory agreement
    ) public pure override returns (string memory) {
        return
            "<u>Confidentiality</u>. Licensee shall: (i) hold in confidence, protect, and safeguard the confidentiality of the terms and existence of this Agreement, which shall constitute the confidential information of Licensor, with at least the same degree of care as Licensee would protect its own confidential information, but in no event with less than a commercially reasonable degree of care; and (ii) not disclose the terms or existence of this Agreement without the prior written consent of Licensor to any person or entity, directly or indirectly, except to Licensee's employees who have a bona fide need to know such information to act on behalf of Licensee to perform its obligations under this Agreement, and who are bound by written nondisclosure and confidentiality obligations that are at least as restrictive as those herein. Upon request by Licensor, Licensee will indicate that its use of Licensee's Use in connection with the Licensed Activities is permitted by or under license from Licensor, using any legend or symbol and in such manner as Licensor may prescribe. If Licensee is required by applicable laws or legal process to disclose any the terms or existence of this Agreement, it shall, prior to making such disclosure, use best efforts to notify Licensor of such requirements to afford Licensor the opportunity to seek, at Licensor's cost and expense, a protective order or other remedy. Licensee will immediately notify Licensor's upon discovery or reasonable suspicion of any loss or unauthorized disclosure of the terms or existence of this Agreement. Licensee acknowledges that a breach of Sections ++1++, ++2++, ++3++, ++6(i)++, or ++6(ii)++ by Licensee would cause Licensor continuing and irreparable injury to its business which may not be adequately compensated for by monetary damages. Licensee therefore agrees that in the event of any actual or threatened breach of Sections ++1++, ++2++, ++3++, ++6(i)++, or ++6(ii)++, Licensor shall be entitled, in addition to any other remedies available to it, to a temporary restraining order and to preliminary and final injunctive relief against Licensee to prevent any violation or continuing violation of Sections ++1++, ++2++, ++3++, ++6(i)++, or ++6(ii)++. Failure to properly demand compliance or performance of any term of Sections ++1++, ++2++, ++3++, ++6(i)++, or ++6(ii)++ shall not constitute a waiver of Licensor's rights hereunder. \n \n >";
    }
}