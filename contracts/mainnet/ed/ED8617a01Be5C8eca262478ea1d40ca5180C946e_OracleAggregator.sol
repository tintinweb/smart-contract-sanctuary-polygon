// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OracleAggregator is Ownable{

    struct TokenInfo {
     uint8 decimals;
     bool dataSigned;
     address callAddress;
     bytes callData;
    }
 
    mapping(address => TokenInfo) internal tokensInfo;

    constructor() public {
        
    }

    function setTokenOracle(address token, address callAddress, uint8 decimals, bytes calldata callData, bool signed) external onlyOwner{
        require(callAddress != address(0),"OracleAggregator:: call address can not be zero");
        require(token != address(0),"OracleAggregator:: token address can not be zero");
        tokensInfo[token].callAddress = callAddress;
        tokensInfo[token].decimals = decimals;
        tokensInfo[token].callData = callData;
        tokensInfo[token].dataSigned = signed;
    }

    function getTokenOracleDecimals(address token) external view returns(uint8 _tokenOracleDecimals){
        _tokenOracleDecimals = tokensInfo[token].decimals;
    }

    function getTokenPrice(address token) external view returns (uint tokenPriceUnadjusted){
        tokenPriceUnadjusted =  _getTokenPrice(token);
    }

    function _getTokenPrice(address token) internal view returns (uint tokenPriceUnadjusted){
        (bool success, bytes memory ret) = tokensInfo[token].callAddress.staticcall(tokensInfo[token].callData);
        if (tokensInfo[token].dataSigned){
            tokenPriceUnadjusted = uint(abi.decode(ret,(int)));
        }
        else{
            tokenPriceUnadjusted = abi.decode(ret,(uint));
        }
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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