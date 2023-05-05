/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/ChallengeFee/Context.sol

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


// File contracts/ChallengeFee/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/ChallengeFee/ChallengeFee.sol


pragma solidity ^0.8.16;

contract ChallengeFee is Ownable {
    /**
    * This struct represents various settings related to fees.
    * The BASE_FEE field represents the base fee, expressed as a percentage and divided by 100.
    * The TOKEN_FEE field represents the fee charged in the token being traded, measured in ETH.
    */
    struct Settings {
        uint256 BASE_FEE; // base fee divided by 100
        uint256 TOKEN_FEE; // token fee divided by 100
    }

    /**
    * Event to emit the amount of base fee and token fee charged for a transaction.
    * 
    * @param baseFee - The amount of base fee charged for the transaction.
    * @param tokenFee - The amount of token fee charged for the transaction.
    */
    event AmountFee (
        uint256 baseFee,
        uint256 tokenFee
    );
    // The SETTINGS variable holds the current settings for the contract.
    Settings public SETTINGS;
    
    /**
    * [description of the modifier]
    * @param _amountBaseFee [description of the parameter]
    * @param _amountTokenFee [description of the parameter]
    */
    modifier checkAmountFee(uint256 _amountBaseFee,uint256 _amountTokenFee) {
        require(_amountBaseFee >= 0 && _amountBaseFee < 100, "Amount base fee is not invalid");
        require(_amountTokenFee >= 0 && _amountTokenFee < 100, "Amount token fee is not invalid");
        _;
    }
    
    /**
    * @dev Contract constructor that sets the base fee and token fee amounts.
    * @param amountBaseFee The amount of the base fee to be set.
    * @param amountTokenFee The amount of the token fee to be set.
    * @notice The checkAmountFee modifier is applied to ensure that the amounts are valid.
    * Emits an AmountFee event with the new fee amounts.
    */
    constructor(uint256 amountBaseFee, uint256 amountTokenFee) checkAmountFee(amountBaseFee, amountTokenFee){
        SETTINGS.BASE_FEE = amountBaseFee; 
        SETTINGS.TOKEN_FEE = amountTokenFee;
        emit AmountFee(amountBaseFee, amountTokenFee);
    }
    
    /**
    * This function returns the current base fee.
    * It is an external view function, which means it can be called from outside the contract and does not modify the contract state.
    * @return The current base fee, expressed as a uint256.
    */
    function getBaseFee() external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }
    
    /**
    * This function returns the current token fee.
    * It is an external view function, which means it can be called from outside the contract and does not modify the contract state.
    * @return The current token fee, expressed as a uint256.
    */
    function getTokenFee() external view returns (uint256) {
        return SETTINGS.TOKEN_FEE;
    }
    
    /**
    * This function sets the base and token fees.
    * It is an external function that can only be called by the contract owner, as specified by the onlyOwner modifier.
    * @param _baseFee The new base fee, expressed as a uint256 divided by 100.
    * @param _tokenFee The new token fee, expressed as a uint256.
    */
    function setFees(
        uint256 _baseFee,
        uint256 _tokenFee
    ) external onlyOwner checkAmountFee(_baseFee, _tokenFee) {
        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.TOKEN_FEE = _tokenFee;
        emit AmountFee(_baseFee, _tokenFee);
    }
}