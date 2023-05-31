// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// CryptoAvatars interfaces
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
import {IExecutionManager} from "./interfaces/IExecutionManager.sol";
import {IExecutionStrategy} from "./interfaces/IExecutionStrategy.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {ICryptoAvatarsExchange} from "./interfaces/ICryptoAvatarsExchange.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";
import {ITransferSelectorNFT} from "./interfaces/ITransferSelectorNFT.sol";
import {ICollectionManager} from "./interfaces/ICollectionManager.sol";
import {IWETH} from "./interfaces/IWETH.sol";

// CryptoAvatars libraries
import {OrderTypes} from "./libraries/OrderTypes.sol";
import {SignatureChecker} from "./libraries/SignatureChecker.sol";

/**
 * @title CryptoAvatars
 * @notice It is the core contract of the CryptoAvatars exchange.
 */
contract CryptoAvatarsExchange is ICryptoAvatarsExchange, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    address public immutable WETH;
    bytes32 public immutable DOMAIN_SEPARATOR;

    address public protocolFeeRecipient;
    address public signer;

    ICurrencyManager public currencyManager;
    IExecutionManager public executionManager;
    IRoyaltyFeeManager public royaltyFeeManager;
    ITransferSelectorNFT public transferSelectorNFT;
    ICollectionManager public collectionManager;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;

    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
    event NewCurrencyManager(address indexed currencyManager);
    event NewExecutionManager(address indexed executionManager);
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event NewRoyaltyFeeManager(address indexed royaltyFeeManager);
    event NewCollectionManager(address indexed collectionManager);
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);

    event RoyaltyPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    event MarketSell(
        bytes makerOrder, // maker order data
        bytes takerOrder // taker order data
    );

    /**
     * @notice Constructor
     * @param _currencyManager currency manager address
     * @param _executionManager execution manager address
     * @param _royaltyFeeManager royalty fee manager address
     * @param _WETH wrapped ether address (for other chains, use wrapped native asset)
     * @param _protocolFeeRecipient protocol fee recipient
     */
    constructor(
        address _currencyManager,
        address _executionManager,
        address _royaltyFeeManager,
        address _collectionManager,
        address _WETH,
        address _protocolFeeRecipient,
        address _signer
    ) {
        // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x479e4b32420d5d35c74f62189f17325d7fd3b51ff82b6be4bcab394dc45ea1d9, // keccak256("CryptoAvatars")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        currencyManager = ICurrencyManager(_currencyManager);
        executionManager = IExecutionManager(_executionManager);
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        collectionManager = ICollectionManager(_collectionManager);
        WETH = _WETH;
        protocolFeeRecipient = _protocolFeeRecipient;
        signer = _signer;
    }

    /**
     * @notice Cancel all pending orders for a sender
     * @param minNonce minimum user nonce
     */
    function cancelAllOrdersForSender(uint256 minNonce) external {
        require(minNonce > userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
        require(minNonce < userMinOrderNonce[msg.sender] + 500000, "Cancel: Cannot cancel more orders");
        userMinOrderNonce[msg.sender] = minNonce;
        emit CancelAllOrders(msg.sender, minNonce);
    }

    /**
     * @notice Cancel maker orders
     * @param orderNonces array of order nonces
     */
    function cancelMultipleMakerOrders(uint256[] calldata orderNonces) external {
        require(orderNonces.length > 0, "Cancel: Cannot be empty");

        for (uint256 i = 0; i < orderNonces.length; i++) {
            require(orderNonces[i] >= userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
            _isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
        }
        emit CancelMultipleOrders(msg.sender, orderNonces);
    }

    /**
     * @notice Match ask with a taker bid order using ETH
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable override nonReentrant {
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: Wrong sides");
        require(makerAsk.currency == WETH, "Order: Currency must be WETH");
        require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

        // If not enough ETH to cover the price, use WETH
        if (takerBid.price > msg.value) {
            IERC20(WETH).safeTransferFrom(msg.sender, address(this), (takerBid.price - msg.value));
        } else {
            require(takerBid.price == msg.value, "Order: Msg.value too high");
        }

        // Wrap ETH sent to this contract
        IWETH(WETH).deposit{value: msg.value}();

        // Check maker ask and taker bid orders
        _validateOrder(makerAsk, takerBid);

        // Retrieve execution parameters
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy)
            .canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        // Execution part 1/2
        _transferFeesAndFundsWithWETH(
           makerAsk,
           takerBid, 
           makerAsk.signer
        );

        // Execution part 2/2
        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        // Emit event
        emit MarketSell(abi.encode(makerAsk), abi.encode(takerBid));

    }

    /**
     * @notice Match a takerBid with a matchAsk
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        override
        nonReentrant
    {
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: Wrong sides");
        require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

        // Check the maker ask order
        _validateOrder(makerAsk, takerBid);


        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy)
            .canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        // Execution part 1/2
        _transferFeesAndFunds(makerAsk, takerBid, takerBid.taker, makerAsk.signer);

        // Execution part 2/2
        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        // Emit event
        emit MarketSell(abi.encode(makerAsk), abi.encode(takerBid));
    }

    /**
     * @notice Match a takerAsk with a makerBid
     * @param takerAsk taker ask order
     * @param makerBid maker bid order
     */
    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        override
        nonReentrant
    {
        require((!makerBid.isOrderAsk) && (takerAsk.isOrderAsk), "Order: Wrong sides");
        require(msg.sender == takerAsk.taker, "Order: Taker must be the sender");

        // Check the maker bid order
        _validateOrder(makerBid, takerAsk);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerBid.strategy)
            .canExecuteTakerAsk(takerAsk, makerBid);

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker bid order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;

        // Execution part 1/2
        _transferNonFungibleToken(makerBid.collection, takerAsk.taker, makerBid.signer, tokenId, amount);
        
        // Execution part 2/2
        _transferFeesAndFunds(makerBid, takerAsk, makerBid.signer, takerAsk.taker);

        // Emit event
        emit MarketSell(abi.encode(makerBid), abi.encode(takerAsk));

    }

    /**
    * @notice Update signer
    * @param _signer new marketplace signer
    */
    function updateSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Owner: Cannot be null address");
        signer = _signer;
    }

    /**
     * @notice Update currency manager
     * @param _currencyManager new currency manager address
     */
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Owner: Cannot be null address");
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    /**
     * @notice Update execution manager
     * @param _executionManager new execution manager address
     */
    function updateExecutionManager(address _executionManager) external onlyOwner {
        require(_executionManager != address(0), "Owner: Cannot be null address");
        executionManager = IExecutionManager(_executionManager);
        emit NewExecutionManager(_executionManager);
    }

    /**
     * @notice Update collection manager
     * @param _collectionManager new collection manager address
     */
    function updateCollectionManager(address _collectionManager) external onlyOwner {
        require(_collectionManager != address(0), "Owner: Cannot be null address");
        collectionManager = ICollectionManager(_collectionManager);
        emit NewCollectionManager(_collectionManager);
    }

    /**
     * @notice Update protocol fee and recipient
     * @param _protocolFeeRecipient new recipient for protocol fees
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @notice Update royalty fee manager
     * @param _royaltyFeeManager new fee manager address
     */
    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Owner: Cannot be null address");
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    /**
     * @notice Update transfer selector NFT
     * @param _transferSelectorNFT new transfer selector address
     */
    function updateTransferSelectorNFT(address _transferSelectorNFT) external onlyOwner {
        require(_transferSelectorNFT != address(0), "Owner: Cannot be null address");
        transferSelectorNFT = ITransferSelectorNFT(_transferSelectorNFT);   
        emit NewTransferSelectorNFT(_transferSelectorNFT);
    }

    /**
     * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param takerOrder taker order 
     * @param makerOrder maker order
     * @param from _msgSender()  
     */
    function _transferFeesAndFunds(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.TakerOrder calldata takerOrder, 
        address from, 
        address to
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = makerOrder.price;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(makerOrder.strategy, makerOrder.price);

            // Check if the protocol fee is different than 0 for this strategy
            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                IERC20(makerOrder.currency).safeTransferFrom(from, protocolFeeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fee
        {        
            if(!isZeroBytes(takerOrder.dataCryptoAvatars)) { // Is CryptoAvatars, pay a fee to the avatar creator
                (address creator , uint256 royaltyFee) = abi.decode(takerOrder.dataCryptoAvatars, (address, uint256));
                uint256 royaltyCreatorFeeAmount = (makerOrder.price * royaltyFee) / 10000 ;
                if ((creator != address(0)) && (royaltyCreatorFeeAmount != 0)) {
                    IERC20(makerOrder.currency).safeTransferFrom(from, creator, royaltyCreatorFeeAmount);
                    finalSellerAmount -= royaltyCreatorFeeAmount;
                }
            }
            else if(!isZeroBytes(takerOrder.dataRemix)) { // Is Remix, pay a fee to the remix creator and to the collection owner
                (address creatorRemix, address ownerRemix) = abi.decode(takerOrder.dataRemix, (address, address));
                uint256 royaltyCreatorFee = royaltyFeeManager.getRemixCreatorRoyaltyFee();
                uint256 royaltyOwnerFee = royaltyFeeManager.getRemixOwnerRoyaltyFee();
                uint256 royaltyCreatorFeeAmount = (makerOrder.price * royaltyCreatorFee) / 10000 ;
                uint256 royaltyOwnerFeeAmount =  (makerOrder.price * royaltyOwnerFee) / 10000 ;
                IERC20(makerOrder.currency).safeTransferFrom(from, creatorRemix, royaltyCreatorFeeAmount);
                IERC20(makerOrder.currency).safeTransferFrom(from, ownerRemix, royaltyOwnerFeeAmount);
                finalSellerAmount -= royaltyCreatorFeeAmount + royaltyOwnerFeeAmount;
            }
            else { // It is a non CA collection, pay a fee to the collection owner
                (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
                    .calculateRoyaltyFeeAndGetRecipient(makerOrder.collection, makerOrder.tokenId, makerOrder.price);
                // Check if there is a royalty fee and that it is different to 0
                if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
                    IERC20(makerOrder.currency).safeTransferFrom(from, royaltyFeeRecipient, royaltyFeeAmount);
                    finalSellerAmount -= royaltyFeeAmount;
                emit RoyaltyPayment(makerOrder.collection, makerOrder.tokenId, royaltyFeeRecipient, makerOrder.currency, royaltyFeeAmount);
                }
            }
        }
        
        require((finalSellerAmount * 10000) >= (makerOrder.minPercentageToAsk * makerOrder.price), "Fees: Higher than expected");

        // 3. Transfer final amount (post-fees) to seller
        {
            IERC20(makerOrder.currency).safeTransferFrom(from, to, finalSellerAmount);
        }
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param makerOrder maker order
     * @param takerOrder taker order
     */
    function _transferFeesAndFundsWithWETH(
       OrderTypes.MakerOrder calldata makerOrder,
       OrderTypes.TakerOrder calldata takerOrder, 
       address to
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = makerOrder.price;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(makerOrder.strategy, makerOrder.price);

            // Check if the protocol fee is different than 0 for this strategy
            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                IERC20(WETH).safeTransfer(protocolFeeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fee
        {  
            if(!isZeroBytes(takerOrder.dataCryptoAvatars)) { // Is CryptoAvatars, pay a fee to the avatar creator
                (address creator , uint256 royaltyFee) = abi.decode(takerOrder.dataCryptoAvatars, (address, uint256));
                uint256 royaltyCreatorFeeAmount = (makerOrder.price * royaltyFee) / 10000 ;
                if ((creator != address(0)) && (royaltyCreatorFeeAmount != 0)) {
                    IERC20(WETH).safeTransfer(creator, royaltyCreatorFeeAmount);
                    finalSellerAmount -= royaltyCreatorFeeAmount;
                }
            }
            else if(!isZeroBytes(takerOrder.dataRemix)) { // Is Remix, pay a fee to the remix creator and to the collection owner
                (address creatorRemix, address ownerRemix) = abi.decode(takerOrder.dataRemix, (address, address));
                uint256 royaltyCreatorFee = royaltyFeeManager.getRemixCreatorRoyaltyFee();
                uint256 royaltyOwnerFee = royaltyFeeManager.getRemixOwnerRoyaltyFee();
                uint256 royaltyCreatorFeeAmount = (makerOrder.price * royaltyCreatorFee) / 10000 ;
                uint256 royaltyOwnerFeeAmount =  (makerOrder.price * royaltyOwnerFee) / 10000 ;
                IERC20(WETH).safeTransfer(creatorRemix, royaltyCreatorFeeAmount);
                IERC20(WETH).safeTransfer(ownerRemix, royaltyOwnerFeeAmount);
                finalSellerAmount -= royaltyCreatorFeeAmount + royaltyOwnerFeeAmount;
            }
            else { // It is a non CA collection, pay a fee to the collection owner
                (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
                    .calculateRoyaltyFeeAndGetRecipient(makerOrder.collection, makerOrder.tokenId, makerOrder.price);
                // Check if there is a royalty fee and that it is different to 0
                if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
                    IERC20(WETH).safeTransfer(royaltyFeeRecipient, royaltyFeeAmount);
                    finalSellerAmount -= royaltyFeeAmount;
                emit RoyaltyPayment(makerOrder.collection, makerOrder.tokenId, royaltyFeeRecipient, WETH, royaltyFeeAmount);
                }
            }
        }

        require((finalSellerAmount * 10000) >= (makerOrder.minPercentageToAsk * makerOrder.price), "Fees: Higher than expected");

        // 3. Transfer final amount (post-fees) to seller
        {
            IERC20(WETH).safeTransfer(to, finalSellerAmount);
        }
    }

    /**
     * @notice Transfer NFT
     * @param collection address of the token collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of tokens (1 for ERC721, 1+ for ERC1155)
     * @dev For ERC721, amount is not used
     */
    function _transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        // Retrieve the transfer manager address
        address transferManager = transferSelectorNFT.checkTransferManagerForToken(collection);

        // If no transfer manager found, it returns address(0)
        require(transferManager != address(0), "Transfer: No NFT transfer manager available");

        // If one is found, transfer the token
        ITransferManagerNFT(transferManager).transferNonFungibleToken(collection, from, to, tokenId, amount);
    }

    /**
     * @notice Calculate protocol fee for an execution strategy
     * @param executionStrategy strategy
     * @param amount amount to transfer
     */
    function _calculateProtocolFee(address executionStrategy, uint256 amount) internal view returns (uint256) {
        uint256 protocolFee = IExecutionStrategy(executionStrategy).viewProtocolFee();
        return (protocolFee * amount) / 10000;
    }

    /**
     * @notice Verify the validity of the maker order and the taker order
     * @param makerOrder maker order
     * @param takerOrder taker order
     */
    function _validateOrder(OrderTypes.MakerOrder calldata makerOrder, 
                            OrderTypes.TakerOrder calldata takerOrder) internal view {
        // Verify whether order nonce has expired
        require(
            (!_isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.nonce]) &&
                (makerOrder.nonce >= userMinOrderNonce[makerOrder.signer]),
            "Order: Matching order expired"
        );

        // Verify the signer is not address(0)
        require(makerOrder.signer != address(0), "Order: Invalid signer");

        // Verify the amount is not 0
        require(makerOrder.amount > 0, "Order: Amount cannot be 0");

        // Verify signature max valid time
        require(block.timestamp<=takerOrder.maxValidTime, "Order: Invalid signature");

        bytes32 makerOrderHash = makerOrder.hashMakerOrder();
        // Verify the validity of the signatures
        // Verify makerOrder signature
        require(
            SignatureChecker.verifySignature712(
                makerOrderHash,
                makerOrder.signer,
                makerOrder.v,
                makerOrder.r,
                makerOrder.s,
                DOMAIN_SEPARATOR
            ),
            "MakerOrder Signature: Invalid"
        );
        bytes32 takerOrderHash = takerOrder.hashTakerOrder();
        // Verify takerOrder signature
        require(
            SignatureChecker.verifySignature191(
                takerOrderHash,
                signer,
                takerOrder.v,
                takerOrder.r,
                takerOrder.s
     ),
            "TakerOrder Signature: Invalid"
        );

        // Verify whether the currency is whitelisted
        require(currencyManager.isCurrencyWhitelisted(makerOrder.currency), "Currency: Not whitelisted");

        // Verify whether strategy can be executed
        require(executionManager.isStrategyWhitelisted(makerOrder.strategy), "Strategy: Not whitelisted");

        // Verify whether the collection is whitelisted
        require(collectionManager.isCollectionWhitelisted(makerOrder.collection),"Collection: Not whitelisted");
    }

    function isZeroBytes(bytes calldata data) public pure returns (bool) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] != 0) {
                return false;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExecutionManager {
    function addStrategy(address strategy) external;

    function removeStrategy(address strategy) external;

    function isStrategyWhitelisted(address strategy) external view returns (bool);

    function viewWhitelistedStrategies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedStrategies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrencyManager {
    function addCurrency(address currency) external;

    function removeCurrency(address currency) external;

    function isCurrencyWhitelisted(address currency) external view returns (bool);

    function viewWhitelistedCurrencies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedCurrencies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface ICryptoAvatarsExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external;

    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferSelectorNFT {
    function checkTransferManagerForToken(address collection) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);

    function getRemixCreatorRoyaltyFee()external view returns(uint256);

    function getRemixOwnerRoyaltyFee()external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the CryptoAvatars exchange.
 */
library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;
    //keccak256("TakerOrder(bool isOrderAsk,address taker,address signer,uint256 price,uint256 tokenId,uint256 maxValidTime,uint256 minPercentageToAsk,bytes params,bytes dataCryptoAvatars,bytes dataRemix)")
    bytes32 internal constant TAKER_ORDER_HASH = 0x52899feb3ddfece805ec742fd953f7c2d538f6a548044216a6b8db2598b449d9;
    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        address signer;
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 maxValidTime; // validTime in timestamp
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
        bytes dataCryptoAvatars; // data for CryptoAvatars NFT
        bytes dataRemix; // check if the NFT is a remix and if so, the creator and the owner of the parent remix avatar for royalties
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hashMakerOrder(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
    // keccak256("TakerOrder(bool isOrderAsk,address taker,uint256 price,uint256 tokenId,uint256 minPercentageToAsk,bytes params,uint256 validTime))

     function hashTakerOrder(TakerOrder memory takerOrder) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TAKER_ORDER_HASH,
                    block.chainid,
                    takerOrder.isOrderAsk,
                    takerOrder.taker,
                    takerOrder.signer,
                    takerOrder.price,
                    takerOrder.tokenId,
                    takerOrder.maxValidTime,
                    takerOrder.minPercentageToAsk,
                    keccak256(takerOrder.params),
                    keccak256(takerOrder.dataCryptoAvatars),
                    keccak256(takerOrder.dataRemix)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferManagerNFT {
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionManager {
    function addCollection(address collection) external;

    function removeCollection(address collection) external;

    function isCollectionWhitelisted(address collection) external view returns (bool);

    function viewWhitelistedCollections(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedCollections() external view returns (uint256);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {
    /**
     * @notice Recovers the signer of a signature (for EOA)
     * @param hash the hash containing the signed mesage
     * @param v parameter (27 or 28). This prevents maleability since the public key recovery equation has two possible solutions.
     * @param r parameter
     * @param s parameter
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Signature: Invalid s parameter"
        );

        require(v == 27 || v == 28, "Signature: Invalid v parameter");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Signature: Invalid signer");

        return signer;
    }

    /**
     * @notice Returns whether the signer matches the signed message
     * @param hash the hash containing the signed mesage
     * @param signer the signer address to confirm message validity
     * @param v parameter (27 or 28)
     * @param r parameter
     * @param s parameter
     * @param domainSeparator paramer to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     * https://eips.ethereum.org/EIPS/eip-712#specification
     */
    function verifySignature712(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
            return
                IERC1271(signer).isValidSignature(
                    digest,
                    abi.encodePacked(r, s, v)
                ) == 0x1626ba7e;
        } else {
            return recover(digest, v, r, s) == signer;
        }
    }

    /**
     * @notice Returns whether the signer matches the signed message
     * @param hash the hash containing the signed mesage
     * @param signer the signer address to confirm message validity
     * @param v parameter (27 or 28)
     * @param r parameter
     * @param s parameter
     * @return true --> if valid // false --> if invalid
     * https://eips.ethereum.org/EIPS/eip-191#specification
     */
    function verifySignature191(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = recover(messageHash, v, r, s);
        return recovered == signer;
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}