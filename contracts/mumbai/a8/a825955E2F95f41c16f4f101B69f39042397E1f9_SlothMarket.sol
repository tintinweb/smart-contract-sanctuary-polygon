/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/utils/Address.sol
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: @openzeppelin/contracts/utils/Strings.sol
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

abstract contract Market {
     enum MarketItemType { NFT, EVENT, TOKEN }
     enum MarketItemSaleType { RAFFLE, INSTANT }
     enum MarketItemStatus { OPEN, FULL, WINNERSPICKED }

     mapping(uint256 => MarketItem) private _marketItems;
     mapping(uint256 => address[]) private _spotsTaken;
     mapping(uint256 => address[]) private _winners;

     struct MarketItem {    
        //global        
        string title; 
        string chain;   
        address contractAddress;    
        uint256 price;        
            
        MarketItemType itemType;
        MarketItemSaleType saleType;   
        MarketItemStatus status;
        //NFT       
        uint256 tokenId;       
        //RAFFLE
        uint256 spots;        
        uint256 spotsFilled;
        uint256 maxSpotsPerWallet;
        uint256 totalWinners;       
        //Tokens
        uint256 amount; //amount of tokens   
     }

     function createItem(uint256 identifier, MarketItem memory item) internal {
         MarketItem memory existingItem = getMarketItem(identifier);
         if(existingItem.spots > 0)
         {
            item.spotsFilled = existingItem.spotsFilled;
         }
            
         _marketItems[identifier] = item;
     }

     function deleteItem(uint256 identifier) internal {
         delete _marketItems[identifier];
     }

     function updateItemStatus(uint256 identifier, MarketItemStatus status) internal {
         _marketItems[identifier].status = status;
     }

     function getMarketItem(uint256 identifier) internal view returns (MarketItem memory) {
         return _marketItems[identifier];
     }

     function setWinners(uint256 identifier, address[] memory winners) internal {
         for(uint i=0; i<winners.length; i++){
             _winners[identifier].push(winners[i]);
         }
     }

     function getWinners(uint256 identifier) public view returns (address[] memory) {
         address[] memory winners = new address[](_winners[identifier].length);
         for(uint i=0; i<_winners[identifier].length; i++){             
            winners[i] = _winners[identifier][i];
         }
         return winners;
     }

     function getMarketItems(uint256[] memory identifiers) public view returns (MarketItem[] memory) {
         MarketItem[] memory items = new MarketItem[](identifiers.length);
         for(uint i=0; i<identifiers.length; i++){
             items[i] = _marketItems[identifiers[i]];
         }
         return items;
     }

     function allocSpots(uint256 identifier, address sender, uint256 spots) internal {
         MarketItem memory mi = getMarketItem(identifier);  
         for(uint i=0; i<spots; i++) {
            _spotsTaken[identifier].push(sender);
         }
         //status update when full
         if(_spotsTaken[identifier].length == mi.spots)
             _marketItems[identifier].status = MarketItemStatus.FULL;

         _marketItems[identifier].spotsFilled = _spotsTaken[identifier].length;
     }

     function getAllocatedSpots(uint256 identifier) internal view returns (uint256) {
        return _spotsTaken[identifier].length;    
     }

     function getAllocatedSpotsByOwner(uint256 identifier, address owner) internal view returns (uint256) {
        uint count = 0;
        for(uint i=0; i<_spotsTaken[identifier].length; i++){
            if(_spotsTaken[identifier][i] == owner)
                count++;
        }    
        return count;
     }
}

abstract contract SlothToken {    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool);

    function allowance(
        address owner, 
        address spender
    ) public virtual returns (uint256);

    function balanceOf(
        address account
    ) public virtual returns (uint256);
}

abstract contract CasualDeeds {    
    function mint(
        address recipient,
        string memory chain,
        address contractAddress,
        uint256 tokenId
    ) public virtual;

    function burn(
        uint256 tokenId
    ) public virtual; 
}

// File: SlothMarket.sol
contract SlothMarket is Market, Ownable {  
    address private _stakingWallet; 
    address private _tokenContract;    
    address private _deedContract;   

    constructor() {        
        _tokenContract = 0xbc9F34e4fEf6B021175F682d5627114C9Da54481;
        _stakingWallet = 0x33DBD49EE7e8618136c09389745855f9897e9f86;
        _deedContract = 0x59862f4b6f4Ef80f549433a9d75d9e657df842f2;
    }

    function buyTokens(uint256 identifier) public payable {       
        MarketItem memory mi = getMarketItem(identifier);
        require(mi.itemType == MarketItemType.TOKEN, "Invalid item type");  
        require(mi.saleType == MarketItemSaleType.INSTANT, "Invalid item sale type");   
        require(mi.price == msg.value, "Sent ether val is incorrect");  
        require((getAllocatedSpots(identifier) + 1) <= mi.spots, "Not enough spots left");
        require((getAllocatedSpotsByOwner(identifier, msg.sender) + 1) <= mi.maxSpotsPerWallet, "To much entries for wallet"); 

        //transfer sloth tokens
        SlothToken(_tokenContract).transferFrom(_stakingWallet, msg.sender, mi.amount);

        //alloc spots for wallet
        allocSpots(identifier, msg.sender, 1);
    }

    function buySpot(uint256 identifier, uint256 quantity) public {       
        MarketItem memory mi = getMarketItem(identifier);  
        uint256 totalPrice = quantity * mi.price;
 
        require(mi.saleType == MarketItemSaleType.RAFFLE, "Invalid item sale type");   
        require(SlothToken(_tokenContract).balanceOf(msg.sender) >= totalPrice, "Not enough balance");
        require(SlothToken(_tokenContract).allowance(msg.sender, address(this)) >= totalPrice, "Not enough allowance");   
        require((getAllocatedSpots(identifier) + quantity) <= mi.spots, "Not enough spots left");
        require((getAllocatedSpotsByOwner(identifier, msg.sender) + quantity) <= mi.maxSpotsPerWallet, "To much entries for wallet");        

        //transfer sloth tokens
        SlothToken(_tokenContract).transferFrom(msg.sender, _stakingWallet, totalPrice);

        //alloc spots for wallet
        allocSpots(identifier, msg.sender, quantity);
    }

    function directBuy(uint256 identifier) public {
        MarketItem memory mi = getMarketItem(identifier); 

        require(mi.itemType != MarketItemType.TOKEN, "Invalid item type"); 
        require(mi.saleType == MarketItemSaleType.INSTANT, "Invalid item sale type"); 
        require(SlothToken(_tokenContract).balanceOf(msg.sender) >= mi.price, "Not enough balance");
        require(SlothToken(_tokenContract).allowance(msg.sender, address(this)) >= mi.price, "Not enough allowance");   
        require((getAllocatedSpots(identifier) + 1) <= mi.spots, "Not enough spots left");
        require((getAllocatedSpotsByOwner(identifier, msg.sender) + 1) <= mi.maxSpotsPerWallet, "To much entries for wallet");    

        //transfer sloth tokens
        SlothToken(_tokenContract).transferFrom(msg.sender, _stakingWallet, mi.price);
        
        //alloc spots for wallet
        allocSpots(identifier, msg.sender, 1);

        //mint placeholder
        if(mi.itemType == MarketItemType.NFT){           
             CasualDeeds(_deedContract).mint(msg.sender, mi.chain, mi.contractAddress, mi.tokenId);
        }        
    }

    function pickWinners(uint256 identifier, address[] memory winners) public onlyOwner {
        MarketItem memory mi = getMarketItem(identifier); 
        require(mi.saleType == MarketItemSaleType.RAFFLE, "Invalid item sale type"); 

        setWinners(identifier, winners);
        updateItemStatus(identifier, MarketItemStatus.WINNERSPICKED);

        //mint placeholder
        if(mi.itemType == MarketItemType.NFT && winners.length == 1){            
            CasualDeeds(_deedContract).mint(msg.sender, mi.chain, mi.contractAddress, mi.tokenId);
        }  

        //transfer sloth tokens
        if(mi.itemType == MarketItemType.TOKEN && winners.length == 1){            
            SlothToken(_tokenContract).transferFrom(_stakingWallet, msg.sender, mi.amount);
        }
    }

    function createMarketItem(uint256 identifier, MarketItem memory item) public onlyOwner {  
        createItem(identifier, item);
    }  

    function updateMarketItemStatus(uint256 identifier, MarketItemStatus status) public onlyOwner {  
        updateItemStatus(identifier, status);
    }   

    function deleteMarketItem(uint256 identifier) public onlyOwner {  
        deleteItem(identifier);
    }   

    function burnDeed(uint256 tokenId) public onlyOwner {
        CasualDeeds(_deedContract).burn(tokenId);
    }

    function setTokenContract(address _contract) public onlyOwner {
        _tokenContract = _contract;
    }

    function setStakingWallet(address _wallet) public onlyOwner {
        _stakingWallet = _wallet;
    }

    function setDeedContract(address _contract) public onlyOwner {
        _deedContract = _contract;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }   
}