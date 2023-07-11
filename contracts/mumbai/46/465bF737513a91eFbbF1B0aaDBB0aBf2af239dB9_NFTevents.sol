// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTevents is Ownable {
    mapping(address => bool) private whitelistedBrand;
    event Transfer(
        address indexed contractAddress,
        address indexed _from,
        address indexed _to,
        uint256 _tokenId,
        string _brandName
    );
    event Approval(
        address indexed contractAddress,
        address indexed _owner,
        address indexed _to,
        uint256 _tokenId,
        string _brandName
    );
    event ApprovalForAll(
        address indexed contractAddress,
        address indexed _owner,
        address indexed _to,
        bool _approved,
        string _brandName
    );
    modifier onlyWhitelisted() {
        require(
            whitelistedBrand[msg.sender] == true,
            "Events: Caller not whitelisted!"
        );
        _;
    }

    constructor(){
        
    }

    function whitelistBrandContract(address _address) public onlyOwner {
        require(
            whitelistedBrand[_address] == false,
            "Events: Brand already whitelisted!"
        );
        whitelistedBrand[_address] = true;
    }

    function removeWhitelistBrandContrac(address _address) public onlyOwner {
        require(whitelistedBrand[_address] == true, "Brand does not Exists!");
        whitelistedBrand[_address] = false;
    }

    function transferEvent(
        address _from,
        address _to,
        uint256 _tokenId,
        string memory _brandName
    ) public onlyWhitelisted {
        emit Transfer(msg.sender, _from, _to, _tokenId, _brandName);
    }

    function approvalForAllEvent(
        address _owner,
        address _to,
        bool _approved,
        string memory _brandName
    ) public onlyWhitelisted {
        emit ApprovalForAll(msg.sender, _owner, _to, _approved, _brandName);
    }

    function approvalEvent(
        address _owner,
        address _to,
        uint256 _tokenId,
        string memory _brandName
    ) public onlyWhitelisted {
        emit Approval(msg.sender, _owner, _to, _tokenId, _brandName);
    }

    function checkIfWhitelisted(address _address) public view returns (bool) {
        return whitelistedBrand[_address];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}