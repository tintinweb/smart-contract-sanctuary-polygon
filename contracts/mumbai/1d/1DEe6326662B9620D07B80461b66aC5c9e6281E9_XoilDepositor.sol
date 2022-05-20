/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title ERC1363Receiver interface
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *  from ERC1363 token contracts.
 */
interface IERC1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the token contract address is always the message sender.
   * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
   * @param from address The address which are token transferred from
   * @param value uint256 The amount of tokens transferred
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
   *  unless throwing
   */
    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) external returns (bytes4);
}



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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



// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract XoilDepositor is IERC1363Receiver, Ownable {

    bytes4 retval = bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));

    uint256 private depositsCount = 0;
    address private depositWallet;

    IERC20 private xoilContract;
    address private xoilContractAddress;

    mapping(uint256 => DepositData) private depositsDataSet;

    constructor(address _depositWallet, address _xoilContractAddress) {
        depositWallet = _depositWallet;
        xoilContract = IERC20(_xoilContractAddress);
        xoilContractAddress = _xoilContractAddress;
    }

    struct DepositData {
        uint256 id;
        address depositor;
        uint256 amount;
    }


    event TokensReceived(
        address indexed operator,
        address indexed from,
        uint256 value,
        bytes data
    );

    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) public virtual override returns (bytes4) {
        require(_msgSender() == xoilContractAddress, "It may be called only by the XOIL contract");
        xoilContract.transfer(depositWallet, value);
        depositsDataSet[depositsCount] = DepositData(depositsCount, operator, value);
        depositsCount++;
        emit TokensReceived(operator, from, value, data);
        return retval;
    }

    function getDepositCount() public view returns (uint256) {
        return depositsCount;
    }

    function setDepositWallet(address _depositWallet) public onlyOwner {
        depositWallet = _depositWallet;
    }

    function getDepositByIndex(uint256 idx) public view returns (DepositData memory) {
        return depositsDataSet[idx];
    }
    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdrawERC20(address tokenContractAddress, uint256 amount, address receipient) external onlyOwner {
        IERC20(tokenContractAddress).transfer(receipient, amount);
    }

}