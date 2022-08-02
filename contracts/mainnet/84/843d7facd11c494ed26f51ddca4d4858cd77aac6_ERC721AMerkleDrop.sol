// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./ERC721A.sol";

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract ERC721AMerkleDrop is ERC721A, Ownable {
    bytes32 public root;

    constructor(
        string memory name,
        string memory symbol,
        bytes32 merkleroot
    ) ERC721A(name, symbol) {
        root = merkleroot;
    }

    mapping(address => bool) public mintcheck;

    // Caller can mint the only one nft in all time,
    // proof is the merkleproof which will ensure that caller is the whitelisted by the onwer and allowed to mint the tokens

    function PublicMint(bytes32[] calldata proof) external {
        uint256 quantity = 1;
        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender))),
            "Not whitelisted"
        );
        require(mintcheck[msg.sender] == false, "Already minted");
        _safeMint(msg.sender, quantity);
        mintcheck[msg.sender] = true;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Read Functions
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function isValid(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function checkleaf(address _addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    // /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Owner Executable
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // owner can update the merkle root at any time

    function updateMerkleroot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    // owner can update the URI

    function setBaseUri(string memory _baseuri) external onlyOwner {
        baseUri = _baseuri;
    }

    function setSuffix(string memory _suffix) external onlyOwner {
        suffix = _suffix;
    }
}