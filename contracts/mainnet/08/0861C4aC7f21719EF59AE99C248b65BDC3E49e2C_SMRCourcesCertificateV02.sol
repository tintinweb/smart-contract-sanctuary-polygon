// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SMRCertificateV02.sol";

contract SMRCourcesCertificateV02 is  SMRCertificateV02 {
    constructor() SMRCertificateV02("TEST - Cources Certificate", "SMRCRS", "Cources") {

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface ISMRCertificateV02 {

    struct Cert {
        uint256 id;
        // who issued
        address issuer;
        // recipient
        address user;
        string uri;
        uint256 issuingDate;
        uint256 acceptanceDate;        
        // data imprint
        string imprint;
        // signature
        bytes signature;
    }

    // backward compatibility
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // certificate is issued
    event Issue(address indexed from, address indexed to, uint256 indexed tokenId);
    // certificate is accepted , nft is minted
    event Attest(address indexed to, uint256 indexed tokenId);
    // certificate is revoked by the issuer. nft has not been minted yet
    event Revoke(address indexed from, uint256 indexed tokenId);
    // certificate is remove, nft removed as well
    event Burn(address indexed from, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);


    function revoke(uint256 tokenId) external;

    function issue(address to, string calldata uri, string calldata imprint, bytes calldata signature) external returns (uint256);

    function attest(address to, string calldata uri, string calldata imprint, bytes calldata signature) external returns (uint256);

    function take(uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function totalReserve() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function status(uint256 tokenId) external view returns (string memory);  

    function certificateDetails(uint256 tokenId) external view returns (Cert memory); 

    // global certification , namespace like Training Platform, Education , Courses, Personal identification, 
    function category() external view returns (string memory);
    
    // version of the certificate platform : v0.0.1, v0.1, v1, etc
    function version() external pure returns (string memory);    
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

interface IERC721Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
//import "./interfaces/ISMRCertificate.sol";

import {ISMRCertificateV02} from "./interfaces/ISMRCertificateV02.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";


abstract contract SMRCertificateV02 is ERC165, IERC721Metadata, ISMRCertificateV02 {
    string private _category;
    string private constant _version = "v02";
    using Counters for Counters.Counter;
    Counters.Counter private _attestCounter;
    Counters.Counter private _reserveCounter;    
    address private _owner;
    address private _service;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances; 
   // mapping for all certificates
    mapping (uint256 => Cert) certificate;

    string private constant _notExistStatus = "not_exist";
    string private constant _reservedStatus = "reserved";
    string private constant _acceptedStatus = "accepted"; 


  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(ISMRCertificateV02).interfaceId ||
      super.supportsInterface(interfaceId);
  }    

    modifier onlyOwner() {
       require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    modifier onlyService() {
       require(service() == msg.sender, "caller is not the authorized service");
        _;
    }    

    constructor(string memory name_, string memory symbol_ , string memory category_) {
      _owner = msg.sender;
      _category = category_;
      _name = name_;
      _symbol = symbol_;
    }

    function issue(address to, string calldata uri, string calldata imprint, bytes calldata signature) external override onlyService returns (uint256) {
      uint256 _tokenId = _issueCertificate (to, uri, imprint, signature);
      emit Issue(certificate[_tokenId].issuer, certificate[_tokenId].user, _tokenId);
      _reserveCounter.increment();      
         // emit events
      return _tokenId;
    }

    function attest(address to, string calldata uri, string calldata imprint, bytes calldata signature) external override onlyService returns (uint256) {
      uint256 _tokenId = _issueCertificate (to, uri, imprint, signature);
      emit Issue(certificate[_tokenId].issuer, certificate[_tokenId].user, _tokenId);

      // assigned date
      certificate[_tokenId].acceptanceDate = block.timestamp;
      // mint nft token
      _mint(to, _tokenId);
      _attestCounter.increment();
      // emit event
      emit Attest(to, _tokenId);
      return _tokenId;
    }
    

    function take(uint256 tokenId) external override  {
      // certificate is not issued, ivalid token ud
      require(certificate[tokenId].user != address(0), "no certificate found");
      require(!_exists(tokenId), "certificate already issued and accepted");          
      require(certificate[tokenId].user == msg.sender, "certificate is addressed for another user");

      certificate[tokenId].acceptanceDate = block.timestamp;

      // mint nft token
      _mint(msg.sender, tokenId);
      _attestCounter.increment();
      // decrement pending
      if (_reserveCounter.current() > 0) _reserveCounter.decrement();
      emit Attest(msg.sender, tokenId);
    }


    function revoke(uint256 tokenId) external override {
      require(certificate[tokenId].user != address(0), "no certificate found");
      // if accepted, then only burn is applicable by the owner
      require(!_exists(tokenId), "certificate already issued and accepted");

      // if issuser wants to revoke certificate from the service, then msg.sender == service, and tx.origin = issuer
      // else issuer = msg.sender
      address _initiator = msg.sender;
      if (service() == msg.sender){
        _initiator = tx.origin;
      }

      address _user = certificate[tokenId].user;
      require(certificate[tokenId].issuer == _initiator, "only issuer of the certificate can revoke it");
      delete certificate[tokenId];
      // decrement pending
      if (_reserveCounter.current() > 0) _reserveCounter.decrement();
      // emit events
      emit Revoke(_user, tokenId);

    } 

    function burn(uint256 tokenId) override external {
      require(certificate[tokenId].user != address(0), "no certificate found");
      require(_exists(tokenId), "certificate is not accepted");            
      require(certificate[tokenId].user ==  msg.sender, "only owner of the token can burn it");

      unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[msg.sender] -= 1;
      }
      delete _owners[tokenId];
      // delete certificate model
      delete certificate[tokenId];

      // decrement minted
      if (_attestCounter.current() > 0) _attestCounter.decrement();
      // emit events
      emit Transfer(msg.sender, address(0), tokenId);            
      emit Burn(msg.sender, tokenId);

    }       

    function _issueCertificate (address _to, string calldata _uri, string calldata _imprint, bytes calldata _signature) private returns (uint256) {
      address _issuer = tx.origin;
      require(_issuer != _to, "Not allowed to give a certificate to oneself");
      uint256 _issuingDate = block.timestamp;
      bytes32 _hash = _buildCertHash(_to, _uri);
      uint256 _tokenId = uint256(_hash);
      // issued and accepted
      require(!_exists(_tokenId), "certificate already issued and accepted");
      // just issued but not accepted
      require(certificate[_tokenId].user == address(0), "certificate already issued");

      Cert memory cert = Cert ({
        id: _tokenId,
        issuer: _issuer,
        user: _to,
        uri: _uri,
        issuingDate: _issuingDate,
        acceptanceDate: 0,
        imprint : _imprint,
        signature : _signature

      });
      // put certificate to storage
      certificate[_tokenId] = cert;

      return _tokenId;
    } 

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }    

    function status(uint256 tokenId) view override virtual external returns (string memory) {
      if (_exists(tokenId)) 
        return _acceptedStatus;
      else if  (certificate[tokenId].user != address(0)) 
        return _reservedStatus;
      else return _notExistStatus;
    } 


    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        require(_exists(tokenId), "invalid token ID");
        return certificate[tokenId].uri;
    }

    function balanceOf(address user) public view virtual override returns (uint256) {
        require(user != address(0), "balanceOf: address zero is not a valid owner");
        return _balances[user];
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address user = _owners[tokenId];
        require(user != address(0), "ownerOf: token doesn't exist");
        return user;
    }    

    function certificateDetails(uint256 tokenId) external override view returns (Cert memory) {
        return certificate[tokenId];
    }	       

    function category() view override external returns (string memory) {
        return _category;
    }             

    function version() pure override external returns (string memory) {
        return _version;
    }

    function totalReserve() external view override returns (uint256) {
      return _reserveCounter.current();
    } 

    function totalSupply() external view override returns (uint256) {
      return _attestCounter.current();
    }    

    function _buildCertHash(address _to, string calldata _uri) internal virtual returns (bytes32){
      return keccak256(abi.encodePacked(_to, _uri, address(this)));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal virtual returns (uint256) {
        require(!_exists(tokenId), "tokenID already exists");
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function service() public view virtual returns (address) {
        return _service;
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _owner = newOwner;
    }

    function setService(address newService) public virtual onlyOwner {
        require(newService != address(0), "New service is the zero address");
        _service = newService;
    } 

}