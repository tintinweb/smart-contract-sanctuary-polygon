// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SoundProofBaseStorage {
    /// @notice SoundProof NFT Info
    struct SoundProofNFTInfo {
        /// NFT Owner
        address nftOwner;
        /// Is Approve
        bool isApprove;
        /// Is Public
        bool isPublic;
    }

    /// @notice SoundProof Owner Structure
    struct SoundProofNFTOwnership {
        /// Owner Address
        address ownerAddress;
        /// Owned Percentage, e.x: 5000 => 50%
        uint256 ownedPercentage;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./ISoundProofBase.sol";

/**
 * SoundProof Utils Interface
 */
abstract contract ISoundProofUtils is SoundProofBaseStorage {
    function checkOwnedPercentage(SoundProofNFTOwnership[] memory ownerList) public pure virtual returns (bool);
    function stringToBytes32(string memory str) public pure virtual returns (bytes32 result);
    function stringToBytes(string memory str) public pure virtual returns (bytes memory);
    function recoverSigner(bytes32 message, bytes memory signature) public pure virtual returns(address);
    function recoverSignerWithRVS(bytes32 message, bytes32 r, bytes32 s, uint8 v) public pure virtual returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Interface/ISoundProofUtils.sol";

/**
 * SoundProof Utils Contract
 */
contract SoundProofUtils is ISoundProofUtils {
    function checkOwnedPercentage(SoundProofNFTOwnership[] memory ownerList) public pure override returns (bool) {
        uint256 sumOfOwnedPercentage = 0;
        for (uint i = 0; i < ownerList.length; i += 1) {
            sumOfOwnedPercentage += ownerList[i].ownedPercentage;
        }

        return sumOfOwnedPercentage == 10000;
    }

    function stringToBytes32(string memory str) public pure override returns (bytes32) {
        bytes memory temp = abi.encodePacked(str);
        require(temp.length <= 32, "Invalid input length");

        if (temp.length == 0) {
            return 0x0;
        }

        bytes32 result;
        assembly {
            result := mload(add(temp, 32))
        }
        return result;
    }

    function stringToBytes(string memory str) public pure override returns (bytes memory) {
        return abi.encodePacked(str);
    }

    function recoverSigner(bytes32 message, bytes memory signature) public pure override returns(address) {
        bytes32 r; bytes32 s; uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return address(0);
        }

        // Extract the signature parameters
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Check the v value
        if (v < 27) {
            v += 27;
        }

        // Recover the signer address
        address signer = ecrecover(message, v, r, s);

        return signer;
    }

    function recoverSignerWithRVS(bytes32 message, bytes32 r, bytes32 s, uint8 v) public pure override returns(address) {
        return ecrecover(message, v, r, s);
    }
}