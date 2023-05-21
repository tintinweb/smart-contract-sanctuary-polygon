// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BlockBase {
    //===================STATE VAR

    struct Property{
        uint256 productId;
        address owner;
        uint256 price;
        string propertyTitle;
        string category;
        string images;
        string propertyAddress;
        string description;
        bool isListed;
        address[] reviewers;
        string[] reviews;
    }
    //===================MAPS
    mapping(uint256 => Property) private properties;
    uint256 public propertyIndex=0;



    //===================EVENTS
    event PropertyListed(uint256 indexed _productId, address indexed _owner,uint256 _price);
    event PropertySold(uint256 indexed _productId, address indexed _oldOwner, address indexed _newOwner,uint256 price);
    event PropertyResold(uint256 indexed _productId, address indexed _oldOwner, address indexed _newOwner,uint256 price);

    event PropertyListedRemoved(uint256 indexed _productId, address indexed _owner);
    event PropertyMinted(uint256 indexed _productId, address indexed _owner);

        //================ REVIEWSECION
        struct Review{
                address reviewer;
                uint256 productId;
                uint256 rating;
                string comment;
                uint256 likes;
                }


        struct Product{
                uint256 productId;
                uint256 totalRating;
                uint256 numReviews;
                }


        //===================MAPS
        mapping (uint256 => Review[]) private reviews;
        mapping (address => uint256[]) private userReviews;
        mapping (uint256 => Product) private products;
        uint256 public reviewsCounter=0;

        //==================EVENTS
        event ReviewAdded(uint256 indexed productproductId, address indexed reviewer, uint256 rating, string comment);
        event ReviewLiked(uint256 indexed productproductId, uint256 indexed reviewIndex, address indexed liker, uint256 likes);
        event ReviewUnliked(uint256 indexed productproductId, uint256 indexed reviewIndex, address indexed liker, uint256 likes);

            
        //===================PROPERTIES FUNCS

    function mintProperty(address _owner, string memory _propertyTitle,string memory _category,string memory _images,string memory _propertyAddress,string memory _description) external returns(uint256){

     uint256 newProductId = propertyIndex++; //first assign as 0 then inc 1 for next property
     Property storage newProperty = properties[newProductId];

     newProperty.productId = newProductId;
     newProperty.owner = _owner;
     newProperty.propertyTitle = _propertyTitle;
     newProperty.category = _category;
     newProperty.images = _images;
     newProperty.propertyAddress = _propertyAddress;
     newProperty.description = _description;
     newProperty.isListed = false;
     emit PropertyMinted(newProductId,_owner);
    return newProductId;
    }


    function RemoveListProperty(uint256 productId,address _owner) external returns(uint256){

        Property storage newProperty = properties[productId];
        
        require(newProperty.owner == _owner,"Only owner function.");

        newProperty.price = 0;
        newProperty.isListed = false;
        emit PropertyListedRemoved(productId,_owner);
        return productId;
    }


    function listProperty(uint256 productId,uint256 _price,address _owner) external returns(uint256){

        require(_price>0,"Price must be greater than zero.");
        Property storage newProperty = properties[productId];
        
        require(newProperty.owner == _owner,"Only owner function.");

        newProperty.price = _price;
        newProperty.isListed = true;
        emit PropertyListed(productId,_owner,_price);
        return productId;
    }

    function updateProperty(address _owner, uint256 _productId,string memory _propertyTitle, string memory _category,string memory _images,string memory _propertyAddress,string memory _description) external returns(uint256){
        Property storage updatedProperty = properties[_productId];
        require(updatedProperty.owner==_owner,"you are not owner");
        updatedProperty.propertyTitle = _propertyTitle; 
        updatedProperty.category = _category; 
        updatedProperty.images = _images; 
        updatedProperty.propertyAddress = _propertyAddress; 
        updatedProperty.description = _description;

    return _productId;
    }

    function updatePropertyPrice(address _owner, uint256 _productId, uint256 _price) external returns(string memory){
        Property storage updatedProperty = properties[_productId];
        require(updatedProperty.owner==_owner,"you are not owner");
        updatedProperty.price = _price; 

    return "Property price has been updated";
    }


    function buyProperty(uint256 _productId,address _buyer) external payable {
        uint256 buyerPrice= msg.value;
        Property storage property = properties[_productId];
        require(buyerPrice >= property.price,"Insufficient Funds");

        (bool sent,) = payable(property.owner).call{value:buyerPrice}("");
        if(sent){
            address _oldOwner = property.owner;
            property.owner = _buyer;
            property.isListed = false;
            property.price = 0;
            emit PropertySold(_productId, _oldOwner,_buyer,buyerPrice);
        }
    }

    function getAllProperties() public view returns(Property[] memory){

        uint256 itemCount = propertyIndex;
        uint256 currentIndex = 0;
        Property[] memory items = new Property[](itemCount);
        for(uint256 i = 0; i < itemCount; i++) {
        // uint256 currentproductId = i + 1;
        // Property storage currentItem= properties[currentproductId];
        Property storage currentItem= properties[i + 1];
        items [currentIndex] = currentItem;
        currentIndex += 1;
        }

        return items;
    } 


    function getSingleProperty(uint256 _productId) external view returns(uint256,address,uint256,string memory,string memory,string memory, string memory,string memory,bool){
        Property storage singleProperty = properties[_productId];

        return(
            singleProperty.productId,
            singleProperty.owner,
            singleProperty.price,
            singleProperty.propertyTitle,
            singleProperty.category,
            singleProperty.images,
            singleProperty.propertyAddress,
            singleProperty.description,
            singleProperty.isListed
        );

    } 


        function getUserProperties(address _user) external view returns(Property[] memory){
            uint256 totalItemCount = propertyIndex;
            uint256 itemCount = 0;
            uint256 currentIndex = 0;
            for(uint256 i = 0; i < totalItemCount; i++){
                if(properties[i+1].owner==_user){
                    itemCount +=1;

                }
            }


            Property[] memory items = new Property[](itemCount);
            for(uint256 i = 0; i < totalItemCount; i++) {

                if(properties[i+1].owner==_user){
                    // uint256 currentproductId = i + 1;
                    // Property storage currentItem= properties[currentproductId];
                    Property storage currentItem = properties[i + 1];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;

                }
            
            }
        return items;
                } 

        //===================REVIEWS
        function addReview(uint256 _productId,uint256 _rating , string calldata _comment,address _user) external {

            require(_rating>=1&&_rating<=5,"Rating must be between 1 to 5");
            Property storage property = properties[_productId];
            property.reviewers.push(_user);
            property.reviews.push(_comment);


            reviews[_productId].push(Review(_user,_productId,_rating,_comment,0));
            userReviews[_user].push(_productId);
            products[_productId].productId = _productId; //extra line
            products[_productId].totalRating += _rating;
            products[_productId].numReviews ++;


            emit ReviewAdded(_productId,_user,_rating,_comment);
                reviewsCounter++; // 0 for current then inc 1 for next review
        }


        function getPropertyReviews(uint256 _productId) external view returns(Review[] memory) {

            return reviews[_productId];

        }

        function getUserReviews(address _user) external view returns(Review[] memory) {



                uint256 totalReviews = userReviews[_user].length;
                Review[] memory userProductReviews = new Review[](totalReviews);


                for(uint256 i = 0; i < userReviews[_user].length; i++) {

                    uint256 productId = userReviews[_user][i];
                    Review[] memory productReviews = reviews[productId];

                    for (uint256 j = 0; j <productReviews.length;j++ ){


                            if(productReviews[j].reviewer==_user){

                                userProductReviews[i]=productReviews[j];
                            }
                    }
            
            }
            return userProductReviews;
        }


        function likeReview (uint256 _productId,uint256 _reviewIndex,address _user) external {
            Review storage review = reviews[_productId][_reviewIndex];
            review.likes++;
            emit ReviewLiked(_productId, _reviewIndex, _user, review.likes);
        }

        function unlikeReview(uint256 _productId,uint256 _reviewIndex,address _user) external {
            Review storage review = reviews[_productId][_reviewIndex];
            
            require(review.likes>0,"likes are zero you cant unlike more");
            review.likes--;
            emit ReviewUnliked(_productId, _reviewIndex, _user, review.likes);
        }



        function getHighestRatedProperty() external view returns(uint256) {
            uint256 highestRating = 0;
            uint256 highestRatedProductId = 0;


            for(uint256 i = 0; i < reviewsCounter; i++){
                uint256 productId = i + 1;


                if(products[productId].numReviews>0){

                    uint256 avgRating = products[productId].totalRating / products[productId].numReviews;

                    if(avgRating > highestRating){
                        highestRating = avgRating;
                        highestRatedProductId = productId;

                    }
                
                
                }


            }

            return highestRatedProductId;
        }



}