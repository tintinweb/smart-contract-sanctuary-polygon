/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: contracts/Copy_marketplaceproxy.sol


pragma solidity  ^0.8.4;






interface MarketplaceToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function transferFrom(address _from, address _to, uint _value)external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address owner, address spender) external returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IMarketplaceSwapper {
    function getAvgPriceForTokens(uint amountIn, address[] memory path) external view returns(uint);
    function getPairTokens(address token1, address token2) view external returns (address);
}

interface INFT {
    function arbitratorAddress() external view returns(address);
    function ownerAddress() external view returns(address);
    function getTokenOwner  (string memory _id) external view returns (address);
    function mintNFT(string memory tokenUri, string memory _id) external returns (uint256);
    function mintNFTAndSell(string memory tokenUri, string memory _id) external returns (uint256);
    function mintNFTAndTransfer(string memory tokenUri, string memory _id, address to) external returns (uint256);
    function internalTransfer(address to, string memory _id, bytes32 data) external returns(bool success);
    function directTransfer(address to, string memory _id) external returns(uint256);
    function userTokens(address to) external;
    function burn (string memory _id) external;
    function royalty() external view returns (uint256);
    function setApprovalForAll(address operator, bool _approved) external;
    function approveTokenToAddress(address to, string memory _id) external;
    function getTotalTokenOwner(address to) external view returns(uint256);
    function doTokenExist(string memory _id) external view returns(bool);
}


contract SingleNFT is Ownable, ReentrancyGuard, Pausable {
    uint public start = block.timestamp;
    uint public end = block.timestamp + 60; // 1 min 
    uint public mkplc_fee = 300; //3% fee
    address[] public arbitrator;
    address public theOwner = address(0);
    uint256 public feesAvailableForWithdraw;
    address public treks = 0xa65d74f1f047596b2DaFedFdfA327Ccbd499Aa9e;
    address public  matic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public daiAddress = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public ethAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public  swapper = 0x26481167e44bCEaE4409e1ca3B7a0927d01067c6;
    address public middleToken = ethAddress;

    struct MultiBid {
        uint timeBidded;
        uint bidPrice;
        address user;
        bool valid;
    }

    struct Escrow {
        bool exists;
        // nft address for the escrow
        address contractAddress;
        string id;
        uint expiryTime;
        address owner;
    }

    struct Sellprice {
        bool exists;
        uint price;  //price in Treks
        string id;
        address contractAddress;
        address arbitrary;  // the address of the arbitrator that changed the price of the order
    }

    struct NFTData {
        string _id;
        uint price;
        address nftContract;
        string tokenUri;
        bool lazy;
        string token;
        address tokenAddress;
        address newOwner;
    }

    mapping(address => mapping(string => Sellprice)) public priceList;
    mapping (bytes32 => Escrow) public escrows;
    address[] public clientList;
    mapping (bytes32 => uint) public highestBid;
    mapping (bytes32 => address) public highestBidder;
    mapping (bytes32 => mapping(address => MultiBid)) public multiPhaseBids;
    mapping (bytes32 => address[]) public bidders;
    
    event Listed (string id, address nftContract);
    event Unlisted (string id, address nftContract);
    event AuctionEnded (bytes32 _hash);
    event NFTBought(address nftContract, string id);
    event Flushed();
    
    constructor( address _owner, address playtreks){
        require(theOwner == address(0));
        theOwner = playtreks;
        arbitrator.push(_owner);
        arbitrator.push(playtreks);
        treks = 0xa65d74f1f047596b2DaFedFdfA327Ccbd499Aa9e;
        matic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        daiAddress = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        ethAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        swapper = 0x26481167e44bCEaE4409e1ca3B7a0927d01067c6;
        middleToken = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    }

    /**
    @dev set up nft for sale
     */
    function listNFT(string memory _id, address nftContract, uint _price) public onlyArbitrator whenNotPaused{
        require(!priceList[nftContract][_id].exists, "NFT already listed on marketplace");
        priceList[nftContract][_id] = Sellprice(true, _price, _id, nftContract, msg.sender); // price in treks and with multiplier.
        emit Listed(_id, nftContract);
    }

    /**
    @dev update an nft already put for sale on the marketplace
     */
    function updateListing(string memory _id, address nftContract, uint _price) public onlyArbitrator whenNotPaused{
        require(priceList[nftContract][_id].exists, "NFT already listed on marketplace");
        priceList[nftContract][_id].price = _price;
    }

    /**
    @dev delist an nft and avoid it being sold
     */
    function removeFromListing(string memory _id, address nftContract) public onlyArbitrator whenNotPaused{
        removeListing(_id, nftContract);
    }

    /**
    @dev delist an nft and avoid it being sold
     */
    function removeListing(string memory _id, address nftContract) private{
        require(priceList[nftContract][_id].exists, "NFT not Listed on Treks marketplace yet");
        priceList[nftContract][_id].exists = false;
        emit Unlisted(_id, nftContract);
    }

    /**
    @dev update swapper contract
     */
    function updateSwapper(address newSwapper) public onlyArbitrator{
        swapper = newSwapper;
    }

    /**
    @dev set middle token for swap path
     */
    function setMiddleToken(address _token) public onlyArbitrator{
        middleToken = _token;
    }

    /**
    @dev set marketplace fee in hundreds so 250 means 2.5% or 0.025
     */
    function changeMarketplaceFee(uint _fee) public onlyArbitrator{
        mkplc_fee = _fee;
    }

    /**
    @dev Update token address of token pairs
     */
    function updateTokens(address _matic, address _treks, address _eth, address _dai, address _middleToken) public onlyArbitrator whenNotPaused{
        treks = _treks;
        matic = _matic;
        daiAddress = _dai;
        ethAddress =  _eth;
        middleToken = _middleToken;
    }
    
    /**
    @dev buy with matic for an existing nft token
     */
    function buywithMatic(string memory _id, address nftContract, address _newOwner) nonReentrant payable external whenNotPaused returns(bool){  //former parameter is uint256 _agreedAmount, 
        require(priceList[nftContract][_id].exists, "NFT not Listed on Treks marketplace yet");
        uint256 amount = msg.value;
        clientList.push(msg.sender);
        removeListing(_id, nftContract);           
        
        require(amount >= priceList[nftContract][_id].price, "Not enough Tokens sent for purchase of nft");
                
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(nftContract);
        
        //transfer the nft to the new owner
        require(Nft.getTokenOwner(_id) != msg.sender, "WASH Trade: You cannot buy your own NFTs");
        
        // allow for gifting tokens, buying on the behalf of someone(relayers)
        Nft.directTransfer(_newOwner, _id); 
        uint royalty = Nft.royalty();
        uint accruedAmount = 10000-mkplc_fee; //100% - fee percentage with 100* to allow 2 decimal places so 1.25% is 125
        
        //pay to nft owner account and taxes and royalties
        if(Nft.ownerAddress() == Nft.getTokenOwner(_id) ){
            (bool success, ) = Nft.getTokenOwner(_id).call{value: (amount * accruedAmount)/10000}("");
            require(success, "receiver rejected MATIC transfer");
        }else{
            (bool success,) = Nft.getTokenOwner(_id).call{value: (amount*(accruedAmount-royalty))/10000}("");
            require(success, "receiver rejected MATIC transfer");
            (bool success2,) = Nft.ownerAddress().call{value: (amount*royalty)/10000}("");
            require(success2, "receiver rejected MATIC transfer");
        }

        //pay remaining commision to PlayTreks wallet
        (bool success3,) = theOwner.call{value: (amount*mkplc_fee)/10000}("");
        require(success3, "receiver rejected MATIC transfer");
        
        emit NFTBought(nftContract, _id);
        return true;
    }
    
    // buy with an arbitrary token for an existing nft token
    /**
    @dev buy with an arbitrary token for an existing nft token
     */
    function buyWithToken(uint256 amount, string memory _id,  address nftContract, address tokenAddress, address _newOwner) nonReentrant whenNotPaused public returns(bool){
        require(priceList[nftContract][_id].exists, "NFT not Listed on Treks marketplace yet");
        require(amount > 0, "You need to send at least some tokens");
        clientList.push(msg.sender);
        removeListing(_id, nftContract);
        
        require(amount >= priceList[nftContract][_id].price, "Not enough Tokens sent for purchase of nft");
        
        MarketplaceToken token = MarketplaceToken(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= amount, "Not enough token allowance");
        
        INFT Nft = INFT(nftContract); //initialize Nft object to pull function from contract after intitialization here
        uint royalty = Nft.royalty();
        uint accruedAmount = 10000-mkplc_fee; //100% - fee percentage with 100* to allow 2 decimal places so 1.25% is 125
        require(Nft.getTokenOwner(_id) != msg.sender, "WASH Trade: You cannot buy your own NFTs");

        //pay to nft owner account and taxes and royalties
        if(Nft.ownerAddress() == Nft.getTokenOwner(_id)){
            require(token.transferFrom(msg.sender, Nft.getTokenOwner(_id), (amount * accruedAmount)/10000), "receiver rejected Token transfer");
        }else{
            require(token.transferFrom(msg.sender, Nft.getTokenOwner(_id), (amount*(accruedAmount-royalty))/10000), "receiver rejected Token transfer");
            require(token.transferFrom(msg.sender, Nft.ownerAddress(), (amount*royalty)/10000), "receiver rejected Token transfer");
        }

        //transfer the nft to the new owner
        Nft.directTransfer(_newOwner, _id);

        //pay remaining commision to PlayTreks wallet
        require(token.transferFrom(msg.sender, theOwner, (amount*mkplc_fee)/10000), "receiver rejected Token transfer");
       
        emit NFTBought(nftContract, _id);
        return true;
    }

    // buy with matic for a non-existent nft token
    /**
    @dev buy with matic for a non-existent nft token
     */
    function lazyBuywithMatic(string memory _id, address nftContract, string memory tokenUri, address _newOwner) nonReentrant whenNotPaused payable external returns(bool){
        require(priceList[nftContract][_id].exists, "NFT not Listed on Treks marketplace yet");
        uint256 amount = msg.value;
        require(amount > 0, "You need to send some Matic");
        clientList.push(msg.sender);
        removeListing(_id, nftContract);
        
        require(amount >= priceList[nftContract][_id].price, "Not enough Tokens sent for purchase of nft");
        
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(nftContract);
        uint accruedAmount = 10000-mkplc_fee;

        //pay to nft owner account and taxes and royalties
        (bool success, ) = Nft.ownerAddress().call{value: (amount*accruedAmount)/10000}("");
        require(success, "receiver rejected MATIC transfer");

        //transfer the nft to the new owner
        // allow for gifting tokens, buying on the behalf of someone(relayers)
        require(Nft.mintNFTAndTransfer(tokenUri, _id, _newOwner) > 0, "NFT transfer failed");

        //pay remaining commision to PlayTreks wallet
        (bool success2, ) = theOwner.call{value: (amount*mkplc_fee)/10000}("");
        require(success2, "receiver rejected MATIC transfer");

        emit NFTBought(nftContract, _id);
        return true;
    }
    
    // buy with arbitrary token for a non-existent nft token
    /**
    @dev buy with an arbitrary token for a non-existent nft token
     */
    function lazyBuyWithToken(uint256 amount, string memory _id,  address nftContract, address tokenAddress, string memory tokenUri, address _newOwner) nonReentrant whenNotPaused public returns(bool){
        require(priceList[nftContract][_id].exists, "NFT not Listed on Treks marketplace yet");
        require(amount > 0, "You need to send at least some tokens");
        clientList.push(msg.sender);
        removeListing(_id, nftContract);
        
        require(amount >= priceList[nftContract][_id].price, "Not enough Tokens sent for purchase of nft");
        
        
        MarketplaceToken token = MarketplaceToken(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= amount, "Not enough token allowance");
        
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(nftContract); 
        uint accruedAmount = 10000-mkplc_fee;       

        //pay to nft owner account and taxes and royalties
        require(token.transferFrom(msg.sender, Nft.ownerAddress(), (amount * accruedAmount)/10000), "receiver rejected Token transfer");

        //transfer the nft to the new owner
        require(Nft.mintNFTAndTransfer(tokenUri, _id, _newOwner) > 0, "NFT transfer failed");

        //pay remaining commision to PlayTreks wallet
        require(token.transferFrom(msg.sender, theOwner, (amount*mkplc_fee)/10000), "receiver rejected Token transfer");
        //trekstoken.transfer(owner, (amount/5));
        emit NFTBought(nftContract, _id);
        return true;
    }

    /**
    @dev add a new arbitrator
     */
    function setArbitrator(address _newArbitrator) onlyArbitrator external {
        /**
         * Set the arbitrator to a new address. Only the owner can call this.
         * @param address _newArbitrator
         */
        arbitrator.push(_newArbitrator);
    }

    /**
    @dev set owner of contract to receive tax on nft sales
     */
    function setOwner(address _newOwner) onlyArbitrator external {
        /**
         * Change the owner to a new address. Only the owner can call this.
         * @param address _newOwner
         */
        theOwner = _newOwner;
    }

    /**
    @dev check if listing of an nft exists
     */
    function exists(string memory _id,  address nftContract) public view returns(bool){
        return priceList[nftContract][_id].exists;
    }

    /**
    @dev get current listing price of an nft
     */
    function getListingPrice(string memory _id,  address nftContract) public view returns (uint){
        return priceList[nftContract][_id].price;
    }

    /**
    @dev clear tokens locked up in contract
     */
    function flushLiquidity() onlyOwnerAllowed public whenNotPaused{
        (bool transSuccess) = MarketplaceToken(treks).transfer(msg.sender, MarketplaceToken(treks).balanceOf(address(this)) );
        (bool success,  ) = msg.sender.call{value: address(this).balance }("");
        require(transSuccess, "Failed to transfer Treks");
        require(success, "Failed to transfer balance");
        emit Flushed();
    }

    /**
    @dev clear a token
     */
    function flushToken(address _token) onlyOwnerAllowed public whenNotPaused{
        (bool transSuccess) = MarketplaceToken(_token).transfer(msg.sender, MarketplaceToken(_token).balanceOf(address(this)) );
        (bool success,  ) = msg.sender.call{value: address(this).balance }("");
        require(transSuccess, "Failed to transfer Treks");
        require(success, "Failed to transfer balance");
        emit Flushed();
    }

    /**
    @dev get contract address where contract was deployed
     */
    function contractAddress() public view returns(address){
        return address(this);
    }

    /**
    @dev modifier for allowing only arbitrators
     */
    modifier onlyArbitrator {
        bool yes = false;
        for (uint i=0; i<arbitrator.length; i++) {
            if(msg.sender == arbitrator[i]){
                yes=true;
            }
        }
        require(yes == true, "Only approved arbitrators can call this function");
        _;
    }

    /**
    @dev modifier for only allowing owner to call the functions
     */
    modifier onlyOwnerAllowed {
        require(theOwner == msg.sender, 'unauthorized');
        _;
    }
}

contract BuyOrMintNFT is SingleNFT {

    constructor(address _owner, address playtreks) SingleNFT(_owner, playtreks){}

    // buy nft with matic as either old token or newly minted token
    /**
    @dev buy nft with matic as either old token or newly minted token
     */
    function buyNFTWithMatic(string memory _id, address nftContract, string memory tokenUri, address _newOwner) payable external returns(bool) {
        INFT Nft = INFT(nftContract);
        if(Nft.doTokenExist(_id)){
            require(this.buywithMatic{ value: msg.value }(_id, nftContract, _newOwner),"Transaction not successful");
        }else{
            require(this.lazyBuywithMatic{ value: msg.value }(_id, nftContract, tokenUri, _newOwner),"Transaction not successful");
        }

        return true;
    }

    // buy nft with matic as either old token or newly minted token
    /**
    @dev buy nft with matic as either old token or newly minted token
     */
    function buyNFTWithToken(uint256 amount, string memory _id,  address nftContract, address tokenAddress, string memory tokenUri, address _newOwner) public returns(bool) {
        INFT Nft = INFT(nftContract);
        if(Nft.doTokenExist(_id)){
            require(buyWithToken(amount, _id, nftContract, tokenAddress, _newOwner),"Transaction not successful");
            
        }else{
            require(lazyBuyWithToken(amount, _id, nftContract, tokenAddress, tokenUri, _newOwner),"Transaction not successful");
        }

        return true;
    }
}


contract UserPlaytreksMarketplace is BuyOrMintNFT {

    constructor(address _owner, address playtreks) BuyOrMintNFT(_owner, playtreks){}
    // multiple buy with matic
    /**
    @dev multiple buy with matic
     */
    function multiBuyMatic(NFTData[] memory _data) payable public {
        for(uint i; i<_data.length; i++){
            NFTData memory data = _data[i];
            require(this.buyNFTWithMatic{ value: msg.value/_data.length }(data._id, data.nftContract, data.tokenUri, data.newOwner),"Transaction not successful");
        }
    }

    // multiple buy with erc20 tokens
    /**
    @dev multiple buy with erc20 tokens
     */
    function multiBuyToken(NFTData[] memory _data) public {
        for(uint i; i<_data.length; i++){
            NFTData memory data = _data[i];
            require(buyNFTWithToken(data.price, data._id, data.nftContract, data.tokenAddress, data.tokenUri, data.newOwner),"Transaction not successful");
        }
    }

    function multiList(string[] memory _ids, address[] calldata nftContracts, uint[] calldata _prices) public {
        require(_ids.length == nftContracts.length && nftContracts.length == _prices.length, "all must be the same length");
        for(uint i; i<_ids.length; i++){
            listNFT(_ids[i], nftContracts[i], _prices[i]);
        }
    }

    function pause() public onlyOwnerAllowed{
        _pause();
    }

    function unpause() public onlyOwnerAllowed{
        _unpause();
    }
}