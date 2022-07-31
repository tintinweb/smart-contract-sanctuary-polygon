// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Ownable} from "./library/Ownable.sol";

interface IVault {
    function governance() external view returns (address);

    function token() external view returns (address);

    function initialize(
        address _token,
        address _governance,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        address _guardian
    ) external;
}

contract VaultCloneFactory is Ownable {
    event NewVault(address indexed token, address vault, address origVault);

    function _newProxyVault(
        address _token,
        address _governance,
        address _rewards,
        address _guardian,
        string memory _name,
        string memory _symbol,
        address _vaultToClone
    ) internal returns (address) {
        address vault;
        {
            require(_vaultToClone != address(0), "!Valid");
            require(IVault(_vaultToClone).token() != address(0), "!Vault");
            vault = _clone(_vaultToClone);
        }
        // NOTE: Must initialize the Vault atomically with deploying it
        IVault(vault).initialize(
            _token,
            _governance,
            _rewards,
            _name,
            _symbol,
            _guardian
        );

        emit NewVault(_token, vault, _vaultToClone); // To track and log the new address

        return vault;
    }

    /**
    @notice
        Create a new Vault for the given token using an original existing Vault as a 
        simple "forwarder-style" delegatecall proxy to this original Vault address.
    @dev
        Throws if _vaultToClone address is not valid or is not associated to a Vault.
    @param _token The token that may be deposited into the new Vault.
    @param _governance Vault governance.
    @param _guardian The address authorized for guardian interactions in the new Vault.
    @param _rewards The address to use for collecting rewards in the new Vault.
    @param _name Specify a custom Vault name. Set to empty string for default choice.
    @param _symbol Specify a custom Vault symbol name. Set to empty string for default choice.
    @return address of the newly-deployed Vault.
     */
    function newVault(
        address _token,
        address _governance,
        address _guardian,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        address _vaultToClone
    ) external onlyOwner returns (address) {
        address vault = _newProxyVault(
            _token,
            _governance,
            _rewards,
            _guardian,
            _name,
            _symbol,
            _vaultToClone
        );

        return vault;
    }

    function _clone(address _target) internal returns (address _newVault) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(_target));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            _newVault := create(0, clone_code, 0x37)
        }
    }
}

import {Context} from './Context.sol';

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}