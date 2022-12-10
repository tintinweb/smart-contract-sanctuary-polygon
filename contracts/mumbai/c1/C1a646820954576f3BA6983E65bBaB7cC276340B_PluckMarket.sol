// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
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
  address royaltyAccount;
  address nftContract;
  address priceSigner;

  event ItemSold(uint256 indexed tokenId, address buyer);

  event RoyaltyPayment(
    uint256 indexed tokenId,
    address userAccount,
    address portalAccount,
    uint256 userValue,
    uint256 portalValue
  );

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
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address _nftContract,
    address _seller,
    uint256 _deadline,
    uint256 _price,
    uint256 _tokenId,
    uint256 _nonce
  ) external payable {
    require(_price == msg.value, "MarketBuy: Price is not price");
    require(_nftContract == nftContract, "MarketBuy: Contract is not contract");
    require(_seller == IPluck(_nftContract).ownerOf(_tokenId), "MarketBuy: Seller is not seller");
    require(_nonce == IPluck(_nftContract).nonce(_tokenId), "MarketBuy: Nonce is not nonce");

    require(
      checkTicket(_v, _r, _s, _seller, _deadline, _price, _tokenId, _nonce),
      "MarketBuy: Sale listing is not valid"
    );

    uint256 _royaltyAmount = (msg.value * 25) / 1000;
    uint256 _roy1 = _royaltyAmount;
    uint256 _roy2 = _royaltyAmount;
    uint256 _roy3 = _royaltyAmount + _royaltyAmount;
    uint256 _tot = msg.value - _roy1 - _roy2 - _roy3;

    address[2] memory _accounts = IPluck(_nftContract).getRoyaltyAccounts(_tokenId);

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

    payable(_seller).transfer(_tot);

    emit RoyaltyPayment(_tokenId, _accounts[0], _accounts[1], _royaltyAmount, _royaltyAmount);

    IPluck(_nftContract).safeTransferFrom(_seller, msg.sender, _tokenId);

    emit ItemSold(_tokenId, msg.sender);
  }

  function checkTicket(
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address _seller,
    uint256 _deadline,
    uint256 _price,
    uint256 _tokenId,
    uint256 _nonce
  ) internal view returns (bool isValid) {
    require(block.timestamp < _deadline, "Signed transaction expired");

    bytes32 _eip712DomainHash = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("PluckMarket")),
        keccak256(bytes("1.1.0")),
        block.chainid,
        address(this)
      )
    );

    bytes32 _hashStruct = keccak256(
      abi.encode(
        keccak256("Ticket(address seller,uint256 price,uint256 deadline,uint256 tokenId,uint256 nonce)"),
        _seller,
        _price,
        _deadline,
        _tokenId,
        _nonce
      )
    );

    bytes32 _hash = keccak256(abi.encodePacked("\x19\x01", _eip712DomainHash, _hashStruct));
    address _signer = ecrecover(_hash, _v, _r, _s);

    require(_signer == _seller || _signer == priceSigner, "MyFunction: invalid signature");
    require(_signer != address(0), "ECDSA: invalid signature");

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