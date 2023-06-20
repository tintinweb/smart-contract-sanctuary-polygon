// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract RealEstate {
    struct Property {
        uint256 productId;
        address owner;
        uint256 price;
        string propertyTitle;
        string category;
        string images;
        string propertyAddress;
        string description;
        address[] reviewers;
        string[] reviews;
    }

    struct Review {
        address reviewer;
        uint256 productId;
        uint256 rating;
        string comment;
        uint256 likes;
    }

    struct Product {
        uint256 productId;
        uint256 totalRating;
        uint256 numReviews;
    }
    //MAPPING
    mapping(uint256 => Property) private properties;

    mapping(uint256 => Review[]) private reviews;

    mapping(address => uint256[]) private userReviews;

    mapping(uint256 => Product) private products;

    //STATE VARIABLE
    uint256 public propertyIndex;
    uint256 public reviewsCounter;

    //EVENTS
    event PropertyListed(uint256 indexed id, address indexed owner);
    event PropertySold(
        uint256 indexed id,
        address indexed oldOwner,
        address indexed newOwner,
        uint256 price
    );
    event PropertyResold(
        uint256 indexed id,
        address indexed oldOwner,
        address indexed newOwner,
        uint256 price
    );

    event ReviewAdded(
        uint256 indexed productId,
        address indexed reviewer,
        uint256 rating,
        string comment
    );
    event ReviewLiked(
        uint256 indexed productId,
        uint256 indexed reviewIndex,
        address indexed liker,
        uint256 likes
    );

    constructor() {}

    //FUNCTIONS

    function listProperty(
        address owner,
        uint256 price,
        string calldata _propertyTitle,
        string calldata _category,
        string calldata _images,
        string calldata _propertyAddress,
        string calldata _description
    ) external returns (uint256) {
        require(price != 0, "Price must be greater than 0");
        uint256 productId = propertyIndex++;
        Property storage property = properties[productId];

        property.productId = productId;
        property.owner = owner;
        property.price = price;
        property.propertyTitle = _propertyTitle;
        property.category = _category;
        property.images = _images;
        property.propertyAddress = _propertyAddress;
        property.description = _description;

        emit PropertyListed(productId, owner);

        return productId;
    }

    function updateProperty(
        uint256 productId,
        string calldata _propertyTitle,
        string calldata _category,
        string calldata _images,
        string calldata _propertyAddress,
        string calldata _description
    ) external returns (uint256) {
        Property storage property = properties[productId];

        require(msg.sender == property.owner, "Access control: not the owner");

        property.propertyTitle = _propertyTitle;
        property.category = _category;
        property.images = _images;
        property.propertyAddress = _propertyAddress;
        property.description = _description;

        return productId;
    }

    function updatePrice(
        uint256 productId,
        uint256 newPrice
    ) external returns (string memory) {
        Property storage property = properties[productId];

        require(msg.sender == property.owner, "Access control: not the owner");

        property.price = newPrice;

        return "Property price updated";
    }

    function buyProperty(uint256 propertyId, address buyer) external payable {
        Property storage property = properties[propertyId];
        require(property.price <= msg.value, "Insufficient funds");
        uint256 amount = msg.value;

        (bool sent, ) = payable(property.owner).call{value: amount}("");
        require(sent, "Funds not sent");

        emit PropertySold(propertyId, property.owner, buyer, amount);
        property.owner = buyer;
    }

    function getAllProperties() public view returns (Property[] memory) {
        Property[] memory items = new Property[](propertyIndex);

        for (uint256 i; i < propertyIndex; ++i) {
            items[i] = properties[i + 1];
        }
        return items;
    }

    function getProperty(
        uint256 propertyId
    ) external view returns (Property memory) {
        return properties[propertyId];
    }

    function getUserProperties(
        address user
    ) external view returns (Property[] memory) {
        Property[] memory userProperties;
        uint256 itemCount; //TODO test if it's working without defining userProperties size

        // for (uint256 i; i < propertyIndex; ++i){
        //     if(properties[i+1].owner == user){
        //         itemCount++;
        //     }
        // }

        for (uint i; i < propertyIndex; ++i) {
            if (properties[i + 1].owner == user) {
                userProperties[i] = properties[i + 1];
            }
        }
        return userProperties;
    }

    //REVIEWS FUNCTION
    function addReview(
        uint256 productId,
        uint256 rating,
        string calldata comment,
        address user
    ) external {
        require(rating != 0 && rating <= 5, "Rating out of range");

        Property storage property = properties[productId];

        property.reviewers.push(user);
        property.reviews.push(comment);

        reviews[productId].push(Review(user, productId, rating, comment, 0));
        userReviews[user].push(productId);
        products[productId].totalRating += rating;
        products[productId].numReviews++;

        emit ReviewAdded(productId, user, rating, comment);

        reviewsCounter++;
    }

    function getProductReviews(
        uint256 productId
    ) external view returns (Review[] memory) {
        return reviews[productId];
    }

    function getUserReviews(
        address user
    ) external view returns (Review[] memory) {
        uint256[] memory productIds = userReviews[user];
        uint256 totalReviews = productIds.length;

        Review[] memory userProductReviews = new Review[](totalReviews);

        for (uint i; i < totalReviews; ++i) {
            Review[] memory productReviews = reviews[productIds[i]];

            for (uint256 j; j < productReviews.length; ++j) {
                if (productReviews[j].reviewer == user) {
                    userProductReviews[i] = productReviews[j];
                }
            }
        }
    }

    function likeReview(
        uint256 productId,
        uint256 reviewIndex,
        address user
    ) external {
        Review storage review = reviews[productId][reviewIndex];

        review.likes++;

        emit ReviewLiked(productId, reviewIndex, user, review.likes);
    }

    function getHighestRatedProduct() external view returns (uint256) {
        uint256 highestRating = 0;
        uint256 highestRatedProductId = 0;

        for (uint256 i; i < reviewsCounter; ++i) {
            uint256 productId = i + 1;

            if (products[productId].numReviews > 0) {
                uint256 avgRating = products[productId].totalRating /
                    products[productId].numReviews;

                if (avgRating > highestRating) {
                    highestRating = avgRating;
                    highestRatedProductId = productId;
                }
            }
        }
        return highestRatedProductId;
    }
}