/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// CMSale.06.sol

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: CMSale.sol

pragma solidity 0.8.7;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract CMSale is Ownable {

    event CreateSale(uint256 saleID, uint256 startTime, uint256 endTime, uint256 cap, uint256 price);
    event DeleteSale(uint256 saleID);
    event CloseSale(uint256 saleID, uint256 closeTime, uint256 soldAmount, uint256 raisedAmount, address cmdWallet);
    event Buy(uint256 saleID, uint256 serialNo, address indexed buyer);
    event ChangeAdmin(address admin);
    event ChangedCmdWallet(address cmdWallet);

    struct Sale {
        uint256 price;
        uint40 startTime;
        uint40 endTime;
        uint24 cap;
        bool isActive;
        uint24 soldAmount;
        uint256 raisedAmount; 
    }

    Sale[] public sales;

    ERC20 public ERC20Interface;

    address public immutable tokenAddress;
    address public admin;
    address public cmdWallet;

    /// @notice There are two admin roles - admin and owner
    /// in case of need/risk, owner can substitute/change admin
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner(), "CMSale: Not Admin");
        _;
    }
    modifier onlyValidAddress(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this) && _recipient != tokenAddress, "CMSale: Not valid recipient address");
        _;
    }
    modifier _positive(uint256 amount) {
        require(amount >= 0, "CMSale: negative amount");
        _;
    }
    modifier _after(uint256 eventTime) {
        require(
            block.timestamp >= eventTime,
            "CMSale: late request"
        );
        _;
    }
    modifier _before(uint256 eventTime) {
        require(
            block.timestamp < eventTime,
            "CMSale: early request"
        );
        _;
    }
    modifier _hasAllowance(address allower_, uint256 amount_, address tokenAddress_) {
        // Make sure the allower has provided the right allowance.
        ERC20Interface = ERC20(tokenAddress_);
        uint256 ourAllowance = ERC20Interface.allowance(allower_, address(this));
        require(
            amount_ <= ourAllowance,
            "CMSale: Not enough allowance"
        );
        _;
    }
    modifier _realAddress(address addr) {
        require(addr != address(0), "CMSale: zero address");
        _;
    }

    constructor (address _tokenAddress, address _cmdWallet) {
        require(_tokenAddress != address(0), "CNS-01");
        require(_cmdWallet != address(0) && _cmdWallet != _tokenAddress, "CNS-02");
        tokenAddress = _tokenAddress;
        cmdWallet = _cmdWallet;
        admin = msg.sender;
    }

    /// @notice create sale
    function createSale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _cap,
        uint256 _price
    )
        external
        onlyAdmin
    {
        require(_price > 0 && _cap > 0, "CRE-01");
        require(block.timestamp < _startTime && _startTime < _endTime, "CRE-02");
        sales.push(Sale(
                _price,
                uint40(_startTime),
                uint40(_endTime),
                uint24(_cap),
                true,
                0,0));
        emit CreateSale(sales.length, _startTime, _endTime, _cap, _price);
    }

    /// @notice delete last sale
    function deleteLastSale() external onlyAdmin {
        uint256 salesLen_ = sales.length;
        require(salesLen_ > 0 && sales[salesLen_-1].startTime > block.timestamp, "DEL-01");
        sales.pop();
        emit DeleteSale(salesLen_);    
    }

    function closeSale(uint256 _saleID) external onlyAdmin {
        require(_saleID <= sales.length, "CLO-01");
        Sale storage sale_ = sales[_saleID-1];        
        require(sale_.isActive, "CLO-02");
        require(block.timestamp > sale_.endTime || sale_.soldAmount == sale_.cap, "CLO-03");
        sale_.isActive = false;
        require(_tokenTransfer(cmdWallet, sale_.raisedAmount, tokenAddress), "CLO-04");
        emit CloseSale(_saleID, block.timestamp, sale_.soldAmount, sale_.raisedAmount, cmdWallet);
    }

    /// @notice buy item
    function buy(uint256 _saleID)
        external
        returns (bool)
    {   
        require(_saleID <= sales.length, "BUY-01");
        Sale storage sale_ = sales[_saleID-1];        
        require (sale_.isActive, "BUY-02");
        require (block.timestamp >= sale_.startTime && block.timestamp <= sale_.endTime, "BUY-03"); 
        require (sale_.soldAmount < sale_.cap, "BUY-04");
        address buyer_ = msg.sender;
        uint256 price_ = sale_.price;
        sale_.soldAmount++;
        sale_.raisedAmount += price_;
        require(_tokenTransferFrom(buyer_, address(this), price_, tokenAddress), "BUY-04");
        emit Buy(_saleID, sale_.soldAmount, buyer_);
        return true;
    }

    function withdrawStuckTokens(uint256 amount_, address tokenAddress_) external onlyAdmin {
        require(_tokenTransfer(owner(), amount_, tokenAddress_), "WTH-01");
    }

    function changeCmdWallet(address _newCmdWallet)
        external
        onlyOwner
        onlyValidAddress(_newCmdWallet)
    {
        cmdWallet = _newCmdWallet;
        emit ChangedCmdWallet(_newCmdWallet);
    }

    function changeAdmin(address _newAdmin) 
        external 
        onlyOwner
        onlyValidAddress(_newAdmin)
    {
        admin = _newAdmin;
        emit ChangeAdmin(_newAdmin);
    }

    function getSalesCount() external view returns (uint256) {
        return sales.length;
    }

    function _tokenTransferFrom(
        address allower_,
        address receiver_,
        uint256 amount_,
        address tokenAddress_
    ) private _hasAllowance(allower_, amount_, tokenAddress_) returns (bool) {
        ERC20Interface = ERC20(tokenAddress_);
        return ERC20Interface.transferFrom(allower_, receiver_, amount_);
    }

    function _tokenTransfer(address to_, uint256 amount_, address tokenAddress_)
        private
        _realAddress(to_)
        _positive(amount_)
        returns (bool)
    {
        ERC20Interface = ERC20(tokenAddress_);
        return ERC20Interface.transfer(to_, amount_);
    }

}