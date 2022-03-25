/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;


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

contract Certificate is Ownable {
  
  struct Certification {
        bytes32 hash;
        uint time;
        uint blockNumber;
    }

    mapping (string => Certification[]) userToCertifications;
    mapping (bytes32 => string) hashToUser;
    
    event CertificateIssued(
        string indexed id,
        bytes32 hash,
        uint time
        );

    constructor () {
        transferOwnership(0x1Dd83E0883657DDd5c9F6a4BCA7e938321cBCcB0);
    }

    function issueCertificate(string memory _id, bytes32 _hash) public onlyOwner() onlyNotIssued(_hash){
        Certification memory certificate = Certification(_hash, block.timestamp, block.number);
        userToCertifications[_id].push(certificate);
        hashToUser[_hash] = _id;
        emit CertificateIssued(_id, _hash, block.timestamp);
    }

    function getCertifications(string memory _id) public view returns(Certification[] memory) {
        //return certifications[_id].hash;
        return userToCertifications[_id];
        
        
    }

    function verifyCertificate(string memory _id, bytes32 _hash) public view returns(Certification memory){
        Certification[] memory certificates_id = userToCertifications[_id];
        for (uint i = 0; i<certificates_id.length; i++){
            if (certificates_id[i].hash == _hash){
                return certificates_id[i];
            }
        }
        return Certification(0,0,0);
    }

    function verifyHash(bytes32 _hash) public view returns(Certification memory){
        string memory id = hashToUser[_hash];
        Certification[] memory certifications = userToCertifications[id];
        for ( uint i = 0; i<certifications.length; i++){
            if (certifications[i].hash == _hash){
                return certifications[i];
            }
        }
        return Certification(0,0,0);
    }

  modifier onlyNotIssued(bytes32 _hash) {
      require(keccak256(bytes(hashToUser[_hash])) == keccak256(""), "Error: Only hashes that have not been issued can be issued");
    _;
  }
}