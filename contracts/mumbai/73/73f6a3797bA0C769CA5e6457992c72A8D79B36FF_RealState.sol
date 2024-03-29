// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract RealState {
    //State variable
    struct Property {
        uint256 productID;
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

    //Mapping
    mapping(uint256 => Property) private properties;
    uint256 public propertyIndex;

    //EVENTS
    event PropertyListed(
        uint256 indexed id,
        address indexed owner,
        uint256 price
    );
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

    //REVIEWSECTION
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

    mapping(uint256 => Review[]) private reviews;
    mapping(address => uint256[]) private userReviews;
    mapping(uint256 => Product) private products;

    uint256 public reviewsCounter;

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

    //Functions in contract
    function listProperty(
        address owner,
        uint256 price,
        string memory _propertyTitle,
        string memory _category,
        string memory _images,
        string memory _propertyAddress,
        string memory _description
    ) external returns (uint256) {
        require(price > 0, "Price must be greater than 0");
        uint256 productId = propertyIndex++;
        Property storage property = properties[productId];
        property.productID = productId;
        property.owner = owner;
        property.price = price;
        property.propertyTitle = _propertyTitle;
        property.category = _category;
        property.images = _images;
        property.propertyAddress = _propertyAddress;
        property.description = _description;

        emit PropertyListed(productId, owner, price);
        return productId;
    }

    function updateProperty(
        address owner,
        uint256 _productId,
        string memory _propertyTitle,
        string memory _category,
        string memory _images,
        string memory _propertyAddress,
        string memory _description
    ) external returns (uint256) {
        Property storage property = properties[_productId];
        require(property.owner == owner, "You are not the owner");
        property.propertyTitle = _propertyTitle;
        property.category = _category;
        property.images = _images;
        property.propertyAddress = _propertyAddress;
        property.description = _description;

        return _productId;
    }

    function updatePrice(
        address owner,
        uint256 _productId,
        uint256 _price
    ) external returns (string memory) {
        Property storage property = properties[_productId];
        require(property.owner == owner, "You are not the owner");
        property.price = _price;
        return "Price updated";
    }

    function buyProperty(uint256 productId, address buyer) external payable {
        uint256 amount = msg.value;
        require(amount >= properties[productId].price, "Insufficient funds");

        Property storage property = properties[productId];

        (bool sent, ) = payable(property.owner).call{value: amount}("");
        if (sent) {
            property.owner = buyer;
            emit PropertySold(productId, property.owner, buyer, amount);
        }
    }

    function getAllProperties() public view returns (Property[] memory) {
        uint256 itemCount = propertyIndex;
        uint256 currentIndex = 0;
        Property[] memory items = new Property[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i;
            Property storage currentItem = properties[currentId];
            items[currentIndex] = currentItem;
            currentId = i + 1;
            currentIndex += 1;
        }
        return items;
    }

    function getProperty(
        uint256 _id
    )
        external
        view
        returns (
            uint256,
            address,
            uint256,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        Property storage property = properties[_id];
        return (
            property.productID,
            property.owner,
            property.price,
            property.propertyTitle,
            property.category,
            property.images,
            property.propertyAddress,
            property.description
        );
    }

    function getUserProperties(
        address user
    ) external view returns (Property[] memory) {
        uint256 totalItemCount = propertyIndex;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (properties[i].owner == user) {
                itemCount += 1;
            }
        }
        Property[] memory items = new Property[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (properties[i].owner == user) {
                uint256 currentId = i;
                Property storage currentItem = properties[currentId];
                items[currentIndex] = currentItem;
                currentId = i + 1;
                currentIndex += 1;
            }
        }
        return items;
    }

    //Reviews functions
    function addReview(
        uint256 productId,
        uint256 rating,
        string calldata comment,
        address user
    ) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        Property storage property = properties[productId];
        property.reviewers.push(user);
        property.reviews.push(comment);

        //REVIEWSECTION
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
        uint256 totalReviews = userReviews[user].length;
        Review[] memory userProductReviews = new Review[](totalReviews);
        for (uint256 i = 0; i < userReviews[user].length; i++) {
            uint256 productId = userReviews[user][i];
            Review[] memory productReviews = reviews[productId];
            for (uint256 j = 0; j < productReviews.length; j++) {
                if (productReviews[j].reviewer == user) {
                    userProductReviews[i] = productReviews[j];
                }
            }
        }

        return userProductReviews;
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

    function getHighestratedProduct() external view returns (uint256) {
        uint256 highestRating = 0;
        uint256 highestRatedProductId = 0;

        for (uint i = 0; i < reviewsCounter; i++) {
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