// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Blog
/// @author https://github.com/Ultra-tech-code
/// A decentralized blogging system that gives bloggers the right over their content and 
/// also allow bloggers to get paid
/// The mode of payment/tip is smartBlog Token.
/// The admin will help bloggers to change their payment address incase of any issues with it

contract blog {

  /***************State Variables***************/
    address admin;
    IERC20 token;
    uint8 public totalBlogs;

    /// @param tokenAddress: this is the address of the deployed smartBlog Token
    constructor(IERC20 tokenAddress){
        msg.sender == admin;
        token = tokenAddress;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "not an admin");
        _;
    }

    modifier blogExist(address blogOwner,uint8 blogId){
      bloggersDetails storage BD = bloggersdetails[blogOwner];
      require(BD.eachBlogs[blogId].timecreated != 0, "Blog doesn't exist");
      _;
    }

    struct blogs{
        string Topic;
        string blogDetails;
        string imageUrl;
        uint timecreated;
        uint upvote;
        uint downvote;
        uint totalReaction;
        uint totalTip;
        uint blogid;
    }

  struct bloggersDetails{
      address blogOwner;
      uint totalBlogs;
      uint timeJoined;
      address paymentaddress;
      string anonName;
      uint totalLikes;
      uint8 blogsCreated;
      mapping(uint => blogs) eachBlogs;
  }

  /***********Events************/
  event joined(string indexed anonname, address indexed, uint8 indexed);
  event Likes(address indexed , uint8 indexed);
  event Unlikes(address indexed, uint8 indexed);
  event blogCreated(address indexed, string indexed topic, uint8 indexed );
  event tipped(address indexed, address indexed, uint8 indexed);


  mapping (address => bloggersDetails) bloggersdetails;
  mapping(address => mapping(uint => bool)) userLike;
  mapping(address => mapping(uint => bool)) userUnlike;
  



    /// @dev A function to join
    /// @param anonname: this is the bloggers name
    /// @notice this is used to keep each bloggers anon and to identify each bloggers easily
  function join(string memory anonname) public {
    bloggersDetails storage BD = bloggersdetails[msg.sender];
    BD.blogOwner = msg.sender;
    BD.timeJoined = block.timestamp;
    BD.paymentaddress = msg.sender;
    BD.anonName = anonname;

    emit joined(anonname, msg.sender, uint8(block.timestamp));
  }


    /// @dev A function to create a blog
    /// @param topic: this is the topic of the blog
    /// @param blogdetails: this is the content of the blog
    /// @param _imageUrl: this is the image that will be displayed along with the blog
  function createBlog(string memory topic, string memory blogdetails, string memory _imageUrl) public {
    bloggersDetails storage BD = bloggersdetails[msg.sender];
    bytes memory username = bytes(BD.anonName);
    require(username.length != 0, "You are required to join");
    uint8 id = BD.blogsCreated;
    BD.eachBlogs[id].Topic = topic;
    BD.eachBlogs[id].blogDetails = blogdetails;
    BD.eachBlogs[id].imageUrl = _imageUrl;
    BD.eachBlogs[id].timecreated = block.timestamp;
    BD.eachBlogs[id].blogid = id;
    BD.blogsCreated += 1;

    totalBlogs++;

    emit blogCreated(msg.sender, topic, uint8(block.timestamp));
  }

    /// @dev A function to vote
    /// @param blogOwner: this is the address of the blogowner
    /// @param blogId: the id of the particular blog a user is trying to upvote
    /// @notice this is used to increase the likes of a particular blog
  function upVote(address blogOwner, uint8 blogId) public blogExist(blogOwner, blogId){
    require(userLike[msg.sender][blogId] == false, "already upvote");
    bloggersDetails storage BD = bloggersdetails[blogOwner];
    BD.eachBlogs[blogId].upvote += 1;
    BD.eachBlogs[blogId].totalReaction += 1;
    BD.totalLikes +=1;

    userLike[msg.sender][blogId] = true;

    emit Likes(msg.sender, uint8(block.timestamp));
  }

    /// @dev A function to vote
    /// @param blogOwner: this is the address of the blogowner
    /// @param blogId: the id of the particular blog a user is trying to upvote
    /// @notice this is used to decrease the likes of a particular blog
  function downVote(address blogOwner, uint8 blogId) public blogExist(blogOwner, blogId){
    require(userUnlike[msg.sender][blogId] == false, "already downVote");
    bloggersDetails storage BD = bloggersdetails[blogOwner]; 
    if(BD.eachBlogs[blogId].downvote == 0){
      BD.eachBlogs[blogId].downvote = 0;
    }else{
      BD.eachBlogs[blogId].downvote += 1;
    }

    if(BD.totalLikes == 0){
      BD.totalLikes = 0;
    }else{
      BD.totalLikes -= 1;
    }

    BD.eachBlogs[blogId].totalReaction += 1;
    userUnlike[msg.sender][blogId] = true;
    
    emit Unlikes(msg.sender, uint8(block.timestamp));
  }

    /// @dev A function to tip
    /// @param blogOwner: this is the address of the blogowner
    /// @param blogId: the id of the particular blog
    /// @notice this is used to tip the blogOwner. the blogowner is tipped the platform token
  function tip(address blogOwner, uint8 blogId, uint8 amount) public blogExist(blogOwner, blogId){
    bloggersDetails storage BD = bloggersdetails[blogOwner];
    address to = BD.paymentaddress;
    IERC20(token).transferFrom(msg.sender, to, amount *1e18);
    BD.eachBlogs[blogId].totalTip = amount;  

    emit tipped(blogOwner, msg.sender, amount);
  }
  
    /// @dev A function to change a bloggers payment address
    /// @param bloggersAddress: this is the address of the bloggers
    /// @param newPaymentAddress: this is the new payment address
    /// @notice this function can only be called by the admin, it's used to change a bloggers payemnt address incase of any issue
  function changepaymentAddress(address bloggersAddress, address newPaymentAddress) public onlyAdmin returns(string memory){
    bloggersDetails storage BD = bloggersdetails[bloggersAddress];
    BD.paymentaddress = newPaymentAddress;

    return ("payment address changed");
  }  

    /// @dev A view function to get the totalLikes a blogger has
    /// @param blogOwner: this is the address of the blogowner
    /// @notice the totalLikes that a bloger has is used to rate the user.
  function bloggersRating(address blogOwner) public view returns(uint256){
    bloggersDetails storage BD = bloggersdetails[blogOwner];
    return BD.totalLikes;
  }

    /// @dev A view function to get the total blogs that a blogger has created
    /// @param blogOwner: this is the address of the blogowner
  function totalBloggersBlog(address blogOwner) public view returns(uint256){
    bloggersDetails storage BD = bloggersdetails[blogOwner];
    return BD.blogsCreated;
  }
    /// @dev A view function to get the total likes that a blog has
    /// @param blogOwner: this is the address of the blogowner
  function getBlogLikes(address blogOwner, uint8 blogId) public view returns(uint256){
    bloggersDetails storage BD = bloggersdetails[blogOwner];
    return BD.eachBlogs[blogId].upvote;
  }


}


interface IERC20{
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}