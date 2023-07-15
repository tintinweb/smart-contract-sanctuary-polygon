// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TropicalLaunchpad is ReentrancyGuard, Ownable {
    IERC20 public _USDC;
    IERC20 public _papple;
    address payable public _wallet;
    uint256 public endPRE;
    uint256 public endPUB;
    uint256 public price;
    uint public maxPurchase;
    uint public availableTokens;
    uint public totalUsdcRaised;
    uint public totalPappleSold;
    uint8 public whitelistSize;
    bool public liveClaim = false;
    uint public timeClaim;
    address[] public funders;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public addressToUsdcFunded;
    mapping(address => uint256) public addressToPapplePurchased;
    mapping(address => uint256) public addressTo_WL_PapplePurchased;

    struct claimWL {
        bool firstClaim;
        uint256 lastClaim;
        uint256 unlockPerDay;
        uint256 startAmount;
        uint256 totalClaimed;
    }

    struct claimPublic {
        bool firstClaim;
        uint256 lastClaim;
        uint256 unlockPerDay;
        uint256 startAmount;
        uint256 totalClaimed;        
    }

    mapping(address => claimWL) public vault_claimWL;
    mapping(address => claimPublic) public vault_claimPublic;

    event TokensPurchased(address indexed beneficiary, uint256 usdcValue, uint256 tokenAmount);
    event TokensClaimed(address indexed beneficiary, uint256 tokenAmount);

    constructor (address payable wallet, IERC20 token, IERC20 usdc) {
        require(wallet != address(0), "Constructor: wallet is the zero address");
        require(address(token) != address(0), "Constructor: token is the zero address");
        require(address(usdc) != address(0), "Constructor: usdc is the zero address");
        
        _wallet = wallet;
        _papple = token;
        _USDC = usdc;
    }

    modifier preActive() {
        require(endPRE > 0 && block.timestamp < endPRE && availableTokens > 0, "Pre-Sale must be active");
        _;
    }
    
    modifier preNotActive() {
        require(endPRE < block.timestamp, "Pre-Sale should not be active");
        _;
    }

    modifier pubActive() {
        require(endPUB > 0 && block.timestamp < endPUB && availableTokens > 0, "Public Sale must be active");
        _;
    }
    
    modifier pubNotActive() {
        require(endPUB < block.timestamp, "Public Sale should not be active");
        _;
    }
    
    //Start Pre-Sale
    function startPreSale(uint256 _endHours) external onlyOwner preNotActive() pubNotActive() {
        availableTokens = 400000 * 1 ether; // 400.000 $PAPPLE
        price = 250000; // 0.25 USDC
        maxPurchase = 10000 * 1 ether; // 10.000 $PAPPLE
        endPRE = block.timestamp + (_endHours * 1 hours); // 48 Hours 
    }
    
    function stopPreSale() external onlyOwner preActive(){
        endPRE = 0;
    }

    //Start Public Sale
    function startPublic(uint256 _endHours) external onlyOwner preNotActive() pubNotActive() {
        availableTokens += 500000 * 1 ether; // Pre-Sale unsold + 500.000 $PAPPLE
        price = 500000; // 0.50 USDC
        endPUB = block.timestamp + (_endHours * 1 hours); // 96 Hours 
    }
    
    function stopPublic() external onlyOwner pubActive(){
        endPUB = 0;
    }
    
    //Pre-Sale Internal
    function buyPresale(address _sender, uint256 amount) internal preActive(){
        uint256 purchased = getTokenAmount(amount);
        require(whitelist[_sender], "Address not in Whitelist");
        require((addressTo_WL_PapplePurchased[_sender] + purchased) <= maxPurchase, "Address exceeds purchasing limit");
        require(availableTokens >= purchased, "Amount purchased exceeds avaiable tokens");
        addressToUsdcFunded[_sender] += amount;
        addressTo_WL_PapplePurchased[_sender] += purchased;
        totalUsdcRaised += amount;
        totalPappleSold += purchased;
        availableTokens -= purchased;
        emit TokensPurchased(_sender, amount, purchased);
    }

    //Public Sale Internal
    function buyPublic(address _sender, uint256 amount) internal pubActive(){
        uint256 purchased = getTokenAmount(amount);
        require(availableTokens >= purchased, "Amount purchased exceeds avaiable tokens");
        addressToUsdcFunded[_sender] += amount;
        addressToPapplePurchased[_sender] += purchased;
        totalUsdcRaised += amount;
        totalPappleSold += purchased;
        availableTokens -= purchased;
        emit TokensPurchased(_sender, amount, purchased);
    }

    // Universal Buy Function
    function buyTokens(uint _usdcAmount) external payable nonReentrant {
        address beneficiary = msg.sender;
        uint256 amount = _usdcAmount;
        bool addrRegistered = false;
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(amount != 0, "Crowdsale: USDC amount is 0");
        require(_USDC.allowance(msg.sender, address(this)) >= amount, "Insufficient USDC allowance");
        require(_USDC.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");
        if (endPRE > 0 && block.timestamp < endPRE && availableTokens > 0){
            buyPresale(beneficiary, amount);
        } else if (endPUB > 0 && block.timestamp < endPUB && availableTokens > 0){
            buyPublic(beneficiary, amount);
        } else {
            require(false, "Sale is not active");
        }
        for(uint i=0; i<funders.length; i++){
            if(funders[i] == beneficiary){addrRegistered = true;}
        }
        if(addrRegistered == false){funders.push(beneficiary);}
    }

    // Whitelist Functions
    function addToWhitelist(address[] memory _addresses) external onlyOwner {
        require(whitelistSize + _addresses.length <= 100, "Addresses exceeds whitelist capacity");
        for (uint8 i = 0; i < _addresses.length; i++) {
            require(!whitelist[_addresses[i]], "Address is already in whitelist");
            whitelist[_addresses[i]] = true;
            whitelistSize += 1;
        }
    }

    function removeFromWhitelist(address[] memory _addresses) external onlyOwner {
        require(whitelistSize - _addresses.length >= 0, "More addresses than whitelist size");
        for (uint8 i = 0; i < _addresses.length; i++) {
            require(whitelist[_addresses[i]], "Address not in whitelist");
            whitelist[_addresses[i]] = false;
            whitelistSize -= 1;
        }
    }

    // Start Claim
    function startClaim() external onlyOwner preNotActive() pubNotActive(){
        liveClaim = true;
        timeClaim = block.timestamp;
    }

    // Claim
    function claimPapple() external payable nonReentrant preNotActive() pubNotActive(){
        address sender = msg.sender;
        uint256 claimAmount;
        uint256 startAmount;
        uint256 totalClaimAmount;
        uint256 totalUnlocked;
        require(liveClaim, "Claim is not active");
        require(addressTo_WL_PapplePurchased[sender] > 0 || addressToPapplePurchased[sender] > 0, "Your $PAPPLE balance is 0");
        if (addressTo_WL_PapplePurchased[sender] > 0){
            if (!vault_claimWL[sender].firstClaim){
                startAmount = addressTo_WL_PapplePurchased[sender]; // Save start amount
                claimAmount = addressTo_WL_PapplePurchased[sender] * 30 / 100; // 30% First claim
                addressTo_WL_PapplePurchased[sender] -= addressTo_WL_PapplePurchased[sender] * 30 / 100; // Update Balance
                uint256 unlockPerDay = addressTo_WL_PapplePurchased[sender] / 30; // 30 days
                vault_claimWL[sender] = claimWL({
                    firstClaim: true,
                    lastClaim: timeClaim,
                    unlockPerDay: unlockPerDay,
                    startAmount: startAmount,
                    totalClaimed: claimAmount
                });
                totalClaimAmount += claimAmount;
                claimAmount = 0; // Reset variable
            }
            totalUnlocked = vault_claimWL[sender].unlockPerDay * (block.timestamp -  vault_claimWL[sender].lastClaim) / 86400; // Total Unlocked from last claim
            if (totalUnlocked > (vault_claimWL[sender].startAmount - vault_claimWL[sender].totalClaimed)){totalUnlocked = vault_claimWL[sender].startAmount - vault_claimWL[sender].totalClaimed;}
            addressTo_WL_PapplePurchased[sender] -= totalUnlocked; // Update balance
            claimAmount += totalUnlocked; // Claim
            vault_claimWL[sender].totalClaimed += claimAmount;
            vault_claimWL[sender].lastClaim = block.timestamp; // Update structure
            totalClaimAmount += claimAmount;
            claimAmount = 0; // Reset variable
        }

        if (addressToPapplePurchased[sender] > 0){
            if (!vault_claimPublic[sender].firstClaim){
                startAmount = addressToPapplePurchased[sender]; // Save start amount
                claimAmount = addressToPapplePurchased[sender] * 60 / 100; // 60% First claim
                addressToPapplePurchased[sender] -= addressToPapplePurchased[sender] * 60 / 100; // Update Balance
                uint256 unlockPerDay = addressToPapplePurchased[sender] / 30; // 30 days
                vault_claimPublic[sender] = claimPublic({
                    firstClaim: true,
                    lastClaim: timeClaim,
                    unlockPerDay: unlockPerDay,
                    startAmount: startAmount,
                    totalClaimed: claimAmount
                });
                totalClaimAmount += claimAmount;
                claimAmount = 0; // Reset variable
            }
            totalUnlocked = vault_claimPublic[sender].unlockPerDay * (block.timestamp -  vault_claimPublic[sender].lastClaim) / 86400; // Total Unlocked from last claim
            if (totalUnlocked > (vault_claimPublic[sender].startAmount - vault_claimPublic[sender].totalClaimed)){totalUnlocked = vault_claimPublic[sender].startAmount - vault_claimPublic[sender].totalClaimed;}
            addressToPapplePurchased[sender] -= totalUnlocked; // Update balance
            claimAmount += totalUnlocked; // Claim
            vault_claimPublic[sender].totalClaimed += claimAmount;
            vault_claimPublic[sender].lastClaim = block.timestamp; // Update structure
            totalClaimAmount += claimAmount;
            claimAmount = 0; // Reset variable
        }

        require(_papple.transfer(sender, totalClaimAmount), "$PAPPLE transfer failed");
        emit TokensClaimed(sender, totalClaimAmount);
    }

    // VIEW

    function getTokenAmount(uint256 usdcAmount) public view returns(uint256) {
        uint256 purchased = usdcAmount / price;
        purchased = purchased * 1 ether; // Conversion to 18 decimals
        return purchased;
    }

    function viewFunders() external view returns(address[] memory _funders){
        return funders;
    }

    // ONLY OWNER

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setAvailableTokens(uint256 amount) external onlyOwner {
        availableTokens = amount;
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner{
        _wallet = newWallet;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner{
        maxPurchase = value;
    }
    
    function setLiveClaim(bool set) external onlyOwner{
        liveClaim = set;
    }

    function withdrawETH() external onlyOwner {
         require(address(this).balance > 0, "Contract has no ETH");
        _wallet.transfer(address(this).balance);    
    }
    
    function withdrawTokens(IERC20 tokenAddress) external onlyOwner{
        IERC20 wToken = tokenAddress;
        uint256 tokenAmt = wToken.balanceOf(address(this));
        require(tokenAmt > 0, "Token balance is 0");
        wToken.transfer(_wallet, tokenAmt);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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