// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract RealEstate {

    //here we will define the entire state variable when a user will uplaod product
    //they will get all these data ..every single property will have a unique id(productID)
    //so thats what we assigning in the struct.we have the address of the particular user
    //we will also keep the track of the price.we track information about the property
    //we also allow user to have multiple categoryin our market place so like housing..rental etc
    //we track the image..property address..we also track the address of the reviewers.so this is
    //the entire data we are storing

    struct Property{
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


// here we have to define the mappingcos we have to map one property with a unique id
mapping(uint256 => Property) private properties;

//here we have to take the property id cos it will track the properties
//the user has listed the market place
uint256 public propertyIndex;




//now we take the event cos they are very important..it will help us fetch datas based on event

event PropertyListed(uint256 indexed id, address indexed owner, uint256 price);
event PropertySold(uint256 indexed id, address indexed oldOwner, address indexed 
newOwner, uint256 price);
event PropertyResold(uint256 indexed id, address indexed oldOwner, address indexed 
newOwner, uint256 price );





//now we work on Revieww model..so here we take a variable for reviewer.productid
//rating..comment and likes cos we will allow users to like a particular revieww and that 
//is going to be control by smart contract so that no one can manipulate cos once we deploy
//this contract on the blockchain nobody can make changes and thats the kind of features we want
//in our application

 struct  Review {
    address reviewer;
    uint256 productId;
    uint256 rating;
    string comment;
    uint256 likes;
     

}



//this struct will keep the track of the product
//based on  how many particular revieww a product has gotten
//track of product id and calculate the highest rated product in our global market place 
//so here we take the product id cos thats unique identifier each product will have
//then we take the total rating .to track totaol rating a product have gotten
//and we num reviews..it will keep a track of total number reviews a particular product
//has gotten 

struct Product{
    uint256 productId;
    uint256 totalRating;
    uint256 numReviews;
}



//THIS WILL ALLOW THE USERS TO HAVE THIER OWN DASHBOARD WHERE THEY CAN SEE 
//WHAT THEY HAVE DONE IN THE PAST. and this will keep a track of the total reviews
//
 mapping(uint256 => Review[]) private reviews;
 mapping(address => uint256[]) private userReviews;
 mapping(uint256 => Product) private products;
 


//we have a variable that will keep a track of the counting 
 uint256 public reviewsCounter;





//we initialize the revieww event..here every single revieww will have a unique index(id)

 event ReviewAdded(uint256 indexed productId , address indexed reviewer, uint256 
 rating, string comment);
 event ReviewLiked(uint256 indexed productId , uint256 indexed revieweIndex, address 
 indexed liker, uint256 likes);



 

//function in contract that will allow uthe user to list their property

function listProperty(address owner, uint256 price, string memory _propertyTitle, 
string memory _category, string memory _images, string memory _propertyAddress, 
string memory _description ) external returns (uint256){


//writing down the above datas into a smart contract but before that we have to 
//run some  conditional check 
require(price > 0, "price must be greater than 0 ." );
   uint256 productId = propertyIndex++;
   Property storage property = properties [productId];
   property.productID = productId;
   property.owner = owner;
   property.price = price;
   property.propertyTitle = _propertyTitle;
   property.category = _category;
   property.images = _images;
   property.propertyAddress = _propertyAddress;
   property.description = _description;
    //we pass the information
    emit PropertyListed(productId, owner, price);

    return productId;
}




     
//this funcftion will allow users to update data but only the ower to update the property

function updateProperty(address owner, uint256 productId, string memory 
_propertyTitle, string memory _category, string memory _images, string memory 
_propertyAddress, string memory _description  )  external returns (uint256){




//we find the product which we have in the contract the bellow 
//function will take all the above data
 Property storage property = properties[productId];
//we update properties BUT FIRST WE RUN A CHECK CONDITION

require(property.owner == owner, "you are not the property owner");
property.propertyTitle = _propertyTitle;
property.category = _category;
property.images = _images;
property.propertyAddress = _propertyAddress;
property.description = _description;

return productId;
}

 
 
 
 //this function will allow users to update the price
  function updatePrice(address owner, uint256 productId, uint256 price) external
 returns(string memory){

  Property storage property = properties [productId];

  require(property.owner == owner, "you are not the property owner");

  property.price = price;

   return "your property price is updated";
}



//buy property function
function buyProperty(uint256 id, address buyer) external payable{
    uint256 amount = msg.value;

    require(amount >= properties[id].price, "insufficient funds");

     Property storage property = properties [id];

     //we make the transaction here
     (bool sent,) = payable(property.owner).call{value: amount}("");
     //if sending is true we change the ownership 

    if(sent){
        property.owner = buyer;
        emit PropertySold(id, property.owner, buyer, amount);
    }

}




function getAllProperties() public view returns(Property[] memory){
   uint256 itemCount = propertyIndex;
   uint256 currentIndex = 0;

   Property[] memory items = new Property[](itemCount);
   for(uint256 i = 0; i < itemCount; i++ ){
    uint256 currentId = i + 1;
    Property storage currentItem = properties[currentId];
    items[currentIndex] = currentItem;

    currentIndex += 1;
   }
   return items;
}


//getproperty  will give us the details of the property all the information
// about the individual property so let's start working on it 
//so first we will return the entire data of the property
function getProperty(uint256 Id) external view returns(
    uint256, address, uint256, string memory, string memory, string memory, 
    string memory, string memory
){
  
  
    //we identify a perticular property which individual is looking
   Property memory property = properties [Id];
   //once identify we return all the data we want from this functionality
    return(
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

function getUserProperties (address user) external view returns(Property[] memory){
   
   uint256 totalItemCount = propertyIndex;
   uint256 itemCount = 0; 
   uint256 currentIndex = 0;

   //this for loop will help us to increment the itemcount
   for (uint256 i = 0; i < totalItemCount; i++){
    if (properties[i + 1].owner == user){
        itemCount += 1;
    }
   }
     //item count is what we are incrementing in the first loop
   Property[] memory items = new Property[](itemCount);
   for(uint256 i = 0; i < totalItemCount; i++ ){
     if(properties[i + 1].owner == user){
        uint256 currentId = i + 1;
        Property storage currentItem = properties[currentId];

        items[currentIndex] = currentItem; 

        currentIndex  += 1;
     }

   }
   return items;
}

//revews function

function addReview(uint256  productId, uint256  rating, string calldata comment, address user ) external{
  //we check and give  some couple of condition like users not rating more than 5 or less than 5
    require(rating >= 1 && rating <= 5, "rating must be between 1 and 5" );

    Property storage property = properties[productId];

    property.reviewers.push(user);
    property.reviews.push(comment);  


    //sreviews section

  
    reviews[productId].push(Review(user, productId, rating, comment, 0));
    userReviews[user].push(productId);
    products[productId].totalRating += rating;
    products[productId].numReviews++;

    emit ReviewAdded(productId, user, rating, comment);
 ///this will keep the track of how many reviews we are getting
    reviewsCounter++;
}




function getProductReviews(uint256  productId) external view returns(Review[] memory)
{
    return reviews[productId];
}
 

 //in this function we get all the reviews a particular user has given this market place
 //not related to any specific property and this is going to display in that user profile section
 //this logic will kep the entire revew for a single use
function getUserReviews(address user) external view returns(Review[] memory){

    uint256 totalReviews = userReviews[user].length;

    Review[] memory userProductReviews = new Review[](totalReviews);

    for(uint256 i = 0; i < userReviews[user].length; i++){
        uint256 productId = userReviews[user][i];
        Review[] memory productReviews = reviews[productId];

        for (uint256 j = 0; j < productReviews.length; j++){
            if(productReviews[j].reviewer == user){
                userProductReviews[i] = productReviews[j];
            }
        }
    }
    return userProductReviews;
}
  
  
  
  
  //if someonengives a reviews of a particular property this function will make other users
  //to like the revie so thats the logic we are gono build here.im passing the indexnbecos
  //every single revie will have a unique value so the 3 datas we are taking in this fuction are
  //productId..reviewIndex and user address
function likeReview(uint256  productId, uint256 reviewIndex, address user) external{
      //this will give us that particular reviews user is trying to like
    Review storage review = reviews[productId][reviewIndex];

    //after that we check the reviewe likes and increment it

    review.likes++;
  
   //we emit the event.. we initializ the event
    emit ReviewLiked(productId, reviewIndex, user, review.likes);


}





//this function will help us to monitor which particular reviews have a highest amount
//of engagemnt and likes.so thats the logic..we want to return the highest engage product
//so we can fetch that paarticular product and display it in our homepage in the Ui
function getHighestRatedProduct() external view returns(uint256){

    uint256 highestRating = 0;
    uint256 highestRatedProductId = 0;

    //we come here an run a for loop
    for(uint256 i = 0; i < reviewsCounter; i++){
        uint256 productId = i + i;
     
     //here we are calculating the average rating of the product based on the number of the rating
     //and the averge number of reviews it got..the logic will allow one peson to write multiple reviews 
        if(products[productId].numReviews > 0){
            uint256 avgRating = products[productId].totalRating / products[productId].
            numReviews;

            if(avgRating < highestRating){
                highestRating = avgRating;
                highestRatedProductId = productId;
            }
        }
    }
      return highestRatedProductId;
}




}