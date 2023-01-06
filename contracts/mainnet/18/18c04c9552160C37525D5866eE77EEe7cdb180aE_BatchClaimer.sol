//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./interfaces/IMerkleDistributorNoAddress.sol";
import "./interfaces/IMerkleDistributor.sol";

struct ClaimData {
    address user;
    uint256 index;
    uint256 amount;
    address merkleContract;
    bytes32[] proof;
}

contract BatchClaimer {
    
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