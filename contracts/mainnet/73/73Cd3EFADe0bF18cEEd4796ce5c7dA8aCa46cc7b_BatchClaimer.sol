// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./interfaces/IMerkleDistributorNoAddress.sol";
import "./interfaces/IMerkleDistributor.sol";

struct ClaimData {
    address user;
    uint256 index;
    uint256 amount;
    address merkleContract;
    bytes32[] proof;
}

contract BatchClaimer is ERC2771Context{

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder){}
    
    function batchClaim(
        address[] memory user,
        uint256[] memory index,
        uint256[] memory amount,
        address[] memory merkleContract,
        bytes32[][] memory proof
    ) public {
        uint256 counter = 0;
        for (uint256 i = 0; i < user.length; i++) {
            IMerkleDistributor merkleDistributor = IMerkleDistributor(merkleContract[i]);
            
            if(!merkleDistributor.isClaimed(index[i])){
                merkleDistributor.claim(index[i], user[i], amount[i], proof[i]);
                counter+=1;
            }
        }
    }

    function batchClaimNoAddress(
        address[] memory user,
        uint256[] memory index,
        uint256[] memory id,
        uint256[] memory amount,
        address[] memory merkleContract,
        bytes32[][] memory proof
    ) public {
        uint256 counter = 0;
        for (uint256 i = 0; i < user.length; i++) {
            IMerkleDistributorNoAddress merkleDistributor = IMerkleDistributorNoAddress(merkleContract[i]);
            
            if(!merkleDistributor.isClaimed(index[i])){
                merkleDistributor.claim(id[i], user[i], index[i], amount[i], proof[i]);
                counter+=1;
            }
        }
    }

    function versionRecipient() external pure returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributorNoAddress {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 id, address account, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}