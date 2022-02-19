/**
 *Submitted for verification at polygonscan.com on 2022-02-19
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: all-code/hive/Hive...Crowdsale.sol


pragma solidity ^0.8.7;


interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Crowdsale {

    IERC20 HONEY;
    IERC20 DAI;
    address owner;

    constructor(address _honey, address _dai) {
        HONEY = IERC20(_honey);
        DAI = IERC20(_dai);
        owner = msg.sender;
    }

    event BuyHoney(address sender, uint aHNY, uint DAIPaid);
    event Redeem(address sender, uint amount);

    mapping(address => uint) public aHNYBalance;
    uint public HNYPrice = 100 * 1e18;

    bool public isRedeemLocked = true;
    uint public aHNYReserve;
    uint public HNYReserve;
    uint public maxCap = 50 * 1e18;
    mapping(address => uint) public totalRedeemed;

    modifier onlyIfUnlocked() {
        require(!isRedeemLocked, "Redeem is currently locked!");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyWhitelisted(bytes32[] calldata merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not a whitelisted address");
        _;
    }


    function buy(uint quantity, bytes32[] calldata proof) public onlyWhitelisted(proof) {
        require(quantity % 10 == 0, "Quantity should be multiples of 10");
        uint amount = quantity * HNYPrice;

        require(aHNYBalanceOf(msg.sender)+(quantity * 1e18) <= maxCap, "Quantity exceeding max cap");
        require(DAI.balanceOf(msg.sender) >= amount, "Insufficient DAI balance");
        require(amount <= aHNYReserve, "Insufficient aHNY balance");
        
        DAI.transferFrom(msg.sender, address(this), amount);
        aHNYBalance[msg.sender] += quantity * 1e18;
        aHNYReserve -= amount;
        emit BuyHoney(msg.sender, quantity, amount);
    }

    function redeem(uint amount, bytes32[] calldata proof) public onlyIfUnlocked onlyWhitelisted(proof) {
        uint balance = aHNYBalance[msg.sender];
        require(balance >= amount, "Insufficient aHNY balance to redeem");

        aHNYBalance[msg.sender] -= amount;
        HNYReserve -= amount;
        totalRedeemed[msg.sender] += amount;
        HONEY.transfer(msg.sender, amount);

        emit Redeem(msg.sender, amount);
    }

    function setRedeemLock(bool _value) public onlyOwner {
        isRedeemLocked = _value;
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

    function aHNYDeposit(uint amount) public onlyOwner {
        aHNYReserve += amount;
    }

    function aHNYBalanceOf(address _addr) public view returns(uint) {
        return aHNYBalance[_addr];
    }

    function totalHNYRedeemed(address _addr) public view returns(uint) {
        return totalRedeemed[_addr];
    }

    function HNYDeposit(uint amount) public onlyOwner {
        require(HONEY.balanceOf(msg.sender) >= amount, "Insufficient token balance to deposit!");
        HONEY.transferFrom(msg.sender, address(this), amount);
        HNYReserve += amount;
    }

    bytes32 public merkleRoot = 0x74f4666169faccda89a45d47ab1997a62f24c3cd534a01539db8f0e40d3eb8b1;


    function updateMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function transferOwnership(address OnwerAddress) public onlyOwner{
        owner = OnwerAddress;
    }

    function Owner() public view returns(address){
        return owner;
    }
}