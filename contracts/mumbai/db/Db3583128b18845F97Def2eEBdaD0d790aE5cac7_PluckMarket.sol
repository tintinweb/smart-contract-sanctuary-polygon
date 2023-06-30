// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Pluck Market
// @author @fredricbohlin
// @version 1.2.2

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPluck {
  function getRoyaltyAccounts(uint256) external view returns (address[2] memory);

  function ownerOf(uint256) external view returns (address);

  function nonce(uint256) external view returns (uint256);

  function safeTransferFrom(
    address,
    address,
    uint256
  ) external;
}

contract PluckMarket is Ownable {
  string contractVersion = "1.2.2";
  address royaltyAccount;
  address nftContract;
  address priceSigner;

  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct SignatureTokenComponents {
    Signature signature;
    address seller;
    uint256 deadline;
    uint256 price;
    uint256 tokenId;
    uint256 nonce;
  }

  struct SignatureInsuranceComponents {
    Signature signature;
    string insuranceProviderId;
    uint256 insurancePrice;
  }

  event ItemSale(uint256 indexed tokenId, address buyer);

  event RoyaltyPayment(uint256 indexed tokenId, address userAccount, address portalAccount, uint256 userValue, uint256 portalValue);

  event InsurancePayment(string insuranceProviderId, uint256 amountAvailable, uint256 insurancePrice, uint256 tokenId);

  event InsurancePaymentFailure(string insuranceProviderId, uint256 amountAvailable, uint256 insurancePrice, uint256 tokenId, string message);

  mapping(string => address) public versionToAddress;

  function registerVersion(string memory _version, address _contractAddress) external onlyOwner {
    require(_contractAddress != address(0), "Invalid contract address");

    versionToAddress[_version] = _contractAddress;
  }

  function getAddressByVersion(string memory _version) public view returns (address) {
    if (keccak256(abi.encodePacked(_version)) == keccak256(abi.encodePacked(contractVersion))) {
      return address(this);
    }

    address contractAddress = versionToAddress[_version];
    require(contractAddress != address(0), "No contract address found for the given version");

    return contractAddress;
  }

  function getPriceSigner() external view returns (address account) {
    return priceSigner;
  }

  function setPriceSigner(address _account) external onlyOwner {
    priceSigner = _account;
  }

  function getRoyaltyAccount() external view returns (address account) {
    return royaltyAccount;
  }

  function setRoyaltyAccount(address _account) external onlyOwner {
    royaltyAccount = _account;
  }

  function setNftContract(address _account) external onlyOwner {
    nftContract = _account;
  }

  function getNftContract() external view returns (address account) {
    return nftContract;
  }

  function buy(
    Signature memory _signature,
    address _nftContract,
    address _seller,
    uint256 _deadline,
    uint256 _price,
    uint256 _tokenId,
    uint256 _nonce
  ) external payable {
    buy(_signature, _nftContract, _seller, _deadline, _price, _tokenId, _nonce, "1.2.0", 0, "", Signature(0, 0, 0));
  }

  function buy(
    Signature memory _signature,
    address _nftContract,
    address _seller,
    uint256 _deadline,
    uint256 _price,
    uint256 _tokenId,
    uint256 _nonce,
    string memory _contractVersion
  ) external payable {
    buy(_signature, _nftContract, _seller, _deadline, _price, _tokenId, _nonce, _contractVersion, 0, "", Signature(0, 0, 0));
  }

  function buy(
    Signature memory _signature,
    address _nftContract,
    address _seller,
    uint256 _deadline,
    uint256 _price,
    uint256 _tokenId,
    uint256 _nonce,
    string memory _contractVersion,
    uint256 _insuranceAmount,
    string memory _insuranceProviderId,
    Signature memory _insuranceSignature
  ) public payable {
    require(msg.value >= _price, "MarketBuy: Not enough funds were sent in transaction");
    require(_nftContract == nftContract, "MarketBuy: Wrong NFT contract supplied");
    require(_seller == IPluck(_nftContract).ownerOf(_tokenId), "MarketBuy: Seller is not owner");
    require(_nonce == IPluck(_nftContract).nonce(_tokenId), "MarketBuy: Nonce does not match");

    SignatureTokenComponents memory _signatureComponents = SignatureTokenComponents({
      signature: _signature,
      seller: _seller,
      deadline: _deadline,
      price: _price,
      tokenId: _tokenId,
      nonce: _nonce
    });

    require(checkTokenTicket(_signatureComponents, _contractVersion), "MarketBuy: Sale listing is not valid");

    address[2] memory _accounts = IPluck(_nftContract).getRoyaltyAccounts(_tokenId);
    uint256 _remainingTokenPriceAmount = payRoyalites(_price, _seller, _tokenId, _accounts);

    payable(_seller).transfer(_remainingTokenPriceAmount);

    IPluck(_nftContract).safeTransferFrom(_seller, msg.sender, _tokenId);

    emit ItemSale(_tokenId, msg.sender);

    if (_insuranceAmount > 0) {
      insure(_tokenId, _insuranceProviderId, (msg.value - _price), _insuranceAmount, _insuranceSignature);
    }
  }

  function payRoyalites(
    uint256 _price,
    address _seller,
    uint256 _tokenId,
    address[2] memory _accounts
  ) private returns (uint256 _remainingAmount) {
    uint256 _royaltyPart = (_price * 25) / 1000;
    uint256 _roy1 = _royaltyPart;
    uint256 _roy2 = _royaltyPart;
    uint256 _roy3 = _royaltyPart + _royaltyPart;
    uint256 _tot = _price - _roy1 - _roy2 - _roy3;

    if (_accounts[0] == _accounts[1]) {
      _roy2 = _roy2 + _roy1;
    } else if (_accounts[0] == royaltyAccount) {
      _roy3 = _roy3 + _roy1;
    } else if (_accounts[0] == _seller) {
      _tot = _tot + _roy1;
    } else {
      payable(_accounts[0]).transfer(_roy1);
    }
    if (_accounts[1] == royaltyAccount) {
      _roy3 = _roy3 + _roy2;
    } else if (_accounts[0] == _seller) {
      _tot = _tot + _roy2;
    } else {
      payable(_accounts[1]).transfer(_roy2);
    }
    if (royaltyAccount == _seller) {
      _tot = _tot + _roy3;
    } else {
      payable(royaltyAccount).transfer(_roy3);
    }

    emit RoyaltyPayment(_tokenId, _accounts[0], _accounts[1], _royaltyPart, _royaltyPart);

    return _tot;
  }

  function buyInsurance(
    uint256 _tokenId,
    string memory _insuranceProviderId,
    uint256 _insuranceAmount,
    Signature memory _insuranceSignature
  ) external payable {
    require(_insuranceAmount > 0, "MarketBuyInsurance: Insurance amount must be greater than 0");
    require(_insuranceAmount <= msg.value, "MarketBuyInsurance: Not enough funds were sent in transaction");

    insure(_tokenId, _insuranceProviderId, msg.value, _insuranceAmount, _insuranceSignature);
  }

  function insure(
    uint256 _tokenId,
    string memory _insuranceProviderId,
    uint256 _amountAvailable,
    uint256 _insurancePrice,
    Signature memory _insuranceSignature
  ) private {
    if (_insurancePrice <= 0) {
      emit InsurancePaymentFailure(_insuranceProviderId, _amountAvailable, _insurancePrice, _tokenId, "Insurance amount must be greater than 0");
    }

    if (_insurancePrice > _amountAvailable) {
      emit InsurancePaymentFailure(_insuranceProviderId, _amountAvailable, _insurancePrice, _tokenId, "Not enough funds were sent in transaction");
    }

    SignatureInsuranceComponents memory _signatureComponents = SignatureInsuranceComponents({
      signature: _insuranceSignature,
      insuranceProviderId: _insuranceProviderId,
      insurancePrice: _insurancePrice
    });

    if (checkInsuranceTicket(_signatureComponents)) {
      emit InsurancePayment(_insuranceProviderId, _amountAvailable, _insurancePrice, _tokenId);
    } else {
      emit InsurancePaymentFailure(_insuranceProviderId, _amountAvailable, _insurancePrice, _tokenId, "Invalid signature");
    }
  }

  function checkTokenTicket(SignatureTokenComponents memory _signatureComponents, string memory _contractVersion)
    private
    view
    returns (bool isValid)
  {
    require(block.timestamp < _signatureComponents.deadline, "Signed transaction expired");

    address _contractAddress = getAddressByVersion(_contractVersion);

    require(_contractAddress != address(0), "Invalid contract address in check");

    bytes32 _eip712DomainHash = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("PluckMarket")),
        keccak256(bytes(_contractVersion)),
        block.chainid,
        address(_contractAddress)
      )
    );

    bytes32 _hashStruct = keccak256(
      abi.encode(
        keccak256("Ticket(address seller,uint256 price,uint256 deadline,uint256 tokenId,uint256 nonce)"),
        _signatureComponents.seller,
        _signatureComponents.price,
        _signatureComponents.deadline,
        _signatureComponents.tokenId,
        _signatureComponents.nonce
      )
    );

    bytes32 _hash = keccak256(abi.encodePacked("\x19\x01", _eip712DomainHash, _hashStruct));
    address _signer = ecrecover(_hash, _signatureComponents.signature.v, _signatureComponents.signature.r, _signatureComponents.signature.s);

    require(_signer == _signatureComponents.seller || _signer == priceSigner, "CheckTokenTicket: Invalid signature");
    require(_signer != address(0), "ECDSA: invalid signature");

    return true;
  }

  function checkInsuranceTicket(SignatureInsuranceComponents memory _signatureComponents) private view returns (bool insuranceIsValid) {
    address _contractAddress = address(this);

    bytes32 _eip712DomainHash = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("PluckMarket")),
        keccak256(bytes(contractVersion)),
        block.chainid,
        address(_contractAddress)
      )
    );

    bytes32 _hashStruct = keccak256(
      abi.encode(
        keccak256("Ticket(string insuranceProviderId,uint256 insurancePrice)"),
        _signatureComponents.insuranceProviderId,
        _signatureComponents.insurancePrice
      )
    );

    bytes32 _hash = keccak256(abi.encodePacked("\x19\x01", _eip712DomainHash, _hashStruct));
    address _signer = ecrecover(_hash, _signatureComponents.signature.v, _signatureComponents.signature.r, _signatureComponents.signature.s);

    if (_signer != owner() || _signer == address(0)) {
      return false;
    }

    return true;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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