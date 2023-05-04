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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IERC721Token.sol";

contract ERC721TokenFactory is Ownable {
  error InvalidAddress();
  error InsufficientFee();
  error TransferFailed();

  event ERC721TokenDeployed(
    address _erc721TokenClone,
    address indexed _creator,
    address indexed _erc721TokenImpl
  );

  event ERC721SoulboundTokenDeployed(
    address _erc721SoulboundTokenClone,
    address indexed _creator,
    address indexed _erc721SoulboundTokenImpl
  );

  event Withdrawal(address _feeTreasury, uint256 _amount);

  event ERC721TokenImplSet(
    address _oldERC721TokenImpl,
    address _newERC721TokenImpl
  );

  event ERC721SoulboundTokenImplSet(
    address _oldERC721SoulboundTokenImpl,
    address _newERC721SoulboundTokenImpl
  );

  event FeeSet(uint256 _oldFee, uint256 _newFee);

  event FeeTreasurySet(address _oldFeeTreasury, address _newFeeTreasury);

  enum TokenType {
    ERC721Token,
    ERC721SoulboundToken
  }

  address public erc721TokenImpl;

  address public erc721SoulboundTokenImpl;

  uint256 public fee;

  address public feeTreasury;

  constructor(
    address _erc721TokenImpl,
    address _erc721SoulboundTokenImpl,
    uint256 _fee,
    address _feeTreasury
  ) {
    if (
      _erc721TokenImpl == address(0) ||
      _erc721SoulboundTokenImpl == address(0) ||
      _feeTreasury == address(0)
    ) revert InvalidAddress();

    erc721TokenImpl = _erc721TokenImpl;
    erc721SoulboundTokenImpl = _erc721SoulboundTokenImpl;
    fee = _fee;
    feeTreasury = _feeTreasury;
  }

  function deployERC721Token(
    TokenType _tokenType,
    string memory _name,
    string memory _symbol,
    string memory contractURI_,
    string memory tokenURI_,
    address _trustedAddress,
    uint256 _maxSupply,
    uint256 _saltNonce
  ) external payable returns (address) {
    if (msg.value != fee * _maxSupply) revert InsufficientFee();

    address erc721TokenClone = Clones.cloneDeterministic(
      _tokenType == TokenType.ERC721Token
        ? erc721TokenImpl
        : erc721SoulboundTokenImpl,
      keccak256(
        abi.encodePacked(
          _name,
          _symbol,
          contractURI_,
          tokenURI_,
          msg.sender,
          _trustedAddress,
          _maxSupply,
          _saltNonce
        )
      )
    );
    IERC721Token(erc721TokenClone).initialize(
      _name,
      _symbol,
      contractURI_,
      tokenURI_,
      msg.sender,
      _trustedAddress,
      _maxSupply
    );

    if (_tokenType == TokenType.ERC721Token) {
      emit ERC721TokenDeployed(erc721TokenClone, msg.sender, erc721TokenImpl);
    } else {
      emit ERC721SoulboundTokenDeployed(
        erc721TokenClone,
        msg.sender,
        erc721SoulboundTokenImpl
      );
    }

    return erc721TokenClone;
  }

  function setERC721TokenImplAddress(
    address _erc721TokenImpl
  ) external onlyOwner {
    if (_erc721TokenImpl == address(0)) revert InvalidAddress();
    address _oldERC721TokenImpl = erc721TokenImpl;
    erc721TokenImpl = _erc721TokenImpl;
    emit ERC721TokenImplSet(_oldERC721TokenImpl, _erc721TokenImpl);
  }

  function setERC721SoulboundTokenImplAddress(
    address _erc721SoulboundTokenImpl
  ) external onlyOwner {
    if (_erc721SoulboundTokenImpl == address(0)) revert InvalidAddress();
    address _oldERC721SoulboundTokenImpl = erc721SoulboundTokenImpl;
    erc721SoulboundTokenImpl = _erc721SoulboundTokenImpl;
    emit ERC721SoulboundTokenImplSet(
      _oldERC721SoulboundTokenImpl,
      _erc721SoulboundTokenImpl
    );
  }

  function setFee(uint256 _fee) external onlyOwner {
    uint256 _oldFee = fee;
    fee = _fee;
    emit FeeSet(_oldFee, _fee);
  }

  function setFeeTreasury(address _feeTreasury) external onlyOwner {
    if (_feeTreasury == address(0)) revert InvalidAddress();
    address _oldFeeTreasury = feeTreasury;
    feeTreasury = _feeTreasury;
    emit FeeTreasurySet(_oldFeeTreasury, _feeTreasury);
  }

  function withdraw() external {
    uint256 balance = address(this).balance;

    if (balance > 0) {
      address _feeTreasury = feeTreasury;

      (bool success, ) = _feeTreasury.call{value: balance}("");
      if (!success) revert TransferFailed();

      emit Withdrawal(_feeTreasury, balance);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Token {
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory contractURI_,
    string memory tokenURI_,
    address _owner,
    address _trustedAddress,
    uint256 _maxSupply
  ) external;
}