/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// File: contracts/SP.sol


pragma solidity 0.8.18;

contract ProductTokenStandard {
    // Token name
    string private _name;

    // Platform owner
    address private _platformOwner;

    /**
     * @dev Emitted when token or product is minted
     */
    event Mint(
        uint256 indexed productId,
        string productName,
        string productType,
        string sender,
        string receiver
    );

    /**
     * @dev Emitted when product's name changes
     */
    event ChangedProductName(
        uint256 indexed productId,
        string previousProductName,
        string newProductName
    );

    /**
     * @dev Emitted when product's type changes
     */
    event ChangedProductType(
        uint256 indexed productId,
        string previousProductType,
        string newProductType
    );

    /**
     * @dev Emitted when token receiver's name changes
     */
    event ChangedReceiverName(
        uint256 indexed productId,
        string previousReceiverName,
        string newReceiverName
    );

    /**
     * @dev Emitted when sender or service provider's name changes
     */
    event ChangedSenderName(
        uint256 indexed productId,
        string previousSenderName,
        string newSenderName
    );

    ///  Mapping from product ID to product structure
    mapping(uint256 => Product) private _productDetails;

    /// Mapping from product holders to prouduct count
    mapping(string => uint256) private _totalBalances;

    /// Mapping from product ID to metaData URI
    mapping(uint256 => string) _tokenURIs;

    struct Product {
        string name;
        string productType;
        string sender;
        string receiver;
    }

    /// @dev The modifier checks for the authorized access

    modifier onlyPlatformOwner() {
        require(
            msg.sender == _platformOwner,
            "onlyPlatformOwner: Unauthorized access"
        );
        _;
    }

    /**
     * @param name_ Name of the product platform or usage
     */
    constructor(string memory name_) {
        _platformOwner = msg.sender;
        _name = name_;
    }

    /**
     *  @dev Changes name of the product and emits event
     * @param productId_ product ID for refernce
     * @param newName_ New name of the product
     */
    function changeProductName(
        uint256 productId_,
        string calldata newName_
    ) external virtual onlyPlatformOwner {
        require(
            bytes(newName_).length > 0,
            "changeProductName: Invalid product name"
        );

        require(
            _productExist(productId_),
            "changeProductName: Product does not exist"
        );

        emit ChangedProductName(
            productId_,
            _productDetails[productId_].name,
            newName_
        );

        _productDetails[productId_].name = newName_;
    }

    /**
     *  @dev Changes type of the product and emits event
     * @param productId_ product ID for refernce
     * @param newName_ New type of the product
     */
    function changeProductType(
        uint256 productId_,
        string calldata newName_
    ) external virtual onlyPlatformOwner {
        require(
            bytes(newName_).length > 0,
            "changeProductType: Invalid product type"
        );

        require(
            _productExist(productId_),
            "changeProductType: Product does not exist"
        );

        emit ChangedProductType(
            productId_,
            _productDetails[productId_].productType,
            newName_
        );

        _productDetails[productId_].productType = newName_;
    }

    /**
     *  @dev Changes name of the receiver or consumer and emits event
     * @param productId_ product ID for refernce
     * @param newName_ New name of the product
     */
    function changeReceiverName(
        uint256 productId_,
        string calldata newName_
    ) external virtual onlyPlatformOwner {
        require(
            _productExist(productId_),
            "changeReceiverName: Product does not exist"
        );

        emit ChangedReceiverName(
            productId_,
            _productDetails[productId_].receiver,
            newName_
        );

        _productDetails[productId_].receiver = newName_;
    }

    /**
     *  @dev Changes name of the sender or provider and emits event
     * @param productId_ product ID for refernce
     * @param newName_ New name of the product
     */
    function changeSenderName(
        uint256 productId_,
        string calldata newName_
    ) external virtual onlyPlatformOwner {
        require(
            _productExist(productId_),
            "changeSenderName: Product does not exist"
        );

        emit ChangedSenderName(
            productId_,
            _productDetails[productId_].receiver,
            newName_
        );

        _productDetails[productId_].sender = newName_;
    }

    /// @dev Returns the name of the receiver or comsumer
    function getReceiver(
        uint256 productId_
    ) external view virtual returns (string memory) {
        return _productDetails[productId_].receiver;
    }

    /// @dev Returns the name of the sender or producer
    function getSender(
        uint256 productId_
    ) external view virtual returns (string memory) {
        return _productDetails[productId_].sender;
    }

    /// @dev Returns product's details
    function extractDetails(
        uint256 productId_
    ) external view virtual returns (Product memory) {
        return _productDetails[productId_];
    }

    /// @dev Returns the number of product token held by any user
    function totalBalance(
        string calldata holder_
    ) external view virtual returns (uint256) {
        return _totalBalances[holder_];
    }

    /// @dev Returns product's metaData URI
    function extractURI(
        uint256 productId_
    ) external view virtual returns (string memory) {
        return _tokenURIs[productId_];
    }

    /**
     * @dev Mints product NFT for the given details.
     * This function checks the parameter and mints.
     * The product ID must not exist.
     */
    function _mint(
        uint256 productId_,
        string calldata name_,
        string calldata productType_,
        string calldata sender_,
        string calldata receiver_,
        string calldata uri_
    ) internal virtual onlyPlatformOwner {
        require(!_productExist(productId_), "_mint: Product already exist");

        require(
            bytes(name_).length > 0 &&
                bytes(productType_).length > 0 &&
                bytes(sender_).length > 0 &&
                bytes(receiver_).length > 0 &&
                bytes(uri_).length > 0,
            "_mint: Invalid input"
        );

        _productDetails[productId_] = Product(
            name_,
            productType_,
            sender_,
            receiver_
        );

        _setURI(productId_, uri_);

        _totalBalances[receiver_] += 1;

        _totalBalances[sender_] += 1;

        emit Mint(productId_, name_, productType_, sender_, receiver_);
    }

    /// @dev Sets the URI of the product
    function _setURI(uint _productId, string calldata _uri) internal virtual {
        require(bytes(_uri).length > 0, "Invalid uri");

        _tokenURIs[_productId] = _uri;
    }

    /// Checks the existence of the product
    function _productExist(
        uint productId_
    ) internal view virtual returns (bool) {
        return bytes(_productDetails[productId_].name).length != 0;
    }
}
// File: contracts/Feedback.sol


pragma solidity 0.8.18;


contract SPFeedback is ProductTokenStandard{

    ProductTokenStandard Stdobj;
    uint256 Fid; 
    mapping(string => mapping(string => uint256)) public Records;

     event Feedbackcreated(
        uint256 indexed productId,
        string sender,
        string receiver,
        string URI
    );


    constructor () ProductTokenStandard("Feedback")
    {
        Stdobj = new ProductTokenStandard("Feedback");
    }

    

    function createFeedback(

        string calldata name_,
        string calldata productType_,
        string calldata sender_,
        string calldata receiver_,
        string calldata uri_

        ) public { // have to do external
         
         // creating the call data variable for mint function
        Fid = Fid +1;
        Records[receiver_][sender_] = Fid;
        _mint(Fid, name_, productType_, sender_, receiver_, uri_);
         


        emit Feedbackcreated(Fid, sender_, receiver_, uri_);
    }


    function changeFeedback(uint256 FID, string calldata _newuri) public {

        require(
            bytes(_newuri).length > 0,
            "changeFeedback: Invalid URI"
        );
        // require(_productExist(Fid), "createFeedback Product does not exist.");
        _setURI(FID, _newuri);
    }
}