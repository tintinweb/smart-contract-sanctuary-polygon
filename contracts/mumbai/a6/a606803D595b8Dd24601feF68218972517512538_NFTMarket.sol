// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface TSKToken {

  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
      uint256 tokensSwapped,
      uint256 ethReceived,
      uint256 tokensIntoLiqudity
  );

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);
  
  function setNFTcontract() external;

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function increaseAllowance(address spender, uint256 addedValue) external  returns (bool);

  function decreaseAllowance(address spender, uint256 subtractedValue) external  returns (bool);

  function isExcludedFromReward(address account) external view returns (bool);

  function totalFees() external view returns (uint256);
  
  function burnedTokens() external view returns (uint256);

  function give(uint256 tAmount) external;

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256);

  function tokenFromReflection(uint256 rAmount) external view returns(uint256);

  function excludeFromReward(address account) external;

  function includeInReward(address account) external;

  function excludeFromFee(address account) external;

  function includeInFee(address account) external;

  function setSwapAndLiquifyEnabled(bool _enabled) external;

  receive() external payable;

  function _reflectFee(uint256 rFee, uint256 tFee, uint256 burnedAmount) external;

  function _getValues(uint256 tAmount) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

  function _getTValues(uint256 tAmount) external view returns (uint256, uint256, uint256);

  function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) external pure returns (uint256, uint256, uint256);

  function _getRate() external view returns(uint256);

  function _getCurrentSupply() external view returns(uint256, uint256);

  function _takeLiquidity(uint256 tLiquidity) external;

  function calculateTaxFee(uint256 _amount) external view returns (uint256);

  function calculateLiquidityFee(uint256 _amount) external view returns (uint256);

  function updateNumTokensBeforeLiquify(uint256 newAmount) external ;

  function removeAllFee() external;

  function _removeAllFee() external;

  function restoreAllFee() external;

  function _restoreAllFee() external;

  function isExcludedFromFee(address account) external view returns(bool);

  function _approve(address owner, address spender, uint256 amount) external;

  function _transfer( address from, address to, uint256 amount) external;

  function swapAndLiquify(uint256 contractTokenBalance) external;

  function swapTokensForEth(uint256 tokenAmount) external;

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external;

  function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) external;

  function _transferStandard(address sender, address recipient, uint256 tAmount) external;

  function _transferToExcluded(address sender, address recipient, uint256 tAmount) external;
  
  function _transferFromExcluded(address sender, address recipient, uint256 tAmount) external;
  
  function _transferBothExcluded(address sender, address recipient, uint256 tAmount) external;
}

interface A2RewardLogic {}

interface A1UtilityNFTs {
  function setToken(A0TheStupidestKidsNFTs _a0TheStupidestKidsNFTs, A2RewardLogic _a2RewardLogic) external;
  function mintUtility(uint256 _id) external;
  function burn(uint256 _id) external;

  function onlyMintNFTs(bool _bool) external;
  function setURI(uint _id, string memory _uri) external;
  function reveal() external;
  function setUtilityPerHour(uint amount) external;

  function uri(uint _id) external  view returns (string memory);
  function getallUtilityNFTs() external view returns(uint[] memory);
  function upgradeUtilityNFTBalance() external;
  
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data ) external;
}
interface A0TheStupidestKidsNFTs {
  
  receive () external payable;
  
  function setToken(A2RewardLogic _a2RewardLogic) external;
  function mint(address _to, uint256 _id) external payable;
  function mintLegendary(uint256 _id) external;
  function needToUpdateCost (uint256 _id) external;
  function payForNFTUtilities(address _user, uint _payment) external;
  function renewAttacks() external;
  function attach() external;
  
  function earnedRewardPointsCounter() external;
  function burnRewardPoints(address _address) external returns (uint);
  
  function onlyMintNFTs(bool _bool) external;
  function setURI(uint _id, string memory _uri) external;
  function activateSecondPresale () external;
  function ActivateClaimReward(bool _bool)external;
  function reveal() external;
  
  function uPoints(address _user) external view returns (uint);
  function getAllNFTs() external view returns(uint[] memory);
  function uri(uint _id) external view returns (string memory);
  function areAvailableNFTs () external view returns (bool[] memory );
  function getRewardPoints(address _address) external view returns (uint);
  function getFuturePoints(address _address)external view returns(uint);
  
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data ) external;
}

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    
    // A1UtilityNFTs private a1UtilityNFTs;
    // A0TheStupidestKidsNFTs private a0TheStupidestKidsNFTs;
    A1UtilityNFTs public a1UtilityNFTs;
    A0TheStupidestKidsNFTs public a0TheStupidestKidsNFTs;
    TSKToken public tskToken;
    
    // address payable a2RewardLogic = payable(0x85732427df4874db73600685072D54b99e72C9cA);
    address payable public a2RewardPool; // TODO PONER WALLETque llevara el 2% a rewards o contrato
    address private owner;
    
    // Market fee 2% for buyers
    uint256 per = 2;
    uint256 listingPrice;
    
    // uint256 public airdropCounter = 0;
    // uint256 public airdropMaxTimes = 3;
    
    uint airdropTokensPerUser;
    uint tokenTSKToAirdrop;
    uint airdropTaken;
    uint airdropTokensUser = 1150 ;
    
    uint256 private minTokensToLiquidity = 5 * 10**3 * 10**18;
    
    mapping(address => bool) public airdropToken; 
    mapping(address => uint) public marketPoints; 
    
    // mapping(address => bool) public whitelist;

    constructor() {
        // nftOwner = payable(msg.sender);
        listingPrice = per / 100;
        owner = msg.sender;
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable nftSeller;
        address payable nftOwner;
        uint256 price;
        bool sold;
        bool pNFT;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address nftSeller,
        address nftOwner,
        uint256 price,
        bool sold
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    // TODO revisar si solo con esto ya funciona
    // TODO agregar * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the acceptance magic value.
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    
    function setToken(A1UtilityNFTs _a1UtilityNFTs, A0TheStupidestKidsNFTs _a0TheStupidestKidsNFTs, TSKToken _tskToken, address payable _address) public onlyOwner {
        a1UtilityNFTs = _a1UtilityNFTs;
        a0TheStupidestKidsNFTs = _a0TheStupidestKidsNFTs;
        tskToken = _tskToken;
        a2RewardPool = _address;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }
    function changeListingPrice(uint _listingPrice) external onlyOwner{
        listingPrice = _listingPrice;
    }
    // 721 safeTransferFrom (from,to,id)
    // 1155 safeTransferFrom ( from,  to,  id, amount, data)
    // true pNFT, false uNFT
    // Antes de poner la 1era venta, me das allowance a tus tsk tokens.
    // TODO ERC1155 ALLOWANCE BEFORE DE LOS DOS CONTRATOS
    function createMarketItem(bool _pNFT,address _nftContract, uint256 _tokenId, uint256 _price, uint _amount) public payable nonReentrant {
        require(_price> 0,"Price must be at least 1 wei");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
    
        idToMarketItem[itemId] = MarketItem(
            itemId, 
            // TODO MODIFICAR VARIABLE
            _nftContract,
            _tokenId,
            payable(msg.sender),
            payable(address(0)),
            _price,
            false,
            _pNFT
        );
        if(_pNFT){
            a0TheStupidestKidsNFTs.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
            idToMarketItem[itemId].pNFT = true;
        }else{
            a1UtilityNFTs.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
            idToMarketItem[itemId].pNFT = false;
        }
        
        emit MarketItemCreated(itemId, _nftContract, _tokenId, msg.sender, address(0), _price, false);
    }
    // TODO TSK ALLOWANCE BEFORE DE LOS DOS CONTRATOS. Hace falta primero vincular un boton approve desde la web al contrato del token para que nos den permiso
        // tskToken.approve(address NFTMarket, uint256 amount);
    function createMarketSale(uint256 itemId, uint _amount) public payable nonReentrant {
        uint allowance = tskToken.allowance(msg.sender, address(this));
        require(allowance > 0, "Contract needs allowance to trade");
        uint lprice = idToMarketItem[itemId].price * listingPrice;
        // uint price = idToMarketItem[itemId].price + lprice;
        uint tokenId = idToMarketItem[itemId].tokenId;
        // require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        require(tskToken.balanceOf(msg.sender) >= idToMarketItem[itemId].price + lprice,"You don't have enough tokens");
        
        
        // idToMarketItem[itemId].nftSeller.transfer(msg.value); NO FUNCIONA, NO PODEMOS HACE LA transaccion TRANSFER por parte del usuario
        address payable _nftSeller = idToMarketItem[itemId].nftSeller;
        // tskToken.transfer(payable(_nftSeller), idToMarketItem[itemId].price);
        // NCESITAMOS TENER UN APPROVE PRIMERO
        
        tskToken.transferFrom(msg.sender, payable(_nftSeller), idToMarketItem[itemId].price);
        bool _pNFT = idToMarketItem[itemId].pNFT;
        if(_pNFT){
            a0TheStupidestKidsNFTs.safeTransferFrom(address(this), msg.sender, tokenId, _amount, "");
        }else{
            // tskToken.transfer(payable(nftOwner), lprice);
            tskToken.transferFrom(msg.sender, payable(a2RewardPool), lprice);
            a1UtilityNFTs.safeTransferFrom(address(this), msg.sender, tokenId, _amount, "");
        }
        
        idToMarketItem[itemId].nftOwner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
        marketPoints[msg.sender] ++;
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current(); 
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i+1].nftOwner == address(0)) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }
        return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if(idToMarketItem[i+1].nftOwner == msg.sender) {
                itemCount+=1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if(idToMarketItem[i +1].nftOwner == msg.sender) {
                uint currentId = idToMarketItem[i +1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;

    }

    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if(idToMarketItem[i+1].nftSeller == msg.sender) {
                itemCount+=1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if(idToMarketItem[i +1].nftSeller == msg.sender) {
                uint currentId = idToMarketItem[i +1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;

    }
    
    function removeFromMarket(uint _index) external{
        MarketItem[] memory _items = fetchMyNFTs();
        uint _NFTToRemove = _items[_index].itemId;
        bool _isPNFT = _items[_index].pNFT;
        uint _tokenId = _items[_index].tokenId;
        
        idToMarketItem[_NFTToRemove].nftOwner = payable(msg.sender);
        
        if(_isPNFT){
            a0TheStupidestKidsNFTs.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
            idToMarketItem[_NFTToRemove].sold = false;
        }else{
            a1UtilityNFTs.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
            idToMarketItem[_NFTToRemove].sold = false;
        }
    }
    // Se le resta los tokens que quedan guardados para el airdrop
        /* function sendTSKToa2RewardPool() external onlyOwner returns(bool){
            uint restUsers = getAirdropRestUsers();
            uint rest = restUsers * airdropTokensPerUser;
            uint pool = tskToken.balanceOf(address(this)) - rest;
            if(pool > minTokensToLiquidity){
                tskToken.transfer(payable(a2RewardLogic), pool);
                return true;
            }
            return false;
        } */
    /////////////
    // Airdrop  //
    /////////////
    // TODO TOKEN DECIMALES
    function calculateAirdropTokensPerUser(uint _amount) external onlyOwner{
        tokenTSKToAirdrop = _amount * 10**18;
        airdropTokensPerUser = tokenTSKToAirdrop / airdropTokensUser ;
    }
    
    function airdropTokens() public returns (bool) {
        // require(whitelist[msg.sender],"You're not in the whitelist");
        require(tskToken.balanceOf(address(this)) > 0, "There are no more airdrops available");
        require(!airdropToken[msg.sender], "You can't claims more airdrops");
        airdropToken[msg.sender] = true;
        
        tskToken.transfer(payable(msg.sender), airdropTokensPerUser);
        airdropTaken ++;
        return true;
    }
    function getAirdropRestUsers() public view returns(uint){
        uint restUsers = airdropTokensUser - airdropTaken;
        return restUsers;
    }
    function userAirdropAvailable() external view returns (bool){
        return airdropToken[msg.sender];
    }
    
    /* function addToWhitelist() public {
        require(!whitelist[msg.sender],"You're  in the whitelist");
        whitelist[msg.sender] = true;
    }
    
    function airdropTokens(address[] memory _recipients, uint256 _amount) public onlynftOwner returns (bool) {
        require(whitelist[msg.sender],"You're not in the whitelist");
        require(airdropCounter <= airdropMaxTimes,"is not possible to make more airdrops");
        uint256 _amountTransfer = _amount * 10**18;
        require(_amountTransfer <= 500 * 10**18,"500 tokens (max) that you can recieve in airdrop ");
        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0));
            tskToken.transfer(payable(_recipients[i]), _amountTransfer);
        }
        airdropCounter += 1 ;
        return true;
    } */
    
    /* function addToWhitelist(address[] memory _investor) public onlyOwner {
        for (uint _i = 0; _i < _investor.length; _i++) {
            require(_investor[_i] != address(0), 'Invalid address.');
            address _investorAddress = _investor[_i];
            whitelist[_investorAddress] = true;
        }
    } */
    
    
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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