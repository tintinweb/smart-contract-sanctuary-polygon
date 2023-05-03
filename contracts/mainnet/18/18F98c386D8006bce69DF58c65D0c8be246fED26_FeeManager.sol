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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is Ownable {
    uint32 constant MAX_PERCENT = 100_00000;
    address public systemAddress;
    mapping(address => uint256) private _transferFeePercentMap;
    mapping(address => uint256) private _swapFeePercentMap;
    mapping(address => bool) private _addressForCallWhitelist;

    constructor() {
        systemAddress = owner();
    }

    /**
     * @dev Function for only owner
     * @param _newSystemAddress New system address
     */
    function changeSystemAddress(address _newSystemAddress) public onlyOwner {
        systemAddress = _newSystemAddress;
    }

    /**
     * @dev Function for only owner
     * @param _currencyAddress Currency address (address(0) if currency is native)
     * @param _feePercent Fee percent in format 10_00000 <-> 10.00000 %
     */
    function changeTransferFeePercent(
        address _currencyAddress,
        uint256 _feePercent
    ) public onlyOwner {
        require(_feePercent <= MAX_PERCENT, "Incorrect percent");
        _transferFeePercentMap[_currencyAddress] = _feePercent;
    }

    /**
     * @param _currencyAddress Currency address (address(0) if currency is native)
     * @param _feePercent Fee percent in format 10_00000 <-> 10.00000 %
     */
    function changeSwapFeePercent(address _currencyAddress, uint256 _feePercent)
        public
        onlyOwner
    {
        require(_feePercent <= MAX_PERCENT, "Incorrect percent");
        _swapFeePercentMap[_currencyAddress] = _feePercent;
    }

    /**
     * @dev Function for only owner
     * @param _address Contract address for `call` function execution
     * @param _approveAddressForCall Status about whether the call function can be started (if true -- yes)
     */
    function changeAddressWhitelistedForCallApprove(
        address _address,
        bool _approveAddressForCall
    ) public onlyOwner {
        _addressForCallWhitelist[_address] = _approveAddressForCall;
    }

    /**
     * @param _currencyAddress Currency address (address(0) if currency is native)
     * @param amount Amount of tokens or native currency
     * @return Fee by transfer tokens or native currency
     */
    function getTransferFee(address _currencyAddress, uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            getQuantityByTotalAndPercent(
                amount,
                _transferFeePercentMap[_currencyAddress]
            );
    }

    /**
     * @param _currencyAddress Currency address (address(0) if currency is native)
     * @param amount Amount of tokens or native currency
     * @return Fee by swap tokens or native currency
     */
    function getSwapFee(address _currencyAddress, uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            getQuantityByTotalAndPercent(
                amount,
                _swapFeePercentMap[_currencyAddress]
            );
    }

    /**
     * @param _currencyAddress Currency address (address(0) if currency is native)
     * @param amount Expected amount of tokens or native currency
     * @return Amount plus fee that the user has to pay for transfer
     */
    function getTransferTokensAmountWithFee(
        address _currencyAddress,
        uint256 amount
    ) public view returns (uint256) {
        uint256 fee = getTransferFee(_currencyAddress, amount);
        return fee + amount;
    }

    /**
     * @param _currencyAddress Currency address (address(0) if currency is native)
     * @param amount Expected amount of tokens or native currency
     * @return Amount plus fee that the user has to pay for swap
     */
    function getSwapTokensAmountWithFee(
        address _currencyAddress,
        uint256 amount
    ) public view returns (uint256) {
        uint256 fee = getSwapFee(_currencyAddress, amount);
        return fee + amount;
    }

    /**
     * @param _address Contract address
     * @return Return the status (if true - yes) that the `call` to address function can be running
     */
    function isAddressWhitelistedForCall(address _address)
        public
        view
        returns (bool)
    {
        return _addressForCallWhitelist[_address];
    }

    /**
     * @dev Get a percentage of a number
     * @param totalCount Amount
     * @param percent Percent in format 10_00000 <-> 10.00000 %
     * @return Return percentage of a `totalCount`
     */
    function getQuantityByTotalAndPercent(uint256 totalCount, uint256 percent)
        public
        pure
        returns (uint256)
    {
        if (percent == 0) return 0;
        require(percent <= MAX_PERCENT, "Incorrect percent");
        return (totalCount * percent) / MAX_PERCENT;
    }
}