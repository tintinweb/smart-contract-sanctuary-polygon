// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;
import "./libraries/MerkleProof.sol";
import "./imports/BoringFactory.sol";
import "./imports/BoringOwnable.sol";
interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;
}

interface INFTToken {
    function burnFrom(address from, uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract NFTLiquifier is BoringFactory, BoringOwnable {
    event LogFeeChanged(uint256 amount, address indexed feeCollector);
    event LogLiquified(uint256 tokenId, address indexed sender);
    event LogMakePotion(uint256 tokenId, address indexed sender);
    event LogFeesCollected(address indexed feeCollector, uint256 amount);
    mapping(string => INFTToken) public tokens;
    string[] public tokenAttributeNames;
    IERC721 public tokenContract;
    bytes32 public merkleRoot;
    string public ipfsURL;
    string private symbol;
    address public immutable masterContract;

    uint256 public fee;
    address payable public feeCollector;

    constructor (
        address _masterContract
    ) {
        masterContract = _masterContract;
    }

    function init(bytes calldata data) external payable {
        require(merkleRoot == bytes32(0));
        (IERC721 _tokenContract, bytes32 _merkleRoot, string memory _ipfsURL, string memory _symbol, address _owner) = abi.decode(data, (IERC721, bytes32, string, string, address));
        
        tokenContract = _tokenContract;
        merkleRoot = _merkleRoot;
        ipfsURL = _ipfsURL;
        symbol = _symbol;
        require(merkleRoot != bytes32(0));

        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function setFee(uint256 amount, address payable _feeCollector) external onlyOwner {
        fee = amount;
        feeCollector = _feeCollector;
        emit LogFeeChanged(amount, _feeCollector);
    }

    function liquify(uint256 tokenId, string[] memory attributes, bytes32[] calldata merkleProof) external payable {
        require(msg.value >= fee);
        verifyMerkleProof(tokenId, attributes, merkleProof);

        for (uint i; i < attributes.length; i++) {
            addToken(attributes[i], msg.sender);
        }

        tokenContract.transferFrom(msg.sender, address(this), tokenId);
        emit LogLiquified(tokenId, msg.sender);
    }

    function makePotion(uint256 tokenId, string[] memory attributes, bytes32[] calldata merkleProof) external payable {
        require(msg.value >= fee);
        verifyMerkleProof(tokenId, attributes, merkleProof);

        for (uint i; i < attributes.length; i++) {
            tokens[attributes[i]].burnFrom(msg.sender, 1e18);
        }

        tokenContract.transferFrom(address(this), msg.sender, tokenId);
        emit LogMakePotion(tokenId, msg.sender);
    }

    function verifyMerkleProof(uint256 tokenId, string[] memory attributes, bytes32[] calldata merkleProof) internal view {
        // verify the merkleRoot
        bytes32 node = keccak256(abi.encode(tokenId, attributes));

        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Liquifier: Invalid proof.');
    }

    function addToken(string memory name, address to) internal {
        INFTToken token = tokens[name];
        INFTToken nToken;
        if (address(token) == address(0)) {
            // New creation of token
            nToken = INFTToken(this.deploy(masterContract, abi.encode(name, string(abi.encodePacked(symbol, " ", name))), true));
            tokens[name] = nToken;
            tokenAttributeNames.push(name);
        } else {
            // Minting new liquid parts
            nToken = INFTToken(token);
        }
        nToken.mint(to, 1e18);
    }

    function collectFees() external {
        require(feeCollector != payable(0));
        uint256 balance = address(this).balance;
        feeCollector.transfer(balance);
        emit LogFeesCollected(feeCollector, balance);
    }

}

// SPDX-License-Identifier: MIT
// Dependency file: @openzeppelin/contracts/cryptography/MerkleProof.sol

// pragma solidity ^0.6.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
// see https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringFactory.sol
pragma solidity >= 0.8.9;
import "../interfaces/IMasterContract.sol";

// solhint-disable no-inline-assembly

contract BoringFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    /// @notice Deploys a given master Contract as a clone.
    /// Any ETH transferred with this call is forwarded to the new clone.
    /// Emits `LogDeploy`.
    /// @param masterContract The address of the contract to clone.
    /// @param data Additional abi encoded calldata that is passed to the new clone via `IMasterContract.init`.
    /// @param useCreate2 Creates the clone by using the CREATE2 opcode, in this case `data` will be used as salt.
    /// @return cloneAddress Address of the created clone contract.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        require(masterContract != address(0), "BoringFactory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.9;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.9;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}