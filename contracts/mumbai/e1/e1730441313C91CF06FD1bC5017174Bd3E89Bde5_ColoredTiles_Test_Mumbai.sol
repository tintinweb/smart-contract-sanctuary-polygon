// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../TokenDropBase.sol";

/**
 * @title NFT Drop "Back To School", by Courtyard, on Polygon Mumbai Testnet.
 * Post deployment note: contract deployed:
 * @ 0x176dcA8b923af69D7196d5c57933158f436CF7a7 -> public sale
 * @ 0x789FA110D8B04014197C1213A65B368f9F228cbf -> presale only
 * @ 0xbE5a09011C320cEf80FF6c012E525ffAEBaD0BA0 -> not open
 * @ 0x0AB233f41D74eFdba48d2E05E952E4287B97d021 -> sold out
 */ 
contract ColoredTiles_Test_Mumbai is TokenDropBase {

    /// @dev Polygon Mumbai Testnet constructor. See {https://docs.chain.link/docs/vrf-contracts/#polygon-matic-mumbai-testnet}. 
    constructor(
    ) TokenDropBase(
        "Colored Tiles | Test 2 (Mumbai)",
        2,                                                                  // max per tx
        5,                                                                  // max per address
        0.15 * 10 ** 18,                                                    // 0.15 ERC20 token
        0x6C2B0EAFbA000eAAB6eb64CB4f925aEcAa655966,                         // Mock ERC20 token deployed on Mumbai
        0xab900F603A1cA0ed4f452b80F7f9c00206005dc9,                         // Test wallet for admin
        0x2df672768c93395F4ED451C8b9Db63e4bd89e171,                         // test registry deployed on Mumbai
        0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,                         // vrfCoordinator on Mumbai Testnet
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB,                         // LINK Token on Mumbai Testnet
        0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4, // keyHash on Mumbai Testnet
        0.0001 * 10 ** 18                                                   // 0.0001 LINK
    ) {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC20FundsHolder.sol";
import "./PresaleList.sol";
import "./TokenMintingPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


/**
 * @title Base contract to handle an NFT drop.
 */ 
abstract contract TokenDropBase is Context, ReentrancyGuard, Ownable, ERC20FundsHolder, PresaleList, TokenMintingPool {

    string private _name;                           // the name of this drop
    uint256 private _maxPerTx;                      // maximum of tokens that can be minted per transaction
    uint256 private _maxPerAddress;                 // maximum of tokens that can be minted by a specific address.
    uint256 public mintPrice;                       // mint price per token, in the selected ERC20.
    mapping(address => uint256) _mintsPerAddress;   // keeps track of how many tokens were minted per address.
    mapping(address => bool) _presaleMinters;       // keeps track of the addresses that already minted the presale.
                                                    // Same conditions apply to the presale as public sale, except only 
                                                    // one transaction is allowed.
    bool private _presaleIsOpen = false;            // flag used to control the presale opening
    bool private _publicSaleIsOpen = false;         // flag used to control the public sale opening

    /* ========================================== CONSTRUCTOR AND HELPERS ========================================== */

    /**
     * @dev Constructor.
     *  - Sets the name of the drop
     *  - Sets the mint limitations
     *  - Sets the mint price
     *  - Sets the {ERC20FundsHolder} parameters
     *  - Sets the {TokenMintingPool} parameters
     */
    constructor(
        string memory dropName,
        uint256 maxPerTx,
        uint256 maxPerAddress,
        uint256 mintPriceERC20,
        address erc20TokenAddress,
        address withdrawalAddress,
        address tokenRegistryAddress,
        address vrfCoordinator,
        address linkToken,
        bytes32 vrfKeyHash,
        uint256 vrfLinkFee
    ) 
    ERC20FundsHolder(erc20TokenAddress, withdrawalAddress)
    PresaleList()
    TokenMintingPool(
        tokenRegistryAddress,
        vrfCoordinator,
        linkToken,
        vrfKeyHash,
        vrfLinkFee
    ) {
        _name = dropName;
        _maxPerTx = maxPerTx;
        _maxPerAddress = maxPerAddress;
        mintPrice = mintPriceERC20;
    }

    /**
     * @dev Returns the name of this drop.
     */
    function name() public view returns (string memory) {
        return _name;
    }


    /**
     * @dev Updates the mint price.
     * Requirement: the drop hasn't started.
     */
    function updateMintPrice(uint256 _mintPrice) public onlyOwner {
        require(!_presaleIsOpen, "TokenDropBase: The drop already started - cannot update the mint price.");
        mintPrice = _mintPrice;
    }


    /* ============================================ TOKEN SUPPLY HELPERS ============================================ */

    /**
     * @dev See {TokenMintingPool._addTokens}.
     */
    function addTokens(bytes32[] memory tokenHashes) public onlyOwner {
        _addTokens(tokenHashes);
    }

    /**
     * @dev See {TokenMintingPool._removeTokens}.
     */
    function removeTokens(bytes32[] memory tokenHashes) public onlyOwner {
        _removeTokens(tokenHashes);
    }

    /**
     * @dev See {TokenMintingPool._lockTokenSupply}.
     */
    function lockTokenSupply() public onlyOwner {
        _lockTokenSupply();
    }


    /* =========================================== PRESALE LIST HELPERS =========================================== */

    /**
     * @dev See {PresaleList._addAddressesToPresale}.
     */
    function addAddressesToPresale(bytes32[] memory addressHashes) public onlyOwner {
        _addAddressesToPresale(addressHashes);
    }

    /**
     * @dev See {PresaleList._removeAddressesFromPresale}.
     */
    function removeAddressesFromPresale(bytes32[] memory addressHashes) public onlyOwner {
        _removeAddressesFromPresale(addressHashes);
    }

    /**
     * @dev allows users to check if they have presale access at their own discretion.
     */ 
    function selfCheckPresaleAccess() public view returns (bool) {
        return _hasPresaleAccess(_msgSender());
    }

    /**
     * @dev allows users to check if they can mint the presale at their own discretion.
     * note: like {selfCheckPresaleAccess}, this will always return false for an non presale address,
     * but it will also return false if a presale address already used their presale access to claim tokens.
     */
    function selfCheckPresaleEligibility() public view returns (bool) {
        address caller = _msgSender();
        return _hasPresaleAccess(caller) && !_presaleMinters[caller];
    }


    /* ========================================= PRESALE AND SALE HELPERS ========================================= */

    /**
     * @dev Check that the presale is open. Note that opening the public sale does not close the presale access.
     */
    modifier onlyPresale {
        require(_presaleIsOpen, "TokenDropBase: The presale is closed.");
        _ ;
    }

    /**
     * @dev Check that the public sale is open.
     */
    modifier onlyPublicSale {
        require(_publicSaleIsOpen, "TokenDropBase: The public sale is closed.");
        _ ;
    }

    /**
     * @dev Opens the presale. This cannot be undone.
     */
    function openPresale() public onlyOwner {
        require(tokenSupplyLocked(), "TokenDropBase: The token supply needs to be locked.");
        _lockPresaleList();
        _presaleIsOpen = true;
    }

    /**
     * @dev Opens the public sale. This cannot be undone.
     * Requirements:
     *  - presale is already open
     */
    function openPublicSale() public onlyOwner onlyPresale {
        _publicSaleIsOpen = true;
    }

    /**
     * @dev Get the sale status of the drop.
     */
    function saleStatus() public view returns (string memory) {
        bool tokenSupplyIsEmpty = remainingSupplyCount() <= 0;
        return _presaleIsOpen ? (_publicSaleIsOpen ? (tokenSupplyIsEmpty ? "SOLD_OUT" : "PUBLIC_SALE") : (tokenSupplyIsEmpty ? "SOLD_OUT" : "PRESALE" )) : "CLOSED";
    }


    /* ================================================== MINTING ================================================== */


    /**
      * @dev Calculate the number of mintable tokens given the following parameters:
      *  - the requested amount of tokens
      *  - {_maxPerTx}
      *  - {_maxPerAddress}
      *  - the remaining supply.
      * 
      * Notes:
      *  - the actual number of tokens that the caller can mint during this transaction may be less than 
      *    the requested amount when getting close to {_maxPerAddress} or when {remainingSupply} is close to 0
      */
     function _mintableAmountForAddress(address minter, uint256 requestedAmount, uint256 remainingSupply) private view returns (uint256) {
        uint256 mintableAmount = requestedAmount;
        mintableAmount = Math.min(mintableAmount, _maxPerAddress - _mintsPerAddress[minter]);
        mintableAmount = Math.min(mintableAmount, remainingSupply);
        return mintableAmount;
     }

    /**
     * @dev Helper to process a mint request.
     * 
     * Requirements:
     *  - the requested amount must be > 0
     *  - the remaining supply must be > 0
     *  - the caller must not have reached {_maxPerAddress}
     *  - {amount} must be less or equal to {_maxPerTx}
     * 
     * Notes:
     *  - Ensures that the address is eligible to mint tokens.
     *  - Calls {_mintableAmountForAddress} to calculate the actual number of tokens that can be minted by that 
     *    address, if differs from the requested amount.
     *  - Processes payment for the tokens through a call to transfer ERC20 tokens from the minter to this contract.
     *    If this fails for any reason (including insufficient funds or lack of authorization) the contract call will be reverted.
     *  - Mints the tokens to the minter.
     */
    function _processMintRequest(address minter, uint256 requestedAmount) private {
        uint256 remainingSupply = remainingSupplyCount();
        require(requestedAmount > 0, "TokenDropBase: Invalid request for zero tokens.");
        require(remainingSupply > 0, "TokenDropBase: No more tokens left.");
        require(_mintsPerAddress[minter] < _maxPerAddress, "TokenDropBase: Token limit per wallet already reached.");
        require(requestedAmount <= _maxPerTx, "TokenDropBase: Token limit per transaction exceeded.");

        uint256 mintableAmount = _mintableAmountForAddress(minter, requestedAmount, remainingSupply);
        _mintsPerAddress[minter] += mintableAmount;
        _processPayment(minter, mintableAmount * mintPrice);
        _mintTokens(minter, mintableAmount);
    }

    /**
     * @dev Claim tokens.
     * 
     * Requirements:
     *  - if the public sale is not open:
     *      - the presale must be open
     *      - sender must be allowed to access the presale
     *      - sender hasn't used their presale access yet
     *  - see {_processMintRequest}
     */
    function claimTokens(uint256 amount) external nonReentrant {
        address caller = _msgSender();
        if (!_publicSaleIsOpen) {
            require(_presaleIsOpen, "TokenDropBase: The presale is not open yet.");
            require(_hasPresaleAccess(caller), "TokenDropBase: The public sale is not open yet and caller does not have presale address.");
            require(!_presaleMinters[caller], "TokenDropBase: The public sale is not open yet and caller already minted during the presale.");
            _presaleMinters[caller] = true;
        }
        _processMintRequest(caller, amount);
    }

    /* ============================================= FUNDS WITHDRAWAL ============================================= */

    /**
     * @dev Updates withdrawal address.
     * Requirement: See {ERC20FundsHolder._setWithdrawalAddress}
     */
    function updateWithdrawalAddress(address withdrawalAddress) public onlyOwner {
        _setWithdrawalAddress(withdrawalAddress);
    }

    /**
     * @dev See {ERC20FundsHolder._withdrawFunds}
     */
    function withdrawFunds() public onlyOwner {
        _withdrawFunds();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title holds ERC20 funds and allows one address to withdraw those funds.
 */ 
abstract contract ERC20FundsHolder is Context {

    event FundsWithdrawn(address to, address token, uint256 amount);

    IERC20 public immutable erc20Token; // the ERC20 token accepted as funds by this contract.
    address private _withdrawalAddress; // the address that is allowed to withdraw the remaining funds from this contract at the end of its lifetime.

    constructor(address tokenAddress, address withdrawalAddr) {
        erc20Token = IERC20(tokenAddress);
        _setWithdrawalAddress(withdrawalAddr);
    }

    /**
     * @dev return the current withdrawal address.
     */
    function withdrawalAddress() public view returns (address) {
        return _withdrawalAddress;
    }

    /* ================================================= SETTERS ================================================= */

    /**
     * @dev Set the withdrawal address.
     * Requirement: the withdrawal address cannot be the null address
     */
    function _setWithdrawalAddress(address newAddress) internal {
        require(newAddress != address(0), "ERC20FundsHolder: Cannot set the withdrawal address to the null address.");
         _withdrawalAddress = newAddress; 
    }

    /* ============================================== FUNDS RECEIVAL ============================================== */

    function _processPayment(address from, uint256 amount) internal returns (bool) {
        return erc20Token.transferFrom(from, address(this), amount);
    }


    /* ============================================= FUNDS WITHDRAWAL ============================================= */

    /**
     * @dev Withdraw funds from the contract to the address set at creation.
     */
    function _withdrawFunds() internal {
        uint256 amount = erc20Token.balanceOf(address(this));
        erc20Token.transfer(_withdrawalAddress, amount);
        emit FundsWithdrawn(_withdrawalAddress, address(erc20Token), amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Presale List contract.
 */ 
abstract contract PresaleList {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set private _presaleList;  // The hashes of the addresses allowed for the presale
    bool private _presaleListLocked = false;        // whether or not the presale list is locked

    constructor() {}

    /**
     * @dev Adds multiple addresses to the presale list.
     * Note: In order to help protect privacy ahead of using the list for a drop or other event,
     * (even though everything is public on the blockchain), we only store the hashes of addresses.
     * Note: if the input is too big, the transaction will fail due to high gas limit.
     */
    function _addAddressesToPresale(bytes32[] memory addressHashes) internal {
        require(!_presaleListLocked, "PresaleList: Presale list is locked. Cannot add new addresses.");
        for (uint ii = 0 ; ii < addressHashes.length ; ii++) {
            _presaleList.add(addressHashes[ii]);
        }
    }

    /**
     * @dev Removes multiple addresses from the presale list.
     * Note: if the input is too big, the transaction will fail due to high gas limit.
     */
    function _removeAddressesFromPresale(bytes32[] memory addressHashes) internal {
        require(!_presaleListLocked, "PresaleList: Presale list is locked. Cannot remove addresses.");
        for (uint ii = 0 ; ii < addressHashes.length ; ii++) {
            _presaleList.remove(addressHashes[ii]);
        }
    }

    /**
     * @dev Locks the presale list.
     */
    function _lockPresaleList() internal {
        _presaleListLocked = true;
    }

    /**
     * @dev Tells if the presale is locked.
     */
    function presaleListLocked() public view returns (bool) {
        return _presaleListLocked;
    }

    /**
     * @dev Give the number of addresses in the presale list.
     */
    function presaleListCount() public view returns (uint256) {
        return _presaleList.length();
    }

    /**
     * @dev Tells whether or not {addr} is in the presale list.
     */
    function _hasPresaleAccess(address addr) internal view returns (bool) {
        return _presaleList.contains(keccak256(abi.encodePacked(addr)));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../registry/ITokenRegistry.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Token minting pool contract.
 */ 
abstract contract TokenMintingPool is VRFConsumerBase {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 private _vrfKeyHash;                                // The key hash to run Chainlink VRF

    uint256 private _vrfLinkFee;                                // Fee to call Chainlink {requestRandomness}, in LINK. 

    ITokenRegistry public immutable tokenRegistry;              // Reference to the registry where tokens will be minted.

    EnumerableSet.Bytes32Set private _availableTokenHashes;     // The available token hashes that haven't been minted yet.

    uint256 private _randomSeed;                                // A random seed number provided by Chainlink, ensuring that 
                                                                // even though the mint is 1st come / 1st serve, the order in 
                                                                // which token hashes were uploaded does not matter.
                                                                // (_randomSeed != 0) serves as a check to verify that the 
                                                                // supply is locked.

    /* ========================================== CONSTRUCTOR AND HELPERS ========================================== */

    /**
     * @dev modifier to check that the token registry implements {ITokenRegistry}, like {CourtyardRegistry}.
     */
    modifier onlyValidRegistry(address tokenRegistryAddress) {
        require(
            ERC165Checker.supportsInterface(tokenRegistryAddress, type(ITokenRegistry).interfaceId),
            "TokenMintingPool: Target token registry contract does not match the interface requirements."
        );
        _;
    }

    /**
     * @dev Constructor.
     *
     *  - Sets the parameters to use Chainlink VRF for token hashes shuffling pre-mint.
     *  - Sets the token registry
     * 
     * Requirement: {tokenRegistryAddress} must point to a valid {ITokenRegistry} contract.
     *  
     */
    constructor(
        address tokenRegistryAddress,
        address vrfCoordinator,
        address linkToken,
        bytes32 vrfKeyHash,
        uint256 vrfLinkFee
    )
    onlyValidRegistry(tokenRegistryAddress)
    VRFConsumerBase(vrfCoordinator, linkToken) {
        tokenRegistry = ITokenRegistry(tokenRegistryAddress);
        _vrfKeyHash = vrfKeyHash;
        _vrfLinkFee = vrfLinkFee;
    }


    /* ============================================ TOKEN SUPPLY HELPERS ============================================ */

    /**
     * @dev add multiple token hashes to the supply.
     * Note: if the input is too big, the transaction will fail due to high gas limit.
     */
    function _addTokens(bytes32[] memory tokenHashes) internal {
        require(!tokenSupplyLocked(), "TokenMintingPool: Token supply is locked. Cannot add new tokens.");
        for (uint ii = 0 ; ii < tokenHashes.length ; ii++) {
            _availableTokenHashes.add(tokenHashes[ii]);
        }
    }

    /**
     * @dev remove multiple token hashes from the supply.
     * Note: if the input is too big, the transaction will fail due to high gas limit.
     */
    function _removeTokens(bytes32[] memory tokenHashes) internal {
        require(!tokenSupplyLocked(), "TokenMintingPool: Token supply is locked. Cannot remove tokens.");
        for (uint ii = 0 ; ii < tokenHashes.length ; ii++) {
            _availableTokenHashes.remove(tokenHashes[ii]);
        }
    }

    /**
     * @dev Triggers the token supply locking process by making a request to Chainlink VRF to get a random seed.
     * The random seed, when provided by Chainlink, will automatically trigger a shuffle of all the token hashes 
     * and lock the supply. See {fulfillRandomness()}.
     *
     * This cannot be undone, but can be called again if chainlink failed to return a random number.
     */
    function _lockTokenSupply() internal {
        require(!tokenSupplyLocked(), "TokenMintingPool: Token supply is already locked.");
        require(LINK.balanceOf(address(this)) >= _vrfLinkFee, "TokenMintingPool: Not enough LINK to run VRF.");
        requestRandomness(_vrfKeyHash, _vrfLinkFee);
    }

    /**
     * @dev Callback function used by the VRF Coordinator, that will update the seed,
     * and lock the supply in the process (See {tokenSupplyLocked()})
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        if (!tokenSupplyLocked()) {
            _randomSeed = randomness;
        }
    }

    /**
     * @dev Tells whether or not the token supply is locked.
     */
    function tokenSupplyLocked() public view returns (bool) {
        return _randomSeed != 0;
    }

    /**
     * @dev The size of the remaining supply.
     */
    function remainingSupplyCount() public view returns (uint256) {
        return _availableTokenHashes.length();
    }

    /* ================================================== MINTING ================================================== */

    /**
     * @dev Minting function
     * 
     * Parameters:
     *  - to: the address that will recieve the newly minted tokens 
     *  - numTokens: the number of tokens to mint
     * 
     * Requirements:
     *  - The token supply must be locked.
     *  - The request hasn't already been fulfilled (using the request hash for reference).
     *  - The number of requested tokens needs to be <= The remaining supply.
     * 
     */
    function _mintTokens(address to, uint256 numTokens) internal {
        require(tokenSupplyLocked(), "TokenMintingPool: Token supply needs to be locked.");
        require(remainingSupplyCount() >= numTokens, "TokenMintingPool: Not enough tokens left.");
        for (uint ii = 0 ; ii < numTokens ; ii++) {
            uint256 index = _randomSeed % remainingSupplyCount();
            bytes32 tokenHash = _availableTokenHashes.at(index);
            tokenRegistry.mintToken(to, tokenHash);
            _availableTokenHashes.remove(tokenHash);
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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title {ITokenRegistry} is an interface for a token registry.
 */
interface ITokenRegistry is IERC165 {
    /**
     * @dev mint a new token to _to, and return the {tokenId} of the newly minted token. Upon minting a token, it is
     * required to provide the {_tokenHash} of integrity of the token. 
     * 
     * The hash uniquely identifies the token and is used to guarantee the integrity of the token at all times.
     * 
     * Use-case: for a token representing a physical asset, the _tokenHash is a hash of the information that uniquely
     * identifies the physical asset in the physical world. 
     */
    function mintToken(address _to, bytes32 _tokenHash) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}