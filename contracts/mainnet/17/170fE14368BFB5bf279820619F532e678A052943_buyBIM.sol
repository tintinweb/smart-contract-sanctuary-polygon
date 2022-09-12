// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract buyBIM is Ownable {

    bool public USDCenabled = false;
    bool public USDTenabled = false;
    uint256 public rateUSDtoBIM = 800000;//rate USD for 1000000000000000000 BIM
    uint256 public minUSD = 10000000;//minimum in USD
    uint256 public maxUSD = 50000000000;//maximum in USD

    IERC20 USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 BIM = IERC20(0xe78649874bcDB7a9D1666E665F340723a0187482);

    address receiverWalletAddress = 0x115A40E5F42a9369797643a65220411C533da38c;

    constructor() {}

    function _USDtoBIM(uint256 _USDamount, IERC20 USD, bool enabled)
        internal
    {
        require(enabled, "Payment Disabled");
        require(_USDamount >= minUSD , "Amount too low");
        require(_USDamount <= maxUSD , "Amount too high");
        require(BIM.balanceOf(address(this)) >= (_USDamount*rateUSDtoBIM)/1000000, "not enough BIM on the contract");
        require(USD.transferFrom(msg.sender, receiverWalletAddress, _USDamount), "USD transaction failed");
        require(BIM.transfer(msg.sender, _USDamount), "BIM transaction failed");
    }

    //_type : 0 -> USDC; 1 -> USDT;
    function USDtoBIM(uint256 _USDamount, uint256 _type)
        external
    {
        if(_type == 0){
            _USDtoBIM(_USDamount, USDC, USDCenabled);
        }
        else if(_type == 1){
            _USDtoBIM(_USDamount, USDT, USDTenabled);
        }
    }

    function sendBIM(uint256 _amount, address _receiverAddress)
        external
        onlyOwner
    {
        require(BIM.balanceOf(address(this)) >= _amount, "not enough BIM on the contract");
        require(BIM.transfer(_receiverAddress, _amount), "BIM transaction failed");
    }

    function setEnableUSDC(bool _enabled)
        external
        onlyOwner
    {
        USDCenabled = _enabled;
    }

    function setEnableUSDT(bool _enabled)
        external
        onlyOwner
    {
        USDTenabled = _enabled;
    }

    function setEnableUSD(bool _enabled)
        external
        onlyOwner
    {
        USDCenabled = _enabled;
        USDTenabled = _enabled;
    }
    
    function setRate(uint256 _rate)
        external
        onlyOwner
    {
        rateUSDtoBIM = _rate;
    }

    function setReceiverWallet(address _receiverWalletAddress)
        external
        onlyOwner
    {
        receiverWalletAddress = _receiverWalletAddress;
    }
}

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