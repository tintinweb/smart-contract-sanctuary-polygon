/**
 *Submitted for verification at polygonscan.com on 2022-07-22
*/

// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI NELGetter Contracts

// File: contracts/INEL.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the NEL
 */
interface INEL {

    /**
     * @dev Returns the current tax rate.
     */
    function tax() external view returns(uint8);

    /**
     * @dev Returns the mintAddLimit.
     */
    function mintAddLimit() external view returns(uint8);

    /**
     * @dev Returns the sum of mint limits.
     */
    function mintLimitSum() external view returns(uint);

    /**
     * @dev Returns the mint limit of an address.
     */
    function mintLimitOf(address _address) external view returns(uint);

    /**
     * @dev Returns whether an address is an issuer or not.
     */
    function isIssuer(address _address) external view returns(bool);

    /**
     * @dev Returns whether an address is in the blacklist or not.
     */
    function blackList(address _address) external view returns(bool);

    /**
     * @dev Returns the amount after deducting tax.
     */
    function checkTax(uint _amount) external view returns(uint);

    /**
     * @dev Changes the tax rate of NEL.
     */
    function changeTax(uint8 _newTax) external returns(bool);

    /**
     * @dev Changes the mintAddLimit.
     */
    function changeMintAddLimit(uint8 _newLimit) external returns(bool);

    /**
     * @dev Changes the mint limit of an address.
     */
    function changeMintLimit(address _address, uint _amount) external returns(bool);

    /**
     * @dev Changes the mint limit of an address.
     */
    function changeBlackList(address _address, bool _bool) external returns(bool);

    /**
     * @dev Lets an issuer mint new CRDIT within its limit.
     */
    function issuerMint(address _to, uint256 _amount) external returns(bool);

    /**
     * @dev Lets an issuer burn NEL to recover its limit.
     */
    function issuerBurn(uint256 _amount) external returns(bool);

    /**
     * @dev Burns NEL.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Burns NEL from its owner.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Returns the cap of the token.
     */
    function cap() external view returns (uint256);
}
// File: contracts/utils/Context.sol


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
// File: contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// File: contracts/NelGetter.sol


// ATSUSHI MANDAI CRDIT Contracts

pragma solidity ^0.8.0;



/// @title NEL
/// @author Atsushi Mandai
/// @notice Basic functions of the ERC20 Token NEL.
contract NELGetter is Ownable {

    /**
     * @dev Emits this event when faucet mints
     */
    event MintToken(address to, uint256 amount);

    /**
     * @dev Amount of NEL a user could mint with Faucet.
     */ 
    uint256 public faucetAmount = 2 * (10**uint256(18));

    /**
     * @dev Address of NEL Token.
     */ 
    address public AddressNEL;

    /**
     * @dev User must wait until the cooldownTime to use nelFaucet function.
     */ 
    mapping(address => uint256) public cooldownTime;

    /**
     * @dev Changes the faucetAmount.
     */ 
    function changeFaucetAmount(uint256 _amount) public onlyOwner {
        faucetAmount = _amount;
    }

    /**
    * @dev Changes AddressNEL.
    */ 
    function changeAddressNEL(address _address) public onlyOwner {
        AddressNEL = _address;
    }

    /**
     * @dev Lets a user mint new NEL.
     */
    function nelFaucet() public returns(bool) {
        require(block.timestamp > cooldownTime[_msgSender()], "Still in the cooldown time.");
        cooldownTime[_msgSender()] = block.timestamp + 1 days;
        INEL token = INEL(AddressNEL);
        bool value = token.issuerMint(_msgSender(), faucetAmount);
        if (value == true) {
            emit MintToken(_msgSender(), faucetAmount);
        } else {
            emit MintToken(_msgSender(), 0);
        }
        return value;
    }

}