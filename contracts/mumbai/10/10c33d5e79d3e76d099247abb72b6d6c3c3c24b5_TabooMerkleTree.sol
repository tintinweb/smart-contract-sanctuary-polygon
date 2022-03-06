/**
 *Submitted for verification at polygonscan.com on 2022-03-05
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: staking.sol



// Edited By LAx
/**

*/

pragma solidity >=0.7.0 <0.9.0;




interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}
interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;
}


contract TabooMerkleTree is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IERC721 public nftAddress ;
    IERC20 public tokenAddress ;   //usdt mainnet 0xdAC17F958D2ee523a2206206994597C13D831ec7
    address [] investers;
    

  bytes32 public merkleRoot = 0x8bef28f0ac54da10614be726622f54ce02e3736d8f100ee126f3bfed268ef0ef;

//max claiming per user rounds  
//uint public MaxClaimAmount = 10;
  //mapping variables checking if already claimed
    mapping(address => bool) public whitelistClaimed ;
  //mapping variables checking NFT amount per wallet
   uint256 public amountClaimed ;
        // Store each nft apy(ntfId->apy)
    mapping(address => uint256) public nftAmount;


   constructor( address  _nft,   address _tokenAddress ) {
     nftAddress = IERC721(_nft) ;
     tokenAddress= IERC20(_tokenAddress);
     initAmount();
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIdCounter.current();
  }

 function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public {
    uint256 amount = nftAmount[msg.sender];
    // Verify whitelist requirements
    require(!whitelistClaimed[msg.sender], "Address already claimed!");
    require(_mintAmount <= amount, "Max amount exceeded" );
//    require (_mintAmount <= MaxClaimAmount , "Max amount exceeded") ;     
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
 

    whitelistClaimed[msg.sender] = true;
    investers.push(msg.sender) ; // to reset mapping
    _mintLoop(msg.sender, _mintAmount);
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

    function setNftAddress(IERC721 _nftAddress) public onlyOwner {
    nftAddress = _nftAddress;
  }

     function setTokenAddress(IERC20 _tokenAddress) public onlyOwner {
    tokenAddress = _tokenAddress;
  }

  //   function setMaxAmount(uint _claimAmount) public onlyOwner {
  //   MaxClaimAmount = _claimAmount;
  // }

  function resetBalance() public onlyOwner {
    for (uint i=0; i< investers.length ; i++){
        whitelistClaimed[investers[i]] = false;
    }
  }

    function usdtBalance(address _to) public view returns (uint256) {
          return tokenAddress.balanceOf(_to);
    }


  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      _tokenIdCounter.increment();
         uint256 tokenId = _tokenIdCounter.current();
         //transfer nft to claimer
          nftAddress.transferFrom(owner(), _receiver,tokenId) ;       
         //send usdt
        tokenAddress.transferFrom(owner(), _receiver, 2);  //to change to real amount
     amountClaimed+=1 ;
    }
  }

      function setAmountByClaimer(address _claimer, uint256 _amount) public onlyOwner {
        require(_amount > 0, "nft and amount must > 0");
        nftAmount[_claimer] = _amount;
    }


  function initAmount() internal onlyOwner {
        nftAmount[0x479eec2Ed1Da9Ec2e8467EF1DC72fd9cE848e1C3] = 5;
        nftAmount[0x562C2435a6692f1801d140482A05194D6D388254] = 3;
        nftAmount[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = 2;
    
    }

}