// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IERC20Mintable {
	function mint(address to, uint256 amount) external;
}

contract MerkleClaim {

	/// ============ Immutable storage ============

	/// @notice ERC20-claimee inclusion root
	bytes32 public immutable merkleRoot;

	/// @notice ERC20 token address to be airdropped
	address public immutable erc20Token;

	/// ============ Mutable storage ============

	/// @notice Mapping of addresses who have claimed tokens
	mapping(address => bool) public hasClaimed;

	/// ============ Errors ============

	/// @notice Thrown if address has already claimed
	error AlreadyClaimed();
	/// @notice Thrown if address/amount are not part of Merkle tree
	error NotInMerkle();

	/// ============ Constructor ============

	/// @notice Creates a new MerkleClaimERC20 contract
	/// @param _erc20Token token to airdrop
	/// @param _merkleRoot of claimees
	constructor(
	address _erc20Token,
	bytes32 _merkleRoot
	) {
	merkleRoot = _merkleRoot; // Update root
	erc20Token = _erc20Token; // Update token
	}

	/// ============ Events ============

	/// @notice Emitted after a successful token claim
	/// @param to recipient of claim
	/// @param amount of tokens claimed
	event Claim(address indexed to, uint256 amount);

	/// ============ Functions ============

	function verify(address to, uint256 amount, bytes32[] calldata proof, bytes32 root) external pure returns(bool){

		// Verify merkle proof, or revert if not in tree
		bytes32 leaf = keccak256(abi.encodePacked(to, amount));
		// bool isValidLeaf = MerkleProof.verify(proof, root, leaf);

		bytes32 temp = leaf;
		uint i;

		for(i=0; i<proof.length; i++) {
			temp = pairHash(temp, proof[i]);
		}

		bool isValidLeaf = temp == root;

		return isValidLeaf;
	}

	/// @notice Allows claiming tokens if address is part of merkle tree
	/// @param to address of claimee
	/// @param amount of tokens owed to claimee
	/// @param proof merkle proof to prove address and amount are in tree
	function claim(address to, uint256 amount, bytes32[] calldata proof) external {
	// Throw if address has already claimed tokens
	if (hasClaimed[to]) revert AlreadyClaimed();

	// Verify merkle proof, or revert if not in tree
	bool isValidLeaf = this.verify(to, amount, proof, merkleRoot);
	if (!isValidLeaf) revert NotInMerkle();

	// Set address to claimed
	hasClaimed[to] = true;

	// Mint tokens to address
	IERC20Mintable(erc20Token).mint(to, amount);

	// Emit claim event
	emit Claim(to, amount);
	}

	function hash(bytes32 _a) internal pure returns(bytes32) {
      return bytes32(keccak256(abi.encode(_a)));
    }

    function pairHash(bytes32 _a, bytes32 _b) internal pure returns(bytes32) {
      return hash(hash(_a) ^ hash(_b));
    }

}