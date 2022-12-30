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
pragma solidity ^0.8.7;
interface INFT1155{
    function transferWithPermission(
        address _from,
        address _to,
        address _payment_token,
        uint256 _NFTId,
        uint256 _amount,
        uint256 _price,
        uint256 _nonce,
        bytes calldata _signature
    ) external returns(bool);
    function getNFTcreator(uint256 NFTId) external view returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface ISVC{
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address owner, address buyer, uint256 numTokens) external returns (bool);
    function approve(address delegate, uint256 numTokens) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library utilities {
    struct COLLECTION {
        uint256 collectionId;
        address collectionOwner;
    }
    struct Order {
        address maker;
        address taker;
        uint256 price;
        uint256 listing_time;
        uint256 expiration_time;
        uint256 NFTId;
        uint256 amount;
        uint256 nonce;
        address payment_token;
    }
      
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/Counters.sol";
import "./library/utilities.sol";
import "./ISVC.sol";
import "./INFT1155.sol";

pragma solidity ^0.8.7;

contract Marketplace {
    address public backend_address;
    address public NFT1155Address;
    address payable public FeeRecipientAddress;
    uint256 public creator_fee;
    uint256 public system_fee;
    mapping(address => uint256) nonces;
    mapping(bytes20 => uint256) public isListed;
    event Listing(bytes20 signature, bool isListed);
    event CancelListing(bytes20 signature, bool isListed);
    event AtomicMatch(
        address maker,
        address taker,
        uint256 NFTId,
        uint256 amount,
        uint256 price,
        bool bestMatch
    );

    constructor(
        address _backend_address,
        address _NFT1155Address,
        address payable _FeeRecipientAddress,
        uint256 _creator_fee,
        uint256 _system_fee
    ) {
        backend_address = _backend_address;
        NFT1155Address = _NFT1155Address;
        FeeRecipientAddress = _FeeRecipientAddress;
        creator_fee = _creator_fee;
        system_fee = _system_fee;
    }
    /**
     * @dev Throws if called by any account other than the dev.
     */
    modifier onlyDev() {
        require(msg.sender == backend_address, "invalid dev address");
        _;
    }
    /**
     * @dev set contract NFT address 
     * @param _NFT1155Address contract NFT address
     */
    function setNFT1155Address(address _NFT1155Address) public onlyDev {
        NFT1155Address = _NFT1155Address;
    }
    /**
     * @dev set creator fee 
     * @param _creator_fee creator fee
     */
    function setCreatorFee(uint8 _creator_fee) public onlyDev {
        creator_fee = _creator_fee;
    }
    /**
     * @dev set system fee 
     * @param _system_fee fee
     */
    function setSystemFee(uint8 _system_fee) public onlyDev {
        system_fee = _system_fee;
    }
    /**
     * @dev set listing status on-chain  
     * @param _signature NFT owner signature include owner address, spender address (NFT contract address), NFT id, price
     */

    function listing(bytes calldata _signature, uint256 _amount) public onlyDev {
        require(_signature.length == 65, "signature length invalid");
        isListed[ripemd160(_signature)] = _amount;
        emit Listing(ripemd160(_signature), true);
    }
    /**
     * @dev check listing status  
     * @param _signature NFT owner signature
     */
    function checkListed(bytes calldata _signature)
        public
        view
        virtual
        returns (bool)
    {
        bool isNFTListed = isListed[ripemd160(_signature)] == 0 ? false :true;
        return isNFTListed;
    }
    function checkListingAmount(bytes calldata _signature)
        public
        view
        virtual
        returns (uint256)
    {
        
        return isListed[ripemd160(_signature)];
    }
    /**
     * @dev cancel listing  
     * @param _signature NFT owner signature
     */
    function cancelListing(bytes calldata _signature) public {
        require(_signature.length == 65, "signature length invalid");
        delete isListed[ripemd160(_signature)];
        emit CancelListing(ripemd160(_signature), false);
    }
    /**
     * @dev Check if 2 Order are Matching 
     * @param _buy Buy side order
     * @param _sell sell side order
     */
    function _orderCanMatch(
        utilities.Order memory _sell,
        utilities.Order memory _buy
    ) internal pure returns (bool) {
        return ((_sell.maker == _buy.taker) &&
            (_sell.taker == _buy.maker) &&
            (_sell.price == _buy.price) &&
            (_sell.listing_time <= _buy.listing_time) &&
            (_sell.expiration_time >= _buy.expiration_time) &&
            (_sell.NFTId == _buy.NFTId) &&
            (_sell.amount >= _buy.amount) &&
            (_sell.nonce == _buy.nonce) &&
            (_sell.payment_token == _buy.payment_token));
    }
    /**
     * @dev Execute all ERC20 token / MATIC transfers associated with an order match 
     * @param _buyer Buyer
     * @param _payment_token token use for payment (if MATIC, address set to address(0))
     * @param _NFT_creator NFT creator
     * @param _seller NFT seller
     * @param _price NFT price
     */
    function _transferToken(
        address _buyer,
        address _payment_token,
        address payable _NFT_creator,
        address payable _seller,
        uint256 _price
    ) internal returns (bool) {
        if (_payment_token != address(0)) {
            uint256 amountToSystem = (_price * system_fee) / 100 ether;
            uint256 amountToCreator = (_price * creator_fee) / 100 ether;
            uint256 amountToSeller = _price - amountToSystem - amountToCreator;

            ISVC(_payment_token).transferFrom(_buyer, _seller, amountToSeller);
            ISVC(_payment_token).transferFrom(
                _buyer,
                _NFT_creator,
                amountToCreator
            );
            ISVC(_payment_token).transferFrom(
                _buyer,
                FeeRecipientAddress,
                amountToSystem
            );
        } else {
            uint256 amountToSystem = (_price * system_fee) / 100 ether;
            uint256 amountToCreator = (_price * creator_fee) / 100 ether;
            uint256 amounToSeller = _price - amountToSystem - amountToCreator;

            require(msg.value >= _price, "insufficient native token");
            _seller.transfer(amounToSeller);
            _NFT_creator.transfer(amountToCreator);
            FeeRecipientAddress.transfer(amountToSystem);
        }
        return true;
    }
    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param _buy Buy-side order
     * @param _sell Sell-side order
     * @param _signature NFT owner signature
     */
    function _atomicMatch(
        utilities.Order memory _sell,
        utilities.Order memory _buy,
        bytes calldata _signature
    ) internal {
        require(checkListed(_signature), "not listed");
        require(_orderCanMatch(_sell, _buy), "Order not matching");
        require(isListed[ripemd160(_signature)] >= _sell.amount , "invalid amount");
        if(isListed[ripemd160(_signature)] - _sell.amount >0){
            isListed[ripemd160(_signature)] =  isListed[ripemd160(_signature)] - _sell.amount;
        }
        else{
            delete isListed[ripemd160(_signature)];
        }
        
        require(
            INFT1155(NFT1155Address).transferWithPermission(
                _sell.maker,
                _sell.taker,
                _sell.payment_token,
                _sell.NFTId,
                _buy.amount,
                _sell.price,
                _sell.nonce,
                _signature
            ),
            "transfer NFT fail"
        );
        require(
            _transferToken(
                _sell.taker,
                _sell.payment_token,
                payable(INFT1155(NFT1155Address).getNFTcreator(_sell.NFTId)),
                payable(_sell.maker),
                _sell.price*_buy.amount
            )
        );
        
        emit AtomicMatch(
            _sell.maker,
            _sell.taker,
            _sell.NFTId,
            _sell.amount,
            _sell.price,
            true
        );
    }
    /**
     * @dev Call _atomicMatch - for buy NFT 
     */
    function atomicMatch(
        address[6] calldata _addrs,
        uint256[12] calldata _uints,
        bytes calldata _signature
    ) public payable {
        _atomicMatch(
            utilities.Order(
                _addrs[0],
                _addrs[1],
                _uints[0],
                _uints[1],
                _uints[2],
                _uints[3],
                _uints[4],
                _uints[5],
                _addrs[2]
            ),
            utilities.Order(
                _addrs[3],
                _addrs[4],
                _uints[6],
                _uints[7],
                _uints[8],
                _uints[9],
                _uints[10],
                _uints[11],
                _addrs[5]
            ),
            _signature
        );
    }
}