// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {IValidator} from "./IValidator.sol";

contract NoValidator is IValidator {

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error WrongIPFSLength();

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Validate Post
    /// @param _ipfs The IPFS Hash
    function validate(address, string calldata _ipfs) external pure returns (bool) {
        bytes memory _ipfsBytes = bytes(_ipfs);
        if (_ipfsBytes.length != 46) {
            revert WrongIPFSLength();
        }
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

interface IValidator {
    function validate(address _user, string calldata _ipfs) external returns (bool);
}