// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "Ownable.sol";
import "IERC20.sol";

interface FitMintToken {
    function mintTokens(uint256 tokenAmount) external;
}

interface FitMintNFT {
    function mintOGNFT(address userAddress) external;
    function mintNGNFT(address userAddress) external;
}

contract FitMintGame is Ownable {

    address public tokenAddress;
    address public nftAddress;
    FitMintToken gameTokenInstance;
    FitMintNFT gameNFTInstance;

    bool public isAllowListActive = false;
    mapping(address => uint8) _allowOGList;
    mapping(address => uint8) _allowNGList;
    uint256 public pricePerNGNFT = 1 ether;
    uint256 public pricePerOGNFT = 1 ether;
    
    bool public isTokenDistributionActive = false;
    mapping(address => uint256) FITTBalances;
    uint256 public pricePerToken = 0 ether;

    uint256 public balance;
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    constructor(address _tokenAddress, address _nftAddress) public {
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
        gameTokenInstance = FitMintToken(_tokenAddress);
        gameNFTInstance = FitMintNFT(_nftAddress);
    }

    function setTokenAddr(address _tokenAddress) public onlyOwner {
       tokenAddress = _tokenAddress;
       gameTokenInstance = FitMintToken(_tokenAddress);
    }

    function setNFTAddr(address _nftAddress) public onlyOwner {
       nftAddress = _nftAddress;
       gameNFTInstance = FitMintNFT(_nftAddress);
    }

    /// todo confirm if Input will be in 1 or 1*(10**18)
    function setPricePerNGNFT(uint256 _pricePerNGNFT) public onlyOwner {
       pricePerNGNFT = _pricePerNGNFT * (10**18);
    }

    function setPricePerOGNFT(uint256 _pricePerOGNFT) public onlyOwner {
       pricePerOGNFT = _pricePerOGNFT * (10**18);
    }

    function setAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setTokenDistributionActive(bool _isTokenDistributionActive) external onlyOwner {
        isTokenDistributionActive = _isTokenDistributionActive;
    }
    

    function setNGAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowNGList[addresses[i]] = numAllowedToMint;
        }
    }

    function setOGAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowOGList[addresses[i]] = numAllowedToMint;
        }
    }

    function nftAvailableToMint(address addr) public onlyOwner returns (uint8, uint8) {
        return (_allowNGList[addr], _allowOGList[addr]);
    }

    function getAvailableToMint(address addr) public onlyOwner returns (uint256) {
        return FITTBalances[addr];
    }


    function setFITTBalances(address[] calldata addresses, uint256[] calldata balancelist) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            FITTBalances[addresses[i]] = balancelist[i];
        }
    }

    function addFITTEarnings(address[] calldata addresses, uint256[] calldata balancelist) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            FITTBalances[addresses[i]] += balancelist[i];
        }
    }
    /// todo Finalize on accepting, logging, and withdrawal of token in Game Contract
    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    } 
    
    function withdraw(uint amount, address payable destAddr) public onlyOwner{
        // require(msg.sender == owner, "Only owner can withdraw funds"); 
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount);
        balance -= amount;
        emit TransferSent(msg.sender, destAddr, amount);
    }

    function transferERC20(IERC20 token, address to, uint256 amount) public onlyOwner {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Insufficient Balance of ERC20 token for Transfer");
        token.transfer(to, amount);
        emit TransferSent(msg.sender, to, amount);
    }

    /// todo Change name of functions which will be used to Mint tokens from FITT ERC20 contract
    function claimComminityTokens(uint tokenAmount) public onlyOwner{
        gameTokenInstance.mintTokens(tokenAmount);
    }

    function claimTokens(uint256 _tokenAmount) public payable{
        require(isTokenDistributionActive, "Token Distribution is not active");
        require(msg.value >= pricePerToken, "pricePerToken to be removed");
        require(FITTBalances[msg.sender] >= _tokenAmount);
        IERC20(tokenAddress).transfer(msg.sender, _tokenAmount);
        FITTBalances[msg.sender] -= _tokenAmount;
    }

    function claimNGNFTwithPolygon() public payable{
        require(isAllowListActive, "Allow list is not active");
        require(msg.value >= pricePerNGNFT, "Native coin send is less than Price of NFT");
        require(_allowNGList[msg.sender] > 0, "Mintable NFT number not updated in _allowList for the Address");
        gameNFTInstance.mintNGNFT(msg.sender);
        _allowNGList[msg.sender] -= 1;
    }

    function claimOGNFTwithPolygon() public payable{
        require(isAllowListActive, "Allow list is not active");
        require(msg.value >= pricePerOGNFT, "Native coin send is less than Price of NFT");
        require(_allowOGList[msg.sender] > 0, "Mintable NFT number not updated in _allowList for the Address");
        gameNFTInstance.mintOGNFT(msg.sender);
        _allowOGList[msg.sender] -= 1;
    }

    /// todo Finalize Reserve functions here or implement in Game Contract & emit event
    function reserveNG(address _address) public onlyOwner {
        gameNFTInstance.mintNGNFT(_address);
    }
    
    function reserveOG(address _address) public onlyOwner {
        gameNFTInstance.mintOGNFT(_address);
    }

    function reserveToken(address _address, uint256 _tokenAmount) public onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= _tokenAmount);
        IERC20(tokenAddress).transfer(_address, _tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}