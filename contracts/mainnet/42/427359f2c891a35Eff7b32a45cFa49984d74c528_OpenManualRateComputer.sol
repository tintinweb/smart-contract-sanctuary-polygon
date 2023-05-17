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
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";

import "../IRateComputer.sol";

/**
 * @title ManualRateComputer
 * @notice A base contract that computes rates based on manual input.
 * @dev This contract is meant to be inherited by a more specific implementation that provides access control.
 *      The checkSetRate function must be implemented in the inheriting contract to enforce access control.
 */
abstract contract ManualRateComputer is IERC165, IRateComputer {
    /// @notice A struct to store rate and timestamp.
    struct Rate {
        uint64 rate;
        uint32 timestamp;
    }

    /// @notice A mapping to store rates for tokens.
    mapping(address => Rate) internal rates;

    /// @notice Custom error for when the rate is not set.
    /// @param token The address of the token that does not have a rate set.
    error RateNotSet(address token);

    /**
     * @notice Computes the rate for a token.
     * @param token The address of the token to compute the rate for.
     * @return rate The rate for the token.
     * @dev Reverts with RateNotSet error if the rate for the token is not set.
     */
    function computeRate(address token) external view override returns (uint64) {
        Rate storage rate = rates[token];
        if (rate.timestamp == 0) {
            revert RateNotSet(token);
        }

        return rate.rate;
    }

    /**
     * @notice Manually sets the rate for a token.
     * @dev This function must be called by an authorized entity. Access control is enforced by the checkSetRate
     * function.
     * @param token The address of the token to set the rate for.
     * @param rate The rate to set for the token.
     */
    function setRate(address token, uint64 rate) external {
        checkSetRate();

        rates[token] = Rate(rate, uint32(block.timestamp));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRateComputer).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice A function that checks whether the caller is authorized to set rates.
     * @dev This function must be implemented in the inheriting contract to enforce access control.
     */
    function checkSetRate() internal view virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IRateComputer
 * @notice An interface that defines a contract that computes rates.
 */
interface IRateComputer {
    /// @notice Computes the rate for a token.
    /// @param token The address of the token to compute the rate for.
    /// @return rate The rate for the token.
    function computeRate(address token) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../../rates/computers/ManualRateComputer.sol";

/// @title OpenManualRateComputer
/// @dev This is a demo contract that allows anyone to set the rate. Do not use in production.
contract OpenManualRateComputer is ManualRateComputer {
    function checkSetRate() internal view virtual override {
        // Allow anyone to set the rate}
    }
}