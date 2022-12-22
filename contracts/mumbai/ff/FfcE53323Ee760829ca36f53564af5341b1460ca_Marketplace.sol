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
        uint256 _NFTId,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) external returns(bool);
    function getNFTcreator(uint256 NFTId) external view returns(address);
    function getNFTstatus(uint256 NFTId) external returns(bool);
    function create1155NFT(
        address _creator,
        uint256 _newNFTid,
        string calldata _tokenURI,
        uint256 _amount
    ) external;
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
import "./libary/utilities.sol";
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
    mapping(bytes20 => bool) public isListed;
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

    modifier onlyDev() {
        require(msg.sender == backend_address, "invalid dev address");
        _;
    }

    function setNFT1155Address(address _NFT1155Address) public onlyDev {
        NFT1155Address = _NFT1155Address;
    }

    function setCreatorFee(uint8 _creator_fee) public onlyDev {
        creator_fee = _creator_fee;
    }

    function setSystemFee(uint8 _system_fee) public onlyDev {
        system_fee = _system_fee;
    }

    function listing(bytes calldata _signature) public onlyDev {
        require(_signature.length == 65, "signature length invalid");
        isListed[ripemd160(_signature)] = true;
        emit Listing(ripemd160(_signature), true);
    }

    function checkListed(bytes calldata _signature)
        public
        view
        virtual
        returns (bool)
    {
        return isListed[ripemd160(_signature)];
    }

    function cancelListing(bytes calldata _signature) public {
        require(_signature.length == 65, "signature length invalid");
        isListed[ripemd160(_signature)] = false;
        emit CancelListing(ripemd160(_signature), false);
    }

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
            (_sell.amount == _buy.amount) &&
            (_sell.nonce == _buy.nonce) &&
            (_sell.payment_token == _buy.payment_token));
    }

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

    function _atomicMatch(
        utilities.Order memory _sell,
        utilities.Order memory _buy,
        bytes calldata _signature,
        string calldata _tokenURI
    ) internal {
        require(isListed[ripemd160(_signature)], "not listed");
        require(_orderCanMatch(_sell, _buy), "Order not matching");
        isListed[ripemd160(_signature)] = false;
        if (!INFT1155(NFT1155Address).getNFTstatus(_sell.NFTId)) {
            INFT1155(NFT1155Address).create1155NFT(
                _sell.maker,
                _sell.NFTId,
                _tokenURI,
                _sell.amount
            );
        }
        require(
            INFT1155(NFT1155Address).transferWithPermission(
                _sell.maker,
                _sell.taker,
                _sell.NFTId,
                _sell.amount,
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
                _sell.price
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

    function atomicMatch(
        address[6] calldata _addrs,
        uint256[12] calldata _uints,
        bytes calldata _signature,
        string calldata _tokenURI
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
            _signature,
            _tokenURI
        );
    }
}