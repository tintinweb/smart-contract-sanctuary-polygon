pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

import "../../contract/childchain/DeCashChildBridge.sol";

contract ChildUSDDBridge is DeCashChildBridge {
    constructor(address _storage) DeCashChildBridge(_storage) {}
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

import "../interfaces/DeCashStorageInterface.sol";

/// @title Base settings / modifiers for each contract in DeCash Token (Credits David Rugendyke/Rocket Pool)
/// @author Shadowy Coders

abstract contract DeCashBase {
    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    DeCashStorageInterface internal _decashStorage =
        DeCashStorageInterface(address(0));

    /**
     * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
     */
    modifier onlyLatestContract(
        string memory _contractName,
        address _contractAddress
    ) {
        require(
            _contractAddress ==
                _getAddress(
                    keccak256(
                        abi.encodePacked("contract.address", _contractName)
                    )
                ),
            "Invalid or outdated contract"
        );
        _;
    }

    modifier onlyOwner() {
        require(_isOwner(msg.sender), "Account is not the owner");
        _;
    }
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "Account is not an admin");
        _;
    }
    modifier onlySuperUser() {
        require(_isSuperUser(msg.sender), "Account is not a super user");
        _;
    }
    modifier onlyDelegator(address _address) {
        require(_isDelegator(_address), "Account is not a delegator");
        _;
    }
    modifier onlyFeeRecipient(address _address) {
        require(_isFeeRecipient(_address), "Account is not a fee recipient");
        _;
    }
    modifier onlyRole(string memory _role) {
        require(_roleHas(_role, msg.sender), "Account does not match the role");
        _;
    }

    /// @dev Set the main DeCash Storage address
    constructor(address _decashStorageAddress) {
        // Update the contract address
        _decashStorage = DeCashStorageInterface(_decashStorageAddress);
    }

    function isOwner(address _address) external view returns (bool) {
        return _isOwner(_address);
    }

    function isAdmin(address _address) external view returns (bool) {
        return _isAdmin(_address);
    }

    function isSuperUser(address _address) external view returns (bool) {
        return _isSuperUser(_address);
    }

    function isDelegator(address _address) external view returns (bool) {
        return _isDelegator(_address);
    }

    function isFeeRecipient(address _address) external view returns (bool) {
        return _isFeeRecipient(_address);
    }

    function isBlacklisted(address _address) external view returns (bool) {
        return _isBlacklisted(_address);
    }

    /// @dev Get the address of a network contract by name
    function _getContractAddress(string memory _contractName)
        internal
        view
        returns (address)
    {
        // Get the current contract address
        address contractAddress = _getAddress(
            keccak256(abi.encodePacked("contract.address", _contractName))
        );
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }

    /// @dev Get the name of a network contract by address
    function _getContractName(address _contractAddress)
        internal
        view
        returns (string memory)
    {
        // Get the contract name
        string memory contractName = _getString(
            keccak256(abi.encodePacked("contract.name", _contractAddress))
        );
        // Check it
        require(
            keccak256(abi.encodePacked(contractName)) !=
                keccak256(abi.encodePacked("")),
            "Contract not found"
        );
        // Return
        return contractName;
    }

    /// @dev Role Management
    function _roleHas(string memory _role, address _address)
        internal
        view
        returns (bool)
    {
        return
            _getBool(
                keccak256(abi.encodePacked("access.role", _role, _address))
            );
    }

    function _isOwner(address _address) internal view returns (bool) {
        return _roleHas("owner", _address);
    }

    function _isAdmin(address _address) internal view returns (bool) {
        return _roleHas("admin", _address);
    }

    function _isSuperUser(address _address) internal view returns (bool) {
        return _roleHas("admin", _address) || _isOwner(_address);
    }

    function _isDelegator(address _address) internal view returns (bool) {
        return _roleHas("delegator", _address) || _isOwner(_address);
    }

    function _isFeeRecipient(address _address) internal view returns (bool) {
        return _roleHas("fee", _address) || _isOwner(_address);
    }

    function _isBlacklisted(address _address) internal view returns (bool) {
        return _roleHas("blacklisted", _address) && !_isOwner(_address);
    }

    /// @dev Storage get methods
    function _getAddress(bytes32 _key) internal view returns (address) {
        return _decashStorage.getAddress(_key);
    }

    function _getUint(bytes32 _key) internal view returns (uint256) {
        return _decashStorage.getUint(_key);
    }

    function _getString(bytes32 _key) internal view returns (string memory) {
        return _decashStorage.getString(_key);
    }

    function _getBytes(bytes32 _key) internal view returns (bytes memory) {
        return _decashStorage.getBytes(_key);
    }

    function _getBool(bytes32 _key) internal view returns (bool) {
        return _decashStorage.getBool(_key);
    }

    function _getInt(bytes32 _key) internal view returns (int256) {
        return _decashStorage.getInt(_key);
    }

    function _getBytes32(bytes32 _key) internal view returns (bytes32) {
        return _decashStorage.getBytes32(_key);
    }

    function _getAddressS(string memory _key) internal view returns (address) {
        return _decashStorage.getAddress(keccak256(abi.encodePacked(_key)));
    }

    function _getUintS(string memory _key) internal view returns (uint256) {
        return _decashStorage.getUint(keccak256(abi.encodePacked(_key)));
    }

    function _getStringS(string memory _key)
        internal
        view
        returns (string memory)
    {
        return _decashStorage.getString(keccak256(abi.encodePacked(_key)));
    }

    function _getBytesS(string memory _key)
        internal
        view
        returns (bytes memory)
    {
        return _decashStorage.getBytes(keccak256(abi.encodePacked(_key)));
    }

    function _getBoolS(string memory _key) internal view returns (bool) {
        return _decashStorage.getBool(keccak256(abi.encodePacked(_key)));
    }

    function _getIntS(string memory _key) internal view returns (int256) {
        return _decashStorage.getInt(keccak256(abi.encodePacked(_key)));
    }

    function _getBytes32S(string memory _key) internal view returns (bytes32) {
        return _decashStorage.getBytes32(keccak256(abi.encodePacked(_key)));
    }

    /// @dev Storage set methods
    function _setAddress(bytes32 _key, address _value) internal {
        _decashStorage.setAddress(_key, _value);
    }

    function _setUint(bytes32 _key, uint256 _value) internal {
        _decashStorage.setUint(_key, _value);
    }

    function _setString(bytes32 _key, string memory _value) internal {
        _decashStorage.setString(_key, _value);
    }

    function _setBytes(bytes32 _key, bytes memory _value) internal {
        _decashStorage.setBytes(_key, _value);
    }

    function _setBool(bytes32 _key, bool _value) internal {
        _decashStorage.setBool(_key, _value);
    }

    function _setInt(bytes32 _key, int256 _value) internal {
        _decashStorage.setInt(_key, _value);
    }

    function _setBytes32(bytes32 _key, bytes32 _value) internal {
        _decashStorage.setBytes32(_key, _value);
    }

    function _setAddressS(string memory _key, address _value) internal {
        _decashStorage.setAddress(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setUintS(string memory _key, uint256 _value) internal {
        _decashStorage.setUint(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setStringS(string memory _key, string memory _value) internal {
        _decashStorage.setString(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBytesS(string memory _key, bytes memory _value) internal {
        _decashStorage.setBytes(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBoolS(string memory _key, bool _value) internal {
        _decashStorage.setBool(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setIntS(string memory _key, int256 _value) internal {
        _decashStorage.setInt(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBytes32S(string memory _key, bytes32 _value) internal {
        _decashStorage.setBytes32(keccak256(abi.encodePacked(_key)), _value);
    }

    /// @dev Storage delete methods
    function _deleteAddress(bytes32 _key) internal {
        _decashStorage.deleteAddress(_key);
    }

    function _deleteUint(bytes32 _key) internal {
        _decashStorage.deleteUint(_key);
    }

    function _deleteString(bytes32 _key) internal {
        _decashStorage.deleteString(_key);
    }

    function _deleteBytes(bytes32 _key) internal {
        _decashStorage.deleteBytes(_key);
    }

    function _deleteBool(bytes32 _key) internal {
        _decashStorage.deleteBool(_key);
    }

    function _deleteInt(bytes32 _key) internal {
        _decashStorage.deleteInt(_key);
    }

    function _deleteBytes32(bytes32 _key) internal {
        _decashStorage.deleteBytes32(_key);
    }

    function _deleteAddressS(string memory _key) internal {
        _decashStorage.deleteAddress(keccak256(abi.encodePacked(_key)));
    }

    function _deleteUintS(string memory _key) internal {
        _decashStorage.deleteUint(keccak256(abi.encodePacked(_key)));
    }

    function _deleteStringS(string memory _key) internal {
        _decashStorage.deleteString(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBytesS(string memory _key) internal {
        _decashStorage.deleteBytes(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBoolS(string memory _key) internal {
        _decashStorage.deleteBool(keccak256(abi.encodePacked(_key)));
    }

    function _deleteIntS(string memory _key) internal {
        _decashStorage.deleteInt(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBytes32S(string memory _key) internal {
        _decashStorage.deleteBytes32(keccak256(abi.encodePacked(_key)));
    }
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

/// @title DeCashChildBridge implementation based on the DeCash perpetual storage
/// @author Shadowy Coders

import "../../lib/NativeMetaTransaction.sol";
import { DeCashBase } from "./../DeCashBase.sol";
import { FeeMetaTransaction } from "../../lib/FeeMetaTransaction.sol";

contract DeCashChildBridge is DeCashBase, FeeMetaTransaction {
  bytes4 private constant withdrawFunctionSignature =
    bytes4(keccak256("withdraw(uint256)"));

  // Construct
  constructor(address _decashStorageAddress) DeCashBase(_decashStorageAddress) {
    _initializeEIP712("DeCashChildBridge");
    version = 1;
  }

  function withdrawViaSignature(
    FeeStruct calldata feeStruct,
    SigStruct calldata sigFee,
    uint256 exitAmount,
    SigStruct calldata sigExit
  )
    external
    onlyDelegator(msg.sender)
    onlyFeeRecipient(feeStruct.feeRecipient)
    onlyLatestContract("bridge", address(this))
  {
    address childTokenAddress = _getAddress(
      keccak256(abi.encodePacked("contract.address", "proxy"))
    );

    _executeFeePayment(feeStruct, sigFee, sigExit, childTokenAddress);

    // exit
    NativeMetaTransaction childToken = NativeMetaTransaction(childTokenAddress);
    childToken.executeMetaTransaction(
      feeStruct.from,
      abi.encodeWithSelector(withdrawFunctionSignature, bytes32(exitAmount)),
      sigExit.r,
      sigExit.s,
      sigExit.v
    );
  }
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

interface DeCashStorageInterface {
    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function transferMany(address[] calldata _tos, uint256[] calldata _values)
        external
        returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function mint(address _to, uint256 _value) external returns (bool);

    function burn(uint256 _value) external returns (bool);

    function burnFrom(address _from, uint256 _value) external returns (bool);
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT

import {EIP712Base} from "./EIP712Base.sol";

contract BaseMetaTransaction is EIP712Base {

    mapping(address => uint256) nonces;

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT

import "./../interfaces/token/ERC20.sol";

import { BaseMetaTransaction } from "./BaseMetaTransaction.sol";
import { SafeMath } from "./SafeMath.sol";

contract FeeMetaTransaction is BaseMetaTransaction {
  using SafeMath for uint256;

  bytes32 private constant FEESTRUCT_TYPEHASH =
    keccak256(
      "FeeStruct(uint256 nonce,address from,uint256 fee,address feeRecipient,bytes32 linkedHash,uint256 deadline)"
    );
  bytes32 private constant SIGSTRUCT_TYPEHASH =
    keccak256("SigStruct(bytes32 r,bytes32 s,uint8 v)");

  bytes32 private constant WITHDRAWSTRUCT_TYPEHASH =
    keccak256("WithdrawStruct(address user,uint256 amount)");

  event FeePaid(address userAddress, address feeAddress, uint256 amount);

  struct FeeStruct {
    uint256 nonce;
    address from;
    uint256 fee;
    address feeRecipient;
    bytes32 linkedHash;
    uint256 deadline;
  }

  struct SigStruct {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  struct WithdrawStruct {
    address user;
    uint256 amount;
  }

  function _executeFeePayment(
    FeeStruct calldata feeStruct,
    SigStruct calldata sigFee,
    SigStruct calldata sigLinked,
    address tokenAddress
  ) internal {
    require(
      verify(feeStruct, sigFee, _hashStruct(sigLinked)),
      "Invalid Signature"
    );

    _updateAndTransfer(feeStruct, tokenAddress);
  }

  function _executeFeePayment(
    FeeStruct calldata feeStruct,
    SigStruct calldata sigFee,
    WithdrawStruct memory withdrawLinked,
    address tokenAddress
  ) internal {
    require(
      verify(feeStruct, sigFee, _hashStruct(withdrawLinked)),
      "Invalid Signature"
    );

    _updateAndTransfer(feeStruct, tokenAddress);
  }

  function _updateAndTransfer(
    FeeStruct calldata feeStruct,
    address tokenAddress
  ) internal {
    // increase nonce for user (to avoid re-use)

    nonces[feeStruct.from] = nonces[feeStruct.from].add(1);

    emit FeePaid(feeStruct.from, feeStruct.feeRecipient, feeStruct.fee);

    // execute fee payment
    ERC20 token = ERC20(tokenAddress);
    require(
      token.transferFrom(feeStruct.from, feeStruct.feeRecipient, feeStruct.fee),
      "Fee payment not successful"
    );
  }

  function _hashStruct(FeeStruct calldata feeStruct)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          FEESTRUCT_TYPEHASH,
          feeStruct.nonce,
          feeStruct.from,
          feeStruct.fee,
          feeStruct.feeRecipient,
          feeStruct.linkedHash,
          feeStruct.deadline
        )
      );
  }

  function _hashStruct(SigStruct calldata sigStruct)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(SIGSTRUCT_TYPEHASH, sigStruct.r, sigStruct.s, sigStruct.v)
      );
  }

  function _hashStruct(WithdrawStruct memory withdrawStruct)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          WITHDRAWSTRUCT_TYPEHASH,
          withdrawStruct.user,
          withdrawStruct.amount
        )
      );
  }

  function verify(
    FeeStruct calldata feeStruct,
    SigStruct calldata sigFee,
    bytes32 hashStruct
  ) internal view returns (bool) {
    require(block.timestamp <= feeStruct.deadline, "Request expired");
    require(feeStruct.linkedHash == hashStruct, "Invalid linked transaction");
    require(feeStruct.from != address(0), "Invalid signer");
    require(feeStruct.nonce == getNonce(feeStruct.from), "Invalid nonce");
    return (feeStruct.from ==
      ecrecover(
        toTypedMessageHash(_hashStruct(feeStruct)),
        sigFee.v,
        sigFee.r,
        sigFee.s
      ));
  }
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT

import {BaseMetaTransaction} from "./BaseMetaTransaction.sol";
import {SafeMath} from "./SafeMath.sol";

contract NativeMetaTransaction is BaseMetaTransaction {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

pragma solidity 0.8.15;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}