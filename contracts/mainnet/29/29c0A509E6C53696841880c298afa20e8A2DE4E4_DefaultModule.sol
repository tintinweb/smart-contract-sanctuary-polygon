// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../modules/IModule.sol";
import "../Utils.sol";

/// @title Cyan Wallet Default Module - Forwards all transactions.
/// @author Bulgantamir Gankhuyag - <[email protected]>
/// @author Naranbayar Uuganbayar - <[email protected]>
contract DefaultModule is IModule {
    /// @inheritdoc IModule
    function handleTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) external payable override returns (bytes memory) {
        return Utils._execute(to, value, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IModule {
    /// @notice Executes given transaction data to given address.
    /// @param to Target contract address.
    /// @param value Value of the given transaction.
    /// @param data Calldata of the transaction.
    /// @return Result of the execution.
    function handleTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Utils {
    /// @notice Executes a transaction to the given address.
    /// @param to Target address.
    /// @param value Native token value to be sent to the address.
    /// @param data Data to be sent to the address.
    /// @return Result of the transaciton.
    function _execute(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bytes memory) {
        assembly {
            let success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /// @notice Recover signer address from signature.
    /// @param signedHash Arbitrary length data signed on the behalf of the wallet.
    /// @param signature Signature byte array associated with signedHash.
    /// @return Recovered signer address.
    function recoverSigner(bytes32 signedHash, bytes memory signature) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        require(v == 27 || v == 28, "Bad v value in signature.");

        address recoveredAddress = ecrecover(signedHash, v, r, s);
        require(recoveredAddress != address(0), "ecrecover returned 0.");
        return recoveredAddress;
    }

    /// @notice Helper method to parse the function selector from data.
    /// @param data Any data to be parsed, mostly calldata of transaction.
    /// @return result Parsed function sighash.
    function parseFunctionSelector(bytes memory data) internal pure returns (bytes4 result) {
        require(data.length >= 4, "Invalid data.");
        assembly {
            result := mload(add(data, 0x20))
        }
    }

    /// @notice Parse uint256 from given data.
    /// @param data Any data to be parsed, mostly calldata of transaction.
    /// @param position Position in the data.
    /// @return result Uint256 parsed from given data.
    function getUint256At(bytes memory data, uint8 position) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(data, add(position, 0x20)))
        }
    }
}