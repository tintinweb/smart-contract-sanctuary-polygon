/**
 *Submitted for verification at polygonscan.com on 2022-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

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

contract MetaverseSagasTokensSplit is Ownable {

    bool public firstRelease;
    bool public secondRelease;

    address public constant METAVERSE_SAGAS_CONTRACT = 0x0448A732bf0f5baBEBE1514a2c2d5978773Fe3B2;

    mapping (address => bool) public _presale1Claimed;
    mapping (address => bool) public _presale2Claimed;
    mapping (address => bool) public _privateSaleClaimed;
    mapping (address => bool) public _presale1Wallets;
    mapping (address => bool) public _presale2Wallets;
    mapping (address => bool) public _privateSaleWallets;
    mapping (address => uint) public _presale1Tokens;
    mapping (address => uint) public _presale2Tokens;
    mapping (address => uint) public _privateSaleTokens;
    mapping (address => uint) public _privateSaleVesting;

    function flipFirstRelease() external onlyOwner {
        firstRelease = !firstRelease;
    }

    function flipSecondRelease() external onlyOwner {
        secondRelease = !secondRelease;
    }

    function addPresale1Tokens(address[] calldata wallets, uint[] calldata amounts) external onlyOwner {
        for (uint i ; i < wallets.length; i++) {
            address wallet = wallets[i];
            _presale1Tokens[wallet] = amounts[i];
            _presale1Wallets[wallet] = !_presale1Wallets[wallet];
        }
    }

    function addPresale2Tokens(address[] calldata wallets, uint[] calldata amounts) external onlyOwner {
        for (uint i ; i < wallets.length; i++) {
            address wallet = wallets[i];
            _presale2Tokens[wallet] = amounts[i];
            _presale2Wallets[wallet] = !_presale2Wallets[wallet];
        }
    }

    function addPrivateSaleTokens(address[] calldata wallets, uint[] calldata amounts) external onlyOwner {
        for (uint i ; i < wallets.length; i++) {
            address wallet = wallets[i];
            _privateSaleTokens[wallet] = amounts[i];
            _privateSaleWallets[wallet] = !_privateSaleWallets[wallet];
        }
    }

    function presale1Claim() external {
        require(_presale1Wallets[msg.sender], "NOT_ALLOWED!");
        if(!_presale1Claimed[msg.sender]){
            require(firstRelease, "CLAIM_NOT_ACTIVE_YET!");
            uint claim = (_presale1Tokens[msg.sender] * 10) / 100;
            IERC20(METAVERSE_SAGAS_CONTRACT).transfer(msg.sender, claim);
            _presale1Tokens[msg.sender] -= claim;
        }else{
            require(secondRelease, "CLAIM_NOT_ACTIVE_YET!");
            IERC20(METAVERSE_SAGAS_CONTRACT).transfer(msg.sender, _presale1Tokens[msg.sender]);
            delete _presale1Tokens[msg.sender];
        }
    }

    function presale2Claim() external {
        require(_presale2Wallets[msg.sender], "NOT_ALLOWED!");
        if(!_presale2Claimed[msg.sender]){
            require(firstRelease, "CLAIM_NOT_ACTIVE_YET!");
            uint claim = (_presale2Tokens[msg.sender] * 30) / 100;
            IERC20(METAVERSE_SAGAS_CONTRACT).transfer(msg.sender, claim);
            _presale2Tokens[msg.sender] -= claim;
        }else{
            require(secondRelease, "CLAIM_NOT_ACTIVE_YET!");
            IERC20(METAVERSE_SAGAS_CONTRACT).transfer(msg.sender, _presale2Tokens[msg.sender]);
            delete _presale2Tokens[msg.sender];
        }
    }

    function privateSaleClaim() external {
        require(_privateSaleWallets[msg.sender], "NOT_ALLOWED!");
        if(!_privateSaleClaimed[msg.sender]){
            require(firstRelease, "CLAIM_NOT_ACTIVE_YET!");
            uint claim = (_privateSaleTokens[msg.sender] * 40) / 100;
            IERC20(METAVERSE_SAGAS_CONTRACT).transfer(msg.sender, claim);
            _privateSaleTokens[msg.sender] -= claim;
        }else if(_privateSaleClaimed[msg.sender]){
            require(secondRelease, "CLAIM_NOT_ACTIVE_YET!");
            uint claim = (_privateSaleTokens[msg.sender] * 30) / 100;
            IERC20(METAVERSE_SAGAS_CONTRACT).transfer(msg.sender, _privateSaleTokens[msg.sender]);
            _privateSaleTokens[msg.sender] -= claim;
            _privateSaleVesting[msg.sender] = block.timestamp + 1209600; 
        }else if(_privateSaleClaimed[msg.sender] && _privateSaleVesting[msg.sender] > block.timestamp){
            IERC20(METAVERSE_SAGAS_CONTRACT).transfer(msg.sender, _privateSaleTokens[msg.sender]);
            delete _privateSaleTokens[msg.sender];
        }   
    }

    function withdraw() external onlyOwner {
        uint balance = IERC20(METAVERSE_SAGAS_CONTRACT).balanceOf(address(this));
        IERC20(METAVERSE_SAGAS_CONTRACT).transfer(msg.sender, balance);
    }

}